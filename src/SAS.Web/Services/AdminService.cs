using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Services;

public class AdminResult
{
    public bool Success { get; init; }
    public string? Error { get; init; }
    public string? Message { get; init; }

    public static AdminResult Ok(string message) => new() { Success = true, Message = message };
    public static AdminResult Fail(string error) => new() { Success = false, Error = error };
}

/// <summary>
/// Full CRUD for every configuration table (Departments, Areas, Shifts,
/// TaskLists, TaskItems, TaskCheckpoints) — this is the only place that
/// writes to those tables outside of a migration. The governing rule this
/// exists to serve: the whole of a department could be deleted and
/// re-entered here with no code change and no redeployment.
/// </summary>
public class AdminService
{
    private readonly AppDbContext _db;

    public AdminService(AppDbContext db)
    {
        _db = db;
    }

    // ---------------- Departments ----------------

    public async Task<List<Department>> GetDepartmentsAsync() =>
        await _db.Departments.OrderBy(d => d.SortOrder).ToListAsync();

    public async Task<AdminResult> CreateDepartmentAsync(string name, int sortOrder)
    {
        if (string.IsNullOrWhiteSpace(name)) return AdminResult.Fail("Name is required.");
        _db.Departments.Add(new Department { Name = name.Trim(), SortOrder = sortOrder, IsActive = true });
        return await TrySaveAsync($"Department \"{name}\" created.", "A department with that name already exists.");
    }

    public async Task<AdminResult> UpdateDepartmentAsync(int id, string name, int sortOrder, bool isActive)
    {
        var dept = await _db.Departments.FindAsync(id);
        if (dept is null) return AdminResult.Fail("Department not found.");
        dept.Name = name.Trim();
        dept.SortOrder = sortOrder;
        dept.IsActive = isActive;
        return await TrySaveAsync("Department updated.", "A department with that name already exists.");
    }

    public async Task<AdminResult> DeleteDepartmentAsync(int id)
    {
        var dept = await _db.Departments.FindAsync(id);
        if (dept is null) return AdminResult.Fail("Department not found.");
        _db.Departments.Remove(dept);
        return await TrySaveAsync("Department deleted.", "Cannot delete this department — remove its areas and shifts first.");
    }

    // ---------------- Areas ----------------

    public async Task<List<Area>> GetAreasAsync() =>
        await _db.Areas.Include(a => a.Department).OrderBy(a => a.DepartmentId).ThenBy(a => a.SortOrder).ToListAsync();

    public async Task<AdminResult> CreateAreaAsync(int departmentId, string name, string? defaultLocation, int sortOrder)
    {
        if (string.IsNullOrWhiteSpace(name)) return AdminResult.Fail("Name is required.");
        _db.Areas.Add(new Area { DepartmentId = departmentId, Name = name.Trim(), DefaultLocation = defaultLocation, SortOrder = sortOrder, IsActive = true });
        return await TrySaveAsync($"Area \"{name}\" created.", "That department already has an area with this name.");
    }

    public async Task<AdminResult> UpdateAreaAsync(int id, int departmentId, string name, string? defaultLocation, int sortOrder, bool isActive)
    {
        var area = await _db.Areas.FindAsync(id);
        if (area is null) return AdminResult.Fail("Area not found.");
        area.DepartmentId = departmentId;
        area.Name = name.Trim();
        area.DefaultLocation = defaultLocation;
        area.SortOrder = sortOrder;
        area.IsActive = isActive;
        return await TrySaveAsync("Area updated.", "That department already has an area with this name.");
    }

    public async Task<AdminResult> DeleteAreaAsync(int id)
    {
        var area = await _db.Areas.FindAsync(id);
        if (area is null) return AdminResult.Fail("Area not found.");
        _db.Areas.Remove(area);
        return await TrySaveAsync("Area deleted.", "Cannot delete this area — remove its task lists first.");
    }

    // ---------------- Shifts ----------------

    public async Task<List<Shift>> GetShiftsAsync() =>
        await _db.Shifts.Include(s => s.Department).OrderBy(s => s.DepartmentId).ThenBy(s => s.SortOrder).ToListAsync();

    public async Task<AdminResult> CreateShiftAsync(int departmentId, string name, int sortOrder)
    {
        if (string.IsNullOrWhiteSpace(name)) return AdminResult.Fail("Name is required.");
        _db.Shifts.Add(new Shift { DepartmentId = departmentId, Name = name.Trim(), SortOrder = sortOrder, IsActive = true });
        return await TrySaveAsync($"Shift \"{name}\" created.", "That department already has a shift with this name.");
    }

