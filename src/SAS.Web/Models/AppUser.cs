namespace SAS.Web.Models;

public class AppUser
{
    public string Username { get; init; } = "";
    public string DisplayName { get; init; } = "";

    /// <summary>What to show in the UI and stamp on records — display name where AD gave us one.</summary>
    public string Label => string.IsNullOrWhiteSpace(DisplayName) ? Username : DisplayName;
}
