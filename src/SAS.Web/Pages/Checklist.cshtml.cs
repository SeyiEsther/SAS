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
    private readonly ChecklistService _checklist;
    private readonly PdfExportService _pdf;

    public ChecklistModel(AppDbContext db, ChecklistService checklist, PdfExportService pdf)
    {
        _db = db;
        _checklist = checklist;
        _pdf = pdf;
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

        var result = await _checklist.GetOrCreateAsync(areaId, shiftId, ChecklistDate, ActorName());
        if (result is null)
        {
            NotConfigured = true;
            return Page();
        }

        Submission = result.Submission;
        TaskListRow = result.TaskList;
        Items = result.Items;
        IsGridMode = result.IsGridMode;

        (AnsweredCount, TotalCount) = ChecklistService.ComputeProgress(Items, Submission);

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

    public async Task<IActionResult> OnGetPdfAsync(int areaId, int shiftId, string? date)
    {
        var checklistDate = string.IsNullOrWhiteSpace(date) ? DateOnly.FromDateTime(DateTime.Now) : DateOnly.Parse(date);

        var area = await _db.Areas.Include(a => a.Department).FirstOrDefaultAsync(a => a.Id == areaId);
        var shift = await _db.Shifts.FirstOrDefaultAsync(s => s.Id == shiftId);
        if (area is null || shift is null) return NotFound();

        var submission = await _db.ChecklistSubmissions
            .Include(s => s.TaskResponses).ThenInclude(r => r.CheckpointResponses)
            .FirstOrDefaultAsync(s => s.AreaId == areaId && s.ShiftId == shiftId && s.ChecklistDate == checklistDate);
        if (submission is null) return NotFound();

        var taskList = await _db.TaskLists
            .Include(l => l.TaskItems.OrderBy(i => i.SortOrder)).ThenInclude(i => i.Checkpoints.OrderBy(c => c.SortOrder))
            .FirstOrDefaultAsync(l => l.Id == submission.TaskListId);
        if (taskList is null) return NotFound();

        var bytes = _pdf.Export(submission, taskList, taskList.TaskItems.ToList(), area, shift, area.Department!);
        var fileName = $"SafeStart_{area.Department!.Name}_{area.Name}_{shift.Name}_{checklistDate:yyyy-MM-dd}.pdf".Replace(" ", "_");
        return File(bytes, "application/pdf", fileName);
    }

    private string ActorName()
    {
        return Request.Query.TryGetValue("actor", out var v) ? v.ToString() : "Unknown";
    }

    public class SaveTaskRequest
    {
        public int SubmissionId { get; set; }
        public int ItemId { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? Notes { get; set; }
        public string? Actor { get; set; }
    }

    public async Task<IActionResult> OnPostSaveTaskAsync([FromBody] SaveTaskRequest req)
    {
        if (req.Status != ResponseStatus.Done && req.Status != ResponseStatus.Issue)
        {
            return BadRequest(new { error = "Invalid status." });
        }
        if (req.Status == ResponseStatus.Issue && string.IsNullOrWhiteSpace(req.Notes))
        {
            return BadRequest(new { error = "Notes are required for an Issue." });
        }

        await _checklist.SaveTaskResponseAsync(req.SubmissionId, req.ItemId, req.Status, req.Notes, req.Actor ?? "Unknown");
        return new JsonResult(new { ok = true });
    }

    public class SaveCheckpointRequest
    {
        public int SubmissionId { get; set; }
        public int ItemId { get; set; }
        public int CheckpointId { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? Notes { get; set; }
        public string? Actor { get; set; }
    }

    public async Task<IActionResult> OnPostSaveCheckpointAsync([FromBody] SaveCheckpointRequest req)
    {
        if (req.Status != ResponseStatus.Done && req.Status != ResponseStatus.Issue)
        {
            return BadRequest(new { error = "Invalid status." });
        }

        await _checklist.SaveCheckpointResponseAsync(req.SubmissionId, req.ItemId, req.CheckpointId, req.Status, req.Notes, req.Actor ?? "Unknown");
        return new JsonResult(new { ok = true });
    }

    public class SaveNotesRequest
    {
        public int SubmissionId { get; set; }
        public int ItemId { get; set; }
        public string? Notes { get; set; }
        public string? Actor { get; set; }
    }

    public async Task<IActionResult> OnPostSaveNotesAsync([FromBody] SaveNotesRequest req)
    {
        var response = await _db.TaskResponses
            .FirstOrDefaultAsync(r => r.ChecklistSubmissionId == req.SubmissionId && r.TaskItemId == req.ItemId);

        if (response is null)
        {
            response = new TaskResponse { ChecklistSubmissionId = req.SubmissionId, TaskItemId = req.ItemId };
            _db.TaskResponses.Add(response);
        }

        response.Notes = req.Notes;
        response.UpdatedAt = DateTime.UtcNow;
        response.AnsweredBy = string.IsNullOrWhiteSpace(req.Actor) ? "Unknown" : req.Actor;
        await _db.SaveChangesAsync();

        return new JsonResult(new { ok = true });
    }

    public class SaveMetaRequest
    {
        public int SubmissionId { get; set; }
        public string? AuditorNames { get; set; }
        public string? Location { get; set; }
        public string? Actor { get; set; }
    }

    public async Task<IActionResult> OnPostSaveMetaAsync([FromBody] SaveMetaRequest req)
    {
        var submission = await _db.ChecklistSubmissions.FindAsync(req.SubmissionId);
        if (submission is null) return NotFound();

        submission.AuditorNames = req.AuditorNames;
        submission.Location = req.Location;
        submission.LastEditedAt = DateTime.UtcNow;
        submission.LastEditedBy = string.IsNullOrWhiteSpace(req.Actor) ? "Unknown" : req.Actor;
        await _db.SaveChangesAsync();

        return new JsonResult(new { ok = true });
    }

    public class CompleteRequest
    {
        public int SubmissionId { get; set; }
        public string? CompletedBy { get; set; }
    }

    public async Task<IActionResult> OnPostCompleteAsync([FromBody] CompleteRequest req)
    {
        var result = await _checklist.CompleteAsync(req.SubmissionId, req.CompletedBy ?? "Unknown");
        if (!result.Success)
        {
            return BadRequest(new { error = result.Error });
        }
        return new JsonResult(new { ok = true });
    }
}