    public async Task<AdminResult> UpdateShiftAsync(int id, int departmentId, string name, int sortOrder, bool isActive)
    {
        var shift = await _db.Shifts.FindAsync(id);
        if (shift is null) return AdminResult.Fail("Shift not found.");
        shift.DepartmentId = departmentId;
        shift.Name = name.Trim();
        shift.SortOrder = sortOrder;
        shift.IsActive = isActive;
        return await TrySaveAsync("Shift updated.", "That department already has a shift with this name.");
    }

    public async Task<AdminResult> DeleteShiftAsync(int id)
    {
        var shift = await _db.Shifts.FindAsync(id);
        if (shift is null) return AdminResult.Fail("Shift not found.");
        _db.Shifts.Remove(shift);
        return await TrySaveAsync("Shift deleted.", "Cannot delete this shift — remove its task lists first.");
    }

    // ---------------- TaskLists ----------------

    public async Task<List<TaskList>> GetTaskListsAsync() =>
        await _db.TaskLists
            .Include(l => l.Area).ThenInclude(a => a!.Department)
            .Include(l => l.Shift)
            .Include(l => l.TaskItems)
            .OrderBy(l => l.Area!.DepartmentId).ThenBy(l => l.AreaId).ThenBy(l => l.ShiftId).ThenByDescending(l => l.Version)
            .ToListAsync();

    public async Task<TaskList?> GetTaskListWithItemsAsync(int id) =>
        await _db.TaskLists
            .Include(l => l.Area).ThenInclude(a => a!.Department)
            .Include(l => l.Shift)
            .FirstOrDefaultAsync(l => l.Id == id);

    public async Task<List<TaskItem>> GetTaskItemsAsync(int taskListId) =>
        await _db.TaskItems.Include(i => i.Checkpoints.OrderBy(c => c.SortOrder))
            .Where(i => i.TaskListId == taskListId).OrderBy(i => i.SortOrder).ToListAsync();

