using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Pages;

/// <summary>
/// The checklist entry screen. This page only ever renders (GET) — every
/// write (save a task, save a checkpoint, complete) goes through
/// Controllers/ChecklistController, and PDF export through
/// Controllers/PdfController, so the writable surface lives in one place.
/// </summary>
public class ChecklistModel : PageModel
{
    private readonly AppDbContext _db;
    private readonly ChecklistLoadService _load;

    public ChecklistModel(AppDbContext db, ChecklistLoadService load)
    {
        _db = db;
        _load = load;
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
