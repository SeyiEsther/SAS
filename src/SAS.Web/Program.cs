using Microsoft.AspNetCore.Authentication.Negotiate;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Infrastructure;
using SAS.Web.Data;
using SAS.Web.Services;

QuestPDF.Settings.License = LicenseType.Community;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException(
        "Connection string 'Default' is not configured. Set it via appsettings.Development.json (untracked), " +
        "user-secrets, or the ConnectionStrings__Default environment variable.");

builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlServer(connectionString));

static string? ResolveWritableKeyDir(params string?[] candidates)
{
    foreach (var c in candidates)
    {
        if (string.IsNullOrWhiteSpace(c)) continue;
        try
        {
            Directory.CreateDirectory(c);
            var probe = Path.Combine(c, ".writetest");
            File.WriteAllText(probe, "ok");
            File.Delete(probe);
            return c;
        }
        catch { }
    }
    return null;
}

var keyDir = ResolveWritableKeyDir(
    builder.Configuration["DataProtection:KeyPath"],
    Path.Combine(builder.Environment.ContentRootPath, "..", "SAS-dataprotection-keys"),
    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "SAS-Portal", "dataprotection-keys"));

if (keyDir is not null)
{
    builder.Services.AddDataProtection()
        .SetApplicationName("SAS-SupportAudit")
        .PersistKeysToFileSystem(new DirectoryInfo(keyDir));
}

builder.Services.AddAuthentication(NegotiateDefaults.AuthenticationScheme).AddNegotiate();
builder.Services.AddAuthorization();

builder.Services.AddHttpContextAccessor();
builder.Services.AddMemoryCache();

builder.Services.AddScoped<UserService>();
builder.Services.AddScoped<AccessService>();
builder.Services.AddScoped<ChecklistLoadService>();
builder.Services.AddScoped<ChecklistSaveService>();
builder.Services.AddScoped<ChecklistCompletionService>();
builder.Services.AddScoped<HistoryListService>();
builder.Services.AddScoped<AdminService>();
builder.Services.AddScoped<PdfExportService>();

builder.Services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(options =>
{
    options.ValueCountLimit = 20_000;
    options.ValueLengthLimit = 1024 * 1024;
});

builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "X-CSRF-TOKEN";
});

builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles);

builder.Services.AddRazorPages();

var app = builder.Build();

var logger = app.Services.GetRequiredService<ILoggerFactory>().CreateLogger("Startup");
logger.LogInformation("Data Protection keys persisted: {Persisted} ({KeyDir})", keyDir is not null, keyDir ?? "in-memory (ephemeral)");

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapRazorPages();

app.Run();
