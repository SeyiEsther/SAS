using System.DirectoryServices.AccountManagement;
using System.Runtime.Versioning;
using Microsoft.Extensions.Caching.Memory;
using SAS.Web.Models;

namespace SAS.Web.Services;

/// <summary>
/// Resolves the signed-in Windows user and their Active Directory display
/// name — same approach as TL's UserService, including the one-hour cache so
/// every request doesn't hit AD. Off Windows (or with no authenticated
/// identity) it falls back to the process user so local development still
/// works without a domain.
/// </summary>
public class UserService
{
    private readonly IHttpContextAccessor _http;
    private readonly ILogger<UserService> _log;
    private readonly IMemoryCache _cache;

    private static readonly TimeSpan CacheDuration = TimeSpan.FromHours(1);

    private AppUser? _current;

    public UserService(IHttpContextAccessor http, ILogger<UserService> log, IMemoryCache cache)
    {
        _http = http;
        _log = log;
        _cache = cache;
    }

    public virtual AppUser GetCurrentUser()
    {
        if (_current != null) return _current;

        var identity = _http.HttpContext?.User?.Identity;
        if (identity?.IsAuthenticated == true && !string.IsNullOrWhiteSpace(identity.Name))
        {
            var username = NormalizeAccountName(identity.Name);
            var displayName = _cache.GetOrCreate(
                $"ad-display-name::{username}",
                entry =>
                {
                    entry.AbsoluteExpirationRelativeToNow = CacheDuration;
                    return ResolveDisplayName(username);
                }) ?? username;

            _current = new AppUser { Username = username, DisplayName = displayName };
            return _current;
        }

        _current = new AppUser { Username = Environment.UserName ?? "unknown", DisplayName = "" };
        return _current;
    }

    public static string NormalizeAccountName(string identityName)
    {
        if (identityName.Contains('\\', StringComparison.Ordinal))
            return identityName.Split('\\').Last();
        if (identityName.Contains('@', StringComparison.Ordinal))
            return identityName.Split('@').First();
        return identityName;
    }

    private string ResolveDisplayName(string username)
    {
        if (!OperatingSystem.IsWindows())
            return username;

        return ResolveDisplayNameWindows(username);
    }

    [SupportedOSPlatform("windows")]
    private string ResolveDisplayNameWindows(string username)
    {
        try
        {
            using var ctx = new PrincipalContext(ContextType.Domain);
            using var user = UserPrincipal.FindByIdentity(ctx, IdentityType.SamAccountName, username);
            if (user != null)
                return user.DisplayName ?? user.GivenName ?? username;
        }
        catch (Exception ex)
        {
            _log.LogWarning("Could not get display name from AD for {User}: {Msg}", username, ex.Message);
        }
        return username;
    }
}

/// <summary>
/// Matches a configured/stored name against the signed-in user's display name
/// or account name. Copied from TL so both systems agree on who someone is:
/// exact match, "First Last" equivalence, nickname pairs (Mike/Michael), and
/// prefix matching for account names like "jsmith".
/// </summary>
public static class PortalNameMatcher
{
    public static bool Matches(string? configured, string? actual)
    {
        var a = Normalize(configured);
        var b = Normalize(actual);
        if (string.IsNullOrEmpty(a) || string.IsNullOrEmpty(b))
            return false;

        if (string.Equals(a, b, StringComparison.OrdinalIgnoreCase))
            return true;

        if (FullNamesEquivalent(a, b))
            return true;

        if (!b.Contains(' ') && a.Contains(' '))
            return FirstNamesCompatible(b, FirstNameOf(a));

        return false;
    }

    public static string Normalize(string? value) =>
        string.Join(' ', (value ?? "").Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries));

    static bool FullNamesEquivalent(string configured, string actual)
    {
        if (!configured.Contains(' ') || !actual.Contains(' '))
            return false;

        if (!string.Equals(LastNameOf(configured), LastNameOf(actual), StringComparison.OrdinalIgnoreCase))
            return false;

        return FirstNamesCompatible(FirstNameOf(configured), FirstNameOf(actual));
    }

    static bool FirstNamesCompatible(string a, string b)
    {
        if (string.Equals(a, b, StringComparison.OrdinalIgnoreCase))
            return true;

        if (NicknamesEquivalent(a, b))
            return true;

        var (shorter, longer) = a.Length <= b.Length ? (a, b) : (b, a);
        return shorter.Length >= 3 &&
               longer.StartsWith(shorter, StringComparison.OrdinalIgnoreCase);
    }

    static readonly Dictionary<string, string> NicknameCanonical =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["mike"] = "michael", ["mick"] = "michael", ["micky"] = "michael", ["mickey"] = "michael",
            ["micheal"] = "michael",
            ["nick"] = "nicholas", ["nicky"] = "nicholas", ["nik"] = "nicholas",
            ["tony"] = "anthony",
            ["jim"] = "james", ["jimmy"] = "james", ["jamie"] = "james",
            ["steve"] = "steven", ["stevie"] = "steven",
            ["bob"] = "robert", ["rob"] = "robert", ["bobby"] = "robert", ["robbie"] = "robert",
            ["bill"] = "william", ["will"] = "william", ["billy"] = "william", ["willy"] = "william",
            ["dick"] = "richard", ["rich"] = "richard", ["rick"] = "richard", ["richie"] = "richard",
            ["dave"] = "david",
            ["dan"] = "daniel", ["danny"] = "daniel",
            ["tom"] = "thomas", ["tommy"] = "thomas",
            ["chris"] = "christopher",
            ["matt"] = "matthew",
            ["andy"] = "andrew", ["drew"] = "andrew",
            ["ben"] = "benjamin",
            ["sam"] = "samuel",
            ["joe"] = "joseph", ["joey"] = "joseph",
            ["ed"] = "edward", ["eddie"] = "edward", ["ted"] = "edward",
            ["ken"] = "kenneth", ["kenny"] = "kenneth",
            ["greg"] = "gregory",
            ["pat"] = "patrick", ["paddy"] = "patrick",
            ["tim"] = "timothy", ["timmy"] = "timothy",
            ["ron"] = "ronald", ["ronnie"] = "ronald",
            ["don"] = "donald", ["donnie"] = "donald",
            ["fred"] = "frederick", ["freddie"] = "frederick",
            ["charlie"] = "charles", ["chuck"] = "charles",
            ["jon"] = "jonathan", ["johnny"] = "john", ["jack"] = "john",
            ["alex"] = "alexander", ["sandy"] = "alexander",
            ["phil"] = "philip", ["philip"] = "phillip",
            ["nate"] = "nathan",
            ["gabe"] = "gabriel",
            ["vic"] = "victor",
            ["les"] = "leslie",
            ["si"] = "simon",
        };

    static bool NicknamesEquivalent(string a, string b)
    {
        var ca = NicknameCanonical.GetValueOrDefault(a, a);
        var cb = NicknameCanonical.GetValueOrDefault(b, b);
        return string.Equals(ca, cb, StringComparison.OrdinalIgnoreCase);
    }

    static string FirstNameOf(string fullName)
    {
        var i = fullName.LastIndexOf(' ');
        return i <= 0 ? fullName : fullName[..i];
    }

    static string LastNameOf(string fullName)
    {
        var i = fullName.LastIndexOf(' ');
        return i < 0 ? fullName : fullName[(i + 1)..];
    }
}
