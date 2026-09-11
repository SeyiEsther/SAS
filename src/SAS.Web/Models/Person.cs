namespace SAS.Web.Models;

public static class PersonRole
{
    public const string Hod = "HOD";
    public const string SeniorOperator = "Senior Operator";
}

public class Person
{
    public int Id { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string? Username { get; set; }
    public string Role { get; set; } = PersonRole.SeniorOperator;
    public int? DepartmentId { get; set; }
    public Department? Department { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}
