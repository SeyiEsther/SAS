using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Pages.Admin;

public class AreasModel : PageModel
{
    private readonly AppDbContext _db;
    public AreasModel(AppDbContext db) { _db = db; }

    public List<Area> Areas { get; set; } = new();
    public List<Department> Departments { get; set; } = new();

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task OnGetAsync()
    {
        Departments = await _db.Departments.OrderBy(d => d.SortOrder).ToListAsync();
        Areas = await _db.Areas.Include(a => a.Department).OrderBy(a => a.DepartmentId).ThenBy(a => a.SortOrder).ToListAsync();
    }

    public async Task<IActionResult> OnPostCreateAsync(int departmentId, string name, string? defaultLocation, int sortOrder)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            Error = "Name is required.";
            return RedirectToPage();
        }
        _db.Areas.Add(new Area
        {
            DepartmentId = departmentId,
            Name = name.Trim(),
            DefaultLocation = defaultLocation,
            SortOrder = sortOrder,
            IsActive = true
        });
        try
        {
            await _db.SaveChangesAsync();
            Message = $"Area \"{name}\" created.";
        }
        catch (DbUpdateException)
        {
            Error = "That department already has an area with this name.";
        }
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostUpdateAsync(int id, int departmentId, string name, string? defaultLocation, int sortOrder, bool isActive)
    {
        var area = await _db.Areas.FindAsync(id);
        if (area is null) return RedirectToPage();
        area.DepartmentId = departmentId;
        area.Name = name.Trim();
        area.DefaultLocation = defaultLocation;
        area.SortOrder = sortOrder;
        area.IsActive = isActive;
        try
        {
            await _db.SaveChangesAsync();
            Message = "Area updated.";
        }
        catch (DbUpdateException)
        {
            Error = "That department already has an area with this name.";
        }
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        var area = await _db.Areas.FindAsync(id);
        if (area is null) return RedirectToPage();
        _db.Areas.Remove(area);
        try
        {
            await _db.SaveChangesAsync();
            Message = "Area deleted.";
        }
        catch (DbUpdateException)
        {
            Error = "Cannot delete this area — remove its task lists first.";
        }
        return RedirectToPage();
    }
}
