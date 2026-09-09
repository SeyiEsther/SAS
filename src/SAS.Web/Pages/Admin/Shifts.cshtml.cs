using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Pages.Admin;

public class ShiftsModel : PageModel
{
    private readonly AppDbContext _db;
    public ShiftsModel(AppDbContext db) { _db = db; }

    public List<Shift> Shifts { get; set; } = new();
    public List<Department> Departments { get; set; } = new();

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task OnGetAsync()
    {
        Departments = await _db.Departments.OrderBy(d => d.SortOrder).ToListAsync();
        Shifts = await _db.Shifts.Include(s => s.Department).OrderBy(s => s.DepartmentId).ThenBy(s => s.SortOrder).ToListAsync();
    }

    public async Task<IActionResult> OnPostCreateAsync(int departmentId, string name, int sortOrder)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            Error = "Name is required.";
            return RedirectToPage();
        }
        _db.Shifts.Add(new Shift { DepartmentId = departmentId, Name = name.Trim(), SortOrder = sortOrder, IsActive = true });
        try
        {
            await _db.SaveChangesAsync();
            Message = $"Shift \"{name}\" created.";
        }
        catch (DbUpdateException)
        {
            Error = "That department already has a shift with this name.";
        }
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostUpdateAsync(int id, int departmentId, string name, int sortOrder, bool isActive)
    {
        var shift = await _db.Shifts.FindAsync(id);
        if (shift is null) return RedirectToPage();
        shift.DepartmentId = departmentId;
        shift.Name = name.Trim();
        shift.SortOrder = sortOrder;
        shift.IsActive = isActive;
        try
        {
            await _db.SaveChangesAsync();
            Message = "Shift updated.";
        }
        catch (DbUpdateException)
        {
            Error = "That department already has a shift with this name.";
        }
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        var shift = await _db.Shifts.FindAsync(id);
        if (shift is null) return RedirectToPage();
        _db.Shifts.Remove(shift);
        try
        {
            await _db.SaveChangesAsync();
            Message = "Shift deleted.";
        }
        catch (DbUpdateException)
        {
            Error = "Cannot delete this shift — remove its task lists first.";
        }
        return RedirectToPage();
    }
}
