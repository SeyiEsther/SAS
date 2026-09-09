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

public class CompleteResult
{
    public bool Success { get; init; }
    public string? Error { get; init; }
}

public class ChecklistService
{
    private readonly AppDbContext _db;

    public ChecklistService(AppDbContext db)
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

    public async Task<TaskResponse> SaveTaskResponseAsync(int submissionId, int taskItemId, string status, string? notes, string actor)
    {
        var response = await _db.TaskResponses
            .FirstOrDefaultAsync(r => r.ChecklistSubmissionId == submissionId && r.TaskItemId == taskItemId);

        if (response is null)
        {
            response = new TaskResponse
            {
                ChecklistSubmissionId = submissionId,
                TaskItemId = taskItemId
            };
            _db.TaskResponses.Add(response);
        }

        response.Status = status;
        response.Notes = notes;
        response.UpdatedAt = DateTime.UtcNow;
        response.AnsweredBy = string.IsNullOrWhiteSpace(actor) ? "Unknown" : actor;

        await TouchSubmissionAsync(submissionId, actor);
        await _db.SaveChangesAsync();
        return response;
    }

    public async Task<CheckpointResponse> SaveCheckpointResponseAsync(int submissionId, int taskItemId, int checkpointId, string status, string? notes, string actor)
    {
        var response = await _db.TaskResponses
            .Include(r => r.CheckpointResponses)
            .FirstOrDefaultAsync(r => r.ChecklistSubmissionId == submissionId && r.TaskItemId == taskItemId);

        if (response is null)
        {
            response = new TaskResponse
            {
                ChecklistSubmissionId = submissionId,
                TaskItemId = taskItemId
            };
            _db.TaskResponses.Add(response);
            await _db.SaveChangesAsync();
        }

        if (notes is not null)
        {
            response.Notes = notes;
        }
        response.UpdatedAt = DateTime.UtcNow;
        response.AnsweredBy = string.IsNullOrWhiteSpace(actor) ? "Unknown" : actor;

        var cp = response.CheckpointResponses.FirstOrDefault(c => c.TaskCheckpointId == checkpointId);
        if (cp is null)
        {
            cp = new CheckpointResponse
            {
                TaskResponseId = response.Id,
                TaskCheckpointId = checkpointId
            };
            _db.CheckpointResponses.Add(cp);
        }

        cp.Status = status;
        cp.Ticked = true;
        cp.TickedAt = DateTime.UtcNow;

        await TouchSubmissionAsync(submissionId, actor);
        await _db.SaveChangesAsync();
        return cp;
    }

    private async Task TouchSubmissionAsync(int submissionId, string actor)
    {
        var submission = await _db.ChecklistSubmissions.FindAsync(submissionId);
        if (submission is null) return;
        submission.LastEditedAt = DateTime.UtcNow;
        submission.LastEditedBy = string.IsNullOrWhiteSpace(actor) ? "Unknown" : actor;
    }

    public async Task<CompleteResult> CompleteAsync(int submissionId, string completedBy)
    {
        var submission = await _db.ChecklistSubmissions
            .Include(s => s.TaskList)!.ThenInclude(l => l!.TaskItems)
                .ThenInclude(i => i.Checkpoints)
            .Include(s => s.TaskResponses)
                .ThenInclude(r => r.CheckpointResponses)
            .FirstOrDefaultAsync(s => s.Id == submissionId);

        if (submission is null)
        {
            return new CompleteResult { Success = false, Error = "Checklist not found." };
        }

        var items = submission.TaskList!.TaskItems;
        foreach (var item in items)
        {
            var response = submission.TaskResponses.FirstOrDefault(r => r.TaskItemId == item.Id);

            if (item.IsTimeBoxed && item.Checkpoints.Count > 0)
            {
                foreach (var cp in item.Checkpoints)
                {
                    var cpResponse = response?.CheckpointResponses.FirstOrDefault(c => c.TaskCheckpointId == cp.Id);
                    if (cpResponse is null || string.IsNullOrEmpty(cpResponse.Status))
                    {
                        return new CompleteResult { Success = false, Error = $"\"{item.Text}\" — {cp.Label} has not been answered." };
                    }
                    if (cpResponse.Status == ResponseStatus.Issue && string.IsNullOrWhiteSpace(response?.Notes))
                    {
                        return new CompleteResult { Success = false, Error = $"\"{item.Text}\" has an issue at {cp.Label} but no notes." };
                    }
                }
            }
            else
            {
                if (response is null || string.IsNullOrEmpty(response.Status))
                {
                    return new CompleteResult { Success = false, Error = $"\"{item.Text}\" has not been answered." };
                }
                if (response.Status == ResponseStatus.Issue && string.IsNullOrWhiteSpace(response.Notes))
                {
                    return new CompleteResult { Success = false, Error = $"\"{item.Text}\" is marked Issue but has no notes." };
                }
            }
        }

        submission.CompletedAt = DateTime.UtcNow;
        submission.CompletedBy = string.IsNullOrWhiteSpace(completedBy) ? "Unknown" : completedBy;
        await _db.SaveChangesAsync();

        return new CompleteResult { Success = true };
    }

    public static bool IsItemAnswered(TaskItem item, ChecklistSubmission submission)
    {
        var response = submission.TaskResponses.FirstOrDefault(r => r.TaskItemId == item.Id);
        if (item.IsTimeBoxed && item.Checkpoints.Count > 0)
        {
            return item.Checkpoints.All(cp =>
                response?.CheckpointResponses.Any(c => c.TaskCheckpointId == cp.Id && !string.IsNullOrEmpty(c.Status)) == true);
        }
        return response is not null && !string.IsNullOrEmpty(response.Status);
    }

    public static (int answered, int total) ComputeProgress(List<TaskItem> items, ChecklistSubmission submission)
    {
        int total = items.Count;
        int answered = items.Count(item => IsItemAnswered(item, submission));
        return (answered, total);
    }

    public static int CountIssues(List<TaskItem> items, ChecklistSubmission submission)
    {
        int issues = 0;
        foreach (var item in items)
        {
            var response = submission.TaskResponses.FirstOrDefault(r => r.TaskItemId == item.Id);
            if (response is null) continue;

            if (item.IsTimeBoxed && item.Checkpoints.Count > 0)
            {
                issues += response.CheckpointResponses.Count(c => c.Status == ResponseStatus.Issue);
            }
            else if (response.Status == ResponseStatus.Issue)
            {
                issues++;
            }
        }
        return issues;
    }
}
