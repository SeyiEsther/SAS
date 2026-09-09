namespace SAS.Web.Models;

public class Department
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;

    public List<Area> Areas { get; set; } = new();
    public List<Shift> Shifts { get; set; } = new();
}
