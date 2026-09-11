using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Pages;

public class ChecklistModel : PageModel
{
    private readonly AppDbContext _db;
    private readonly ChecklistLoadService _load;
    private readonly AccessService _access;

    public ChecklistModel(AppDbContext db, ChecklistLoadService load, AccessService access)
    {
        _db = db;
        _load = load;
        _access = access;
    }

    public Area? Area { get; set; }
    public Shift? Shift { get; set; }
    public Department? Department { get; set; }
    public ChecklistSubmission? Submission { get; set; }
    public TaskList? TaskListRow { get; set; }
    public List<TaskItem> Items { get; set; } = new();
    public bool IsGridMode { get; set; }
    public bool NotConfigured { get; set; }
    public DateOnly ChecklistDate { get; set; }
    public bool IsReadOnly => Submission?.CompletedAt is not null;
    public int AnsweredCount { get; set; }
    public int TotalCount { get; set; }
    public List<GridCategoryVm> GridCategories { get; set; } = new();

    public bool IsHod { get; set; }
    public string CurrentUserLabel { get; set; } = "";
    public List<Person> Hods { get; set; } = new();

    public List<EscalationVm> Escalations { get; set; } = new();

    public record EscalationVm(string Text, string EscalateTo, string? Window, string? Notes);

    public static bool IsHodOnly(TaskItem item) =>
        string.Equals(item.ResponsibleRole, PersonRole.Hod, StringComparison.OrdinalIgnoreCase);

    public class GridCategoryVm
    {
        public string Category { get; set; } = string.Empty;
        public List<TaskCheckpoint> Checkpoints { get; set; } = new();
        public List<TaskItem> Items { get; set; } = new();
    }

    public static string CategorySlug(string category) => category.ToLowerInvariant() switch
    {
        "h&s" => "hs",
        "quality" => "quality",
        "performance" => "performance",
        "morale" => "morale",
        _ => "other"
    };

    public async Task<IActionResult> OnGetAsync(int areaId, int shiftId, string? date)
    {
        ChecklistDate = string.IsNullOrWhiteSpace(date) ? DateOnly.FromDateTime(DateTime.Now) : DateOnly.Parse(date);

        Area = await _db.Areas.Include(a => a.Department).FirstOrDefaultAsync(a => a.Id == areaId);
        Shift = await _db.Shifts.FirstOrDefaultAsync(s => s.Id == shiftId);
        if (Area is null || Shift is null) return NotFound();
        Department = Area.Department;

        var result = await _load.GetOrCreateAsync(areaId, shiftId, ChecklistDate, ActorName());
        if (result is null)
        {
            NotConfigured = true;
            return Page();
        }

        Submission = result.Submission;
        TaskListRow = result.TaskList;
        Items = result.Items;
        IsGridMode = result.IsGridMode;

        (AnsweredCount, TotalCount) = ChecklistProgress.ComputeProgress(Items, Submission);

        IsHod = await _access.IsHodAsync();
        CurrentUserLabel = await _access.CurrentDisplayNameAsync();
        Hods = await _access.GetHodsAsync();

        Escalations = Items
            .Where(i => !string.IsNullOrWhiteSpace(i.EscalateToRole))
            .Select(i => new { Item = i, Resp = Submission.TaskResponses.FirstOrDefault(r => r.TaskItemId == i.Id) })
            .Where(x => x.Resp is not null &&
                        (x.Resp.Status == ResponseStatus.Issue ||
                         x.Resp.CheckpointResponses.Any(c => c.Status == ResponseStatus.Issue)))
            .Select(x => new EscalationVm(x.Item.Text, x.Item.EscalateToRole!, x.Item.EscalationWindow, x.Resp!.Notes))
            .ToList();

        if (IsGridMode)
        {
            GridCategories = Items
                .GroupBy(i => i.Category ?? "Other")
                .Select(g => new GridCategoryVm
                {
                    Category = g.Key,
                    Items = g.OrderBy(i => i.SortOrder).ToList(),
                    Checkpoints = g.Where(i => i.IsTimeBoxed)
                        .SelectMany(i => i.Checkpoints)
                        .GroupBy(c => new { c.Label, c.SortOrder })
                        .Select(x => x.First())
                        .OrderBy(c => c.SortOrder)
                        .ToList()
                })
                .OrderBy(g => g.Items.Min(i => i.SortOrder))
                .ToList();
        }

        return Page();
    }

    private string ActorName()
    {
        return Request.Query.TryGetValue("actor", out var v) ? v.ToString() : "Unknown";
    }
}
