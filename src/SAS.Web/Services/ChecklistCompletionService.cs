using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Services;

public class CompleteResult
{
    public bool Success { get; init; }
    public string? Error { get; init; }
}

/// <summary>
/// Gates and performs sign-off: every item must be answered, and every Issue
/// must carry notes, before a checklist can be marked complete. A save is
/// only ever confirmed successful after this genuinely commits.
/// </summary>
public class ChecklistCompletionService
{
    private readonly AppDbContext _db;

    public ChecklistCompletionService(AppDbContext db)
    {
        _db = db;
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
}
