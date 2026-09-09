namespace SAS.Web.Models;

public class ChecklistSubmission
{
    public int Id { get; set; }
    public int AreaId { get; set; }
    public Area? Area { get; set; }
    public int ShiftId { get; set; }
    public Shift? Shift { get; set; }
    public int TaskListId { get; set; }
    public TaskList? TaskList { get; set; }
    public DateOnly ChecklistDate { get; set; }
    public string? AuditorNames { get; set; }
    public string? Location { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime? LastEditedAt { get; set; }
    public string? LastEditedBy { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string? CompletedBy { get; set; }

    public List<TaskResponse> TaskResponses { get; set; } = new();
}
