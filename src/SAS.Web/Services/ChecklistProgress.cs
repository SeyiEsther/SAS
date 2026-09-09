using SAS.Web.Models;

namespace SAS.Web.Services;

/// <summary>
/// Shared read-only helpers for working out how much of a checklist has been
/// answered. Used by the load, completion and history services alike so the
/// definition of "answered" lives in exactly one place.
/// </summary>
public static class ChecklistProgress
{
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