    public async Task<AdminResult> CreateTaskListAsync(int areaId, int shiftId, string? healthRepsReminder, string createdBy)
    {
        var area = await _db.Areas.FirstOrDefaultAsync(a => a.Id == areaId);
        var shift = await _db.Shifts.FirstOrDefaultAsync(s => s.Id == shiftId);
        if (area is null || shift is null || area.DepartmentId != shift.DepartmentId)
        {
            return AdminResult.Fail("Pick an area and shift that belong to the same department.");
        }

        var existing = await _db.TaskLists.Where(l => l.AreaId == areaId && l.ShiftId == shiftId).ToListAsync();
        if (existing.Any(l => l.IsCurrent))
        {
            return AdminResult.Fail("A current task list already exists for this area and shift. Use \"New version\" instead.");
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
            CreatedBy = createdBy
        });
        await _db.SaveChangesAsync();
        return AdminResult.Ok("Task list created. Add tasks to it from the list below.");
    }

    public async Task<AdminResult> CreateNewVersionAsync(int sourceId, string createdBy)
    {
        var source = await _db.TaskLists
            .Include(l => l.TaskItems).ThenInclude(i => i.Checkpoints)
            .FirstOrDefaultAsync(l => l.Id == sourceId);
        if (source is null) return AdminResult.Fail("Task list not found.");

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
            CreatedBy = createdBy
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
        return AdminResult.Ok($"Created version {clone.Version}, copied from version {source.Version}. It is now current.");
    }

    public async Task<AdminResult> SetCurrentTaskListAsync(int id)
    {
        var list = await _db.TaskLists.FindAsync(id);
        if (list is null) return AdminResult.Fail("Task list not found.");
        var siblings = await _db.TaskLists.Where(l => l.AreaId == list.AreaId && l.ShiftId == list.ShiftId).ToListAsync();
        foreach (var s in siblings) s.IsCurrent = s.Id == id;
        await _db.SaveChangesAsync();
        return AdminResult.Ok($"Version {list.Version} is now current.");
    }

    // ---------------- TaskItems ----------------

    public async Task<AdminResult> CreateTaskItemAsync(int taskListId, string text, int sortOrder, bool isTimeBoxed,
        string? category, string? cadence, string? responsibleRole, string? escalateToRole, string? escalationWindow)
    {
        _db.TaskItems.Add(new TaskItem
        {
            TaskListId = taskListId,
            Text = text.Trim(),
            SortOrder = sortOrder,
            IsTimeBoxed = isTimeBoxed,
            Category = string.IsNullOrWhiteSpace(category) ? null : category.Trim(),
            Cadence = string.IsNullOrWhiteSpace(cadence) ? null : cadence.Trim(),
            ResponsibleRole = string.IsNullOrWhiteSpace(responsibleRole) ? null : responsibleRole.Trim(),
            EscalateToRole = string.IsNullOrWhiteSpace(escalateToRole) ? null : escalateToRole.Trim(),
            EscalationWindow = string.IsNullOrWhiteSpace(escalationWindow) ? null : escalationWindow.Trim()
        });
        await _db.SaveChangesAsync();
        return AdminResult.Ok("Task added.");
    }

    public async Task<AdminResult> UpdateTaskItemAsync(int id, string text, int sortOrder, bool isTimeBoxed,
        string? category, string? cadence, string? responsibleRole, string? escalateToRole, string? escalationWindow)
    {
        var item = await _db.TaskItems.FindAsync(id);
        if (item is null) return AdminResult.Fail("Task not found.");
        item.Text = text.Trim();
        item.SortOrder = sortOrder;
        item.IsTimeBoxed = isTimeBoxed;
        item.Category = string.IsNullOrWhiteSpace(category) ? null : category.Trim();
        item.Cadence = string.IsNullOrWhiteSpace(cadence) ? null : cadence.Trim();
        item.ResponsibleRole = string.IsNullOrWhiteSpace(responsibleRole) ? null : responsibleRole.Trim();
        item.EscalateToRole = string.IsNullOrWhiteSpace(escalateToRole) ? null : escalateToRole.Trim();
        item.EscalationWindow = string.IsNullOrWhiteSpace(escalationWindow) ? null : escalationWindow.Trim();
        await _db.SaveChangesAsync();
        return AdminResult.Ok("Task updated.");
    }

    public async Task<AdminResult> DeleteTaskItemAsync(int id)
    {
        var item = await _db.TaskItems.FindAsync(id);
        if (item is null) return AdminResult.Fail("Task not found.");
        _db.TaskItems.Remove(item);
        await _db.SaveChangesAsync();
        return AdminResult.Ok("Task deleted.");
    }

    // ---------------- TaskCheckpoints ----------------

    public async Task<AdminResult> CreateCheckpointAsync(int taskItemId, string label, int sortOrder)
    {
        _db.TaskCheckpoints.Add(new TaskCheckpoint { TaskItemId = taskItemId, Label = label.Trim(), SortOrder = sortOrder });
        await _db.SaveChangesAsync();
        return AdminResult.Ok("Checkpoint added.");
    }

    public async Task<AdminResult> DeleteCheckpointAsync(int id)
    {
        var cp = await _db.TaskCheckpoints.FindAsync(id);
        if (cp is null) return AdminResult.Fail("Checkpoint not found.");
        _db.TaskCheckpoints.Remove(cp);
        await _db.SaveChangesAsync();
        return AdminResult.Ok("Checkpoint deleted.");
    }

    // ---------------- People (HODs / Senior Operators) ----------------

    public async Task<List<Person>> GetAllPeopleAsync() =>
        await _db.People.Include(p => p.Department)
            .OrderBy(p => p.Role).ThenBy(p => p.SortOrder).ThenBy(p => p.DisplayName)
            .ToListAsync();

    public async Task<AdminResult> CreatePersonAsync(string displayName, string? username, string role, int? departmentId, int sortOrder)
    {
        if (string.IsNullOrWhiteSpace(displayName)) return AdminResult.Fail("Name is required.");
        _db.People.Add(new Person
        {
            DisplayName = displayName.Trim(),
            Username = string.IsNullOrWhiteSpace(username) ? null : username.Trim(),
            Role = role,
            DepartmentId = departmentId,
            SortOrder = sortOrder,
            IsActive = true
        });
        return await TrySaveAsync($"\"{displayName}\" added.", "Someone with that name already holds that role.");
    }

    public async Task<AdminResult> UpdatePersonAsync(int id, string displayName, string? username, string role, int? departmentId, int sortOrder, bool isActive)
    {
        var person = await _db.People.FindAsync(id);
        if (person is null) return AdminResult.Fail("Person not found.");
        person.DisplayName = displayName.Trim();
        person.Username = string.IsNullOrWhiteSpace(username) ? null : username.Trim();
        person.Role = role;
        person.DepartmentId = departmentId;
        person.SortOrder = sortOrder;
        person.IsActive = isActive;
        return await TrySaveAsync("Updated.", "Someone with that name already holds that role.");
    }

    public async Task<AdminResult> DeletePersonAsync(int id)
    {
        var person = await _db.People.FindAsync(id);
        if (person is null) return AdminResult.Fail("Person not found.");
        _db.People.Remove(person);
        return await TrySaveAsync("Removed.", "Could not remove this person.");
    }

    // ---------------- helpers ----------------

    private async Task<AdminResult> TrySaveAsync(string successMessage, string conflictError)
    {
        try
        {
            await _db.SaveChangesAsync();
            return AdminResult.Ok(successMessage);
        }
        catch (DbUpdateException)
        {
            return AdminResult.Fail(conflictError);
        }
    }
}
