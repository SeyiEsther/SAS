namespace SAS.Web.Models;

public class TaskCheckpoint
{
    public int Id { get; set; }
    public int TaskItemId { get; set; }
    public TaskItem? TaskItem { get; set; }
    public string Label { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}
