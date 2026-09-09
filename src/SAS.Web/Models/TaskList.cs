namespace SAS.Web.Models;

public class TaskList
{
    public int Id { get; set; }
    public int AreaId { get; set; }
    public Area? Area { get; set; }
    public int ShiftId { get; set; }
    public Shift? Shift { get; set; }
    public int Version { get; set; } = 1;
    public bool IsCurrent { get; set; } = true;
    public string? HealthRepsReminder { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string CreatedBy { get; set; } = string.Empty;

    public List<TaskItem> TaskItems { get; set; } = new();
}
