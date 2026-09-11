namespace SAS.Web.Models;

public class TaskItem
{
    public int Id { get; set; }
    public int TaskListId { get; set; }
    public TaskList? TaskList { get; set; }
    public string Text { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public bool IsTimeBoxed { get; set; }

    public string? Category { get; set; }
    public string? Cadence { get; set; }
    public string? ResponsibleRole { get; set; }
    public string? EscalateToRole { get; set; }
    public string? EscalationWindow { get; set; }

    public List<TaskCheckpoint> Checkpoints { get; set; } = new();
}
