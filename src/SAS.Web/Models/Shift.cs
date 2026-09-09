namespace SAS.Web.Models;

public class Shift
{
    public int Id { get; set; }
    public int DepartmentId { get; set; }
    public Department? Department { get; set; }
    public string Name { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;

    public List<TaskList> TaskLists { get; set; } = new();
}
