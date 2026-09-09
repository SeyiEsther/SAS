namespace SAS.Web.Models;

public static class PersonRole
{
    public const string Hod = "HOD";
    public const string SeniorOperator = "Senior Operator";
}

/// <summary>
/// Who may answer HOD-only checks and who may sign a checklist off. Names live
/// in the database and are editable in Admin — nothing about a person is
/// hardcoded. Matched against the signed-in Windows user by display name or
/// account name (see PortalNameMatcher).
/// </summary>
public class Person
{
    public int Id { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    /// <summary>AD sAMAccountName, when known. Optional — display name matching is the primary route.</summary>
    public string? Username { get; set; }
    public string Role { get; set; } = PersonRole.SeniorOperator;
    /// <summary>Null means the person covers every department.</summary>
    public int? DepartmentId { get; set; }
    public Department? Department { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}
