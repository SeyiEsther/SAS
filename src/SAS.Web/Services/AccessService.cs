using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Services;

/// <summary>
/// Who the signed-in user is allowed to be, and what that lets them do.
/// Mirrors TL's PortalAccessService: admin comes from configuration
/// (Admin:DisplayNames / Admin:Usernames / Admin:GrantAll), everyone else is
/// matched against the People table by display name or account name.
///
/// The rules themselves come from the Dispatch Warehouse audit data, not from
/// code: an item whose ResponsibleRole is "HOD" can only be answered by an
/// HOD, and an item with an EscalateToRole must be escalated to that role
/// within its EscalationWindow once it's answered as an Issue.
/// </summary>
public class AccessService
{
    private const string PeopleCacheKey = "sas-people";
    private static readonly TimeSpan CacheTtl = TimeSpan.FromSeconds(60);

    private readonly AppDbContext _db;
    private readonly UserService _users;
    private readonly IConfiguration _config;
    private readonly IMemoryCache _cache;

    public AccessService(AppDbContext db, UserService users, IConfiguration config, IMemoryCache cache)
    {
        _db = db;
        _users = users;
        _config = config;
        _cache = cache;
    }

    public AppUser CurrentUser => _users.GetCurrentUser();

    public async Task<List<Person>> GetPeopleAsync()
    {
        if (_cache.TryGetValue<List<Person>>(PeopleCacheKey, out var cached) && cached is not null)
            return cached;

        var people = await _db.People.AsNoTracking()
            .Where(p => p.IsActive)
            .OrderBy(p => p.SortOrder).ThenBy(p => p.DisplayName)
            .ToListAsync();

        _cache.Set(PeopleCacheKey, people, CacheTtl);
        return people;
    }

    public void InvalidatePeopleCache() => _cache.Remove(PeopleCacheKey);

    public async Task<List<Person>> GetHodsAsync() =>
        (await GetPeopleAsync()).Where(p => p.Role == PersonRole.Hod).ToList();

    public bool IsAdmin()
    {
        if (_config.GetValue("Admin:GrantAll", false))
            return true;

        var user = CurrentUser;

        var usernames = _config.GetSection("Admin:Usernames").Get<string[]>() ?? [];
        if (usernames.Any(u => PortalNameMatcher.Matches(u, user.Username)))
            return true;

        var displayNames = _config.GetSection("Admin:DisplayNames").Get<string[]>() ?? [];
        if (!string.IsNullOrWhiteSpace(user.DisplayName) &&
            displayNames.Any(n => PortalNameMatcher.Matches(n, user.DisplayName)))
            return true;

        return false;
    }

    /// <summary>The People row matching the signed-in user, if there is one.</summary>
    public async Task<Person?> ResolveCurrentPersonAsync()
    {
        var user = CurrentUser;
        var people = await GetPeopleAsync();
        return people.FirstOrDefault(p =>
            PortalNameMatcher.Matches(p.DisplayName, user.DisplayName) ||
            PortalNameMatcher.Matches(p.DisplayName, user.Username) ||
            (p.Username is not null && PortalNameMatcher.Matches(p.Username, user.Username)));
    }

    public async Task<bool> IsHodAsync()
    {
        if (IsAdmin()) return true;
        var person = await ResolveCurrentPersonAsync();
        return person?.Role == PersonRole.Hod;
    }

    /// <summary>
    /// Can the current user answer this check? Items the audit assigns to the
    /// HOD are HOD-only; everything else is open to whoever is on shift.
    /// </summary>
    public async Task<bool> CanAnswerAsync(TaskItem item)
    {
        if (!string.Equals(item.ResponsibleRole, PersonRole.Hod, StringComparison.OrdinalIgnoreCase))
            return true;
        return await IsHodAsync();
    }

    /// <summary>Only an HOD signs a checklist off.</summary>
    public Task<bool> CanSignOffAsync() => IsHodAsync();
}
