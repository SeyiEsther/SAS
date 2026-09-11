namespace SAS.Web.Models;

public class AppUser
{
    public string Username { get; init; } = "";
    public string DisplayName { get; init; } = "";

    public string Label => string.IsNullOrWhiteSpace(DisplayName) ? Username : DisplayName;
}
