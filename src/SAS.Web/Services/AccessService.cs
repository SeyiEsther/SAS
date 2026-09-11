using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Services;

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

    public async Task<Person?> ResolveCurrentPersonAsync()
    {
        var user = CurrentUser;
        var people = await GetPeopleAsync();

        var byAccount = people.FirstOrDefault(p =>
            !string.IsNullOrWhiteSpace(p.Username) &&
            string.Equals(p.Username!.Trim(), user.Username, StringComparison.OrdinalIgnoreCase));
        if (byAccount is not null) return byAccount;

        return people.FirstOrDefault(p =>
            PortalNameMatcher.Matches(p.DisplayName, user.DisplayName) ||
            PortalNameMatcher.Matches(p.DisplayName, user.Username));
    }

    public async Task<string> CurrentDisplayNameAsync()
    {
        var user = CurrentUser;

        try
        {
            var person = await ResolveCurrentPersonAsync();
            if (person is not null && !string.IsNullOrWhiteSpace(person.DisplayName))
                return person.DisplayName;
        }
        catch
        {
        }

        if (!string.IsNullOrWhiteSpace(user.DisplayName) &&
            !string.Equals(user.DisplayName, user.Username, StringComparison.OrdinalIgnoreCase))
            return user.DisplayName;

        return user.Username;
    }

    public string CurrentAccountName => CurrentUser.Username;

    public async Task<bool> IsHodAsync()
    {
        if (IsAdmin()) return true;
        var person = await ResolveCurrentPersonAsync();
        return person?.Role == PersonRole.Hod;
    }

    public async Task<bool> CanAnswerAsync(TaskItem item)
    {
        if (!string.Equals(item.ResponsibleRole, PersonRole.Hod, StringComparison.OrdinalIgnoreCase))
            return true;
        return await IsHodAsync();
    }

    public Task<bool> CanSignOffAsync() => IsHodAsync();
}
