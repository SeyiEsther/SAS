using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Services;

public class ChecklistLoadResult
{
    public required ChecklistSubmission Submission { get; init; }
    public required TaskList TaskList { get; init; }
    public required List<TaskItem> Items { get; init; }
    public bool IsGridMode { get; init; }
}

/// <summary>
/// Finds or creates the ChecklistSubmission for an Area + Shift + Date and
/// loads the current TaskList's items and checkpoints alongside it.
/// Continuity (resuming a checklist someone else started) matches on
/// Area + Shift + Date only — never a person's name.
/// </summary>
public class ChecklistLoadService
{
    private readonly AppDbContext _db;

    public ChecklistLoadService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<ChecklistLoadResult?> GetOrCreateAsync(int areaId, int shiftId, DateOnly date, string actor)
    {
        var taskList = await _db.TaskLists
            .Include(l => l.TaskItems.OrderBy(i => i.SortOrder))
                .ThenInclude(i => i.Checkpoints.OrderBy(c => c.SortOrder))
            .Where(l => l.AreaId == areaId && l.ShiftId == shiftId && l.IsCurrent)
            .OrderByDescending(l => l.Version)
            .FirstOrDefaultAsync();

        if (taskList is null) return null;

        var submission = await _db.ChecklistSubmissions
            .Include(s => s.TaskResponses)
                .ThenInclude(r => r.CheckpointResponses)
            .FirstOrDefaultAsync(s => s.AreaId == areaId && s.ShiftId == shiftId && s.ChecklistDate == date);

        if (submission is null)
        {
            var area = await _db.Areas.FindAsync(areaId);
            submission = new ChecklistSubmission
            {
                AreaId = areaId,
                ShiftId = shiftId,
                TaskListId = taskList.Id,
                ChecklistDate = date,
                Location = area?.DefaultLocation,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = string.IsNullOrWhiteSpace(actor) ? "Unknown" : actor
            };
            _db.ChecklistSubmissions.Add(submission);
            await _db.SaveChangesAsync();
            submission.TaskResponses = new List<TaskResponse>();
        }

        var items = taskList.TaskItems.ToList();
        var isGridMode = items.Any(i => i.Category != null);

        return new ChecklistLoadResult
        {
            Submission = submission,
            TaskList = taskList,
            Items = items,
            IsGridMode = isGridMode
        };
    }

    /// <summary>Loads a submission already known to exist, for read-only views (PDF export, Completed list).</summary>
    public async Task<ChecklistLoadResult?> GetExistingAsync(int areaId, int shiftId, DateOnly date)
    {
        var submission = await _db.ChecklistSubmissions
            .Include(s => s.TaskResponses)
                .ThenInclude(r => r.CheckpointResponses)
            .FirstOrDefaultAsync(s => s.AreaId == areaId && s.ShiftId == shiftId && s.ChecklistDate == date);

        if (submission is null) return null;

        var taskList = await _db.TaskLists
            .Include(l => l.TaskItems.OrderBy(i => i.SortOrder))
                .ThenInclude(i => i.Checkpoints.OrderBy(c => c.SortOrder))
            .FirstOrDefaultAsync(l => l.Id == submission.TaskListId);

        if (taskList is null) return null;

        var items = taskList.TaskItems.ToList();
        return new ChecklistLoadResult
        {
            Submission = submission,
            TaskList = taskList,
            Items = items,
            IsGridMode = items.Any(i => i.Category != null)
        };
    }
}
