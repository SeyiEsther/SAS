using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Pages.Admin;

public class TaskListsModel : PageModel
{
    private readonly AppDbContext _db;
    public TaskListsModel(AppDbContext db) { _db = db; }

    public List<TaskList> Lists { get; set; } = new();
    public List<Area> Areas { get; set; } = new();
    public List<Shift> Shifts { get; set; } = new();

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task OnGetAsync()
    {
        Areas = await _db.Areas.Include(a => a.Department).OrderBy(a => a.SortOrder).ToListAsync();
        Shifts = await _db.Shifts.Include(s => s.Department).OrderBy(s => s.SortOrder).ToListAsync();
        Lists = await _db.TaskLists
            .Include(l => l.Area).ThenInclude(a => a!.Department)
            .Include(l => l.Shift)
            .Include(l => l.TaskItems)
            .OrderBy(l => l.Area!.DepartmentId).ThenBy(l => l.AreaId).ThenBy(l => l.ShiftId).ThenByDescending(l => l.Version)
            .ToListAsync();
    }

    public async Task<IActionResult> OnPostCreateAsync(int areaId, int shiftId, string? healthRepsReminder)
    {
        var area = await _db.Areas.FirstOrDefaultAsync(a => a.Id == areaId);
        var shift = await _db.Shifts.FirstOrDefaultAsync(s => s.Id == shiftId);
        if (area is null || shift is null || area.DepartmentId != shift.DepartmentId)
        {
            Error = "Pick an area and shift that belong to the same department.";
            return RedirectToPage();
        }

        var existing = await _db.TaskLists.Where(l => l.AreaId == areaId && l.ShiftId == shiftId).ToListAsync();
        if (existing.Any(l => l.IsCurrent))
        {
            Error = "A current task list already exists for this area and shift. Use \"New version\" instead.";
            return RedirectToPage();
        }

        var nextVersion = existing.Any() ? existing.Max(l => l.Version) + 1 : 1;
        _db.TaskLists.Add(new TaskList
        {
            AreaId = areaId,
            ShiftId = shiftId,
            Version = nextVersion,
            IsCurrent = true,
            HealthRepsReminder = healthRepsReminder,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = "Admin"
        });
        await _db.SaveChangesAsync();
        Message = "Task list created. Add tasks to it from the list below.";
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostNewVersionAsync(int sourceId)
    {
        var source = await _db.TaskLists
            .Include(l => l.TaskItems).ThenInclude(i => i.Checkpoints)
            .FirstOrDefaultAsync(l => l.Id == sourceId);
        if (source is null) return RedirectToPage();

        var siblings = await _db.TaskLists.Where(l => l.AreaId == source.AreaId && l.ShiftId == source.ShiftId).ToListAsync();
        foreach (var s in siblings) s.IsCurrent = false;

        var clone = new TaskList
        {
            AreaId = source.AreaId,
            ShiftId = source.ShiftId,
            Version = siblings.Max(l => l.Version) + 1,
            IsCurrent = true,
            HealthRepsReminder = source.HealthRepsReminder,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = "Admin"
        };
        foreach (var item in source.TaskItems.OrderBy(i => i.SortOrder))
        {
            var newItem = new TaskItem
            {
                Text = item.Text,
                SortOrder = item.SortOrder,
                IsTimeBoxed = item.IsTimeBoxed,
                Category = item.Category,
                Cadence = item.Cadence,
                ResponsibleRole = item.ResponsibleRole,
                EscalateToRole = item.EscalateToRole,
                EscalationWindow = item.EscalationWindow
            };
            foreach (var cp in item.Checkpoints.OrderBy(c => c.SortOrder))
            {
                newItem.Checkpoints.Add(new TaskCheckpoint { Label = cp.Label, SortOrder = cp.SortOrder });
            }
            clone.TaskItems.Add(newItem);
        }

        _db.TaskLists.Add(clone);
        await _db.SaveChangesAsync();
        Message = $"Created version {clone.Version}, copied from version {source.Version}. It is now current.";
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostSetCurrentAsync(int id)
    {
        var list = await _db.TaskLists.FindAsync(id);
        if (list is null) return RedirectToPage();
        var siblings = await _db.TaskLists.Where(l => l.AreaId == list.AreaId && l.ShiftId == list.ShiftId).ToListAsync();
        foreach (var s in siblings) s.IsCurrent = s.Id == id;
        await _db.SaveChangesAsync();
        Message = $"Version {list.Version} is now current.";
        return RedirectToPage();
    }
}
