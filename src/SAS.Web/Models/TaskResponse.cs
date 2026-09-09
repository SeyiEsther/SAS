namespace SAS.Web.Models;

public static class ResponseStatus
{
    public const string Done = "Done";
    public const string Issue = "Issue";
}

public class TaskResponse
{
    public int Id { get; set; }
    public int ChecklistSubmissionId { get; set; }
    public ChecklistSubmission? ChecklistSubmission { get; set; }
    public int TaskItemId { get; set; }
    public TaskItem? TaskItem { get; set; }
    public string? Status { get; set; }
    public string? Notes { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public string? AnsweredBy { get; set; }

    public List<CheckpointResponse> CheckpointResponses { get; set; } = new();
}
