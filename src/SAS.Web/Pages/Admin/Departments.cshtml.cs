using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Pages.Admin;

public class DepartmentsModel : PageModel
{
    private readonly AppDbContext _db;
    public DepartmentsModel(AppDbContext db) { _db = db; }

    public List<Department> Departments { get; set; } = new();

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task OnGetAsync()
    {
        Departments = await _db.Departments.OrderBy(d => d.SortOrder).ToListAsync();
    }

    public async Task<IActionResult> OnPostCreateAsync(string name, int sortOrder)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            Error = "Name is required.";
            return RedirectToPage();
        }
        _db.Departments.Add(new Department { Name = name.Trim(), SortOrder = sortOrder, IsActive = true });
        try
        {
            await _db.SaveChangesAsync();
            Message = $"Department \"{name}\" created.";
        }
        catch (DbUpdateException)
        {
            Error = "A department with that name already exists.";
        }
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostUpdateAsync(int id, string name, int sortOrder, bool isActive)
    {
        var dept = await _db.Departments.FindAsync(id);
        if (dept is null) return RedirectToPage();
        dept.Name = name.Trim();
        dept.SortOrder = sortOrder;
        dept.IsActive = isActive;
        try
        {
            await _db.SaveChangesAsync();
            Message = "Department updated.";
        }
        catch (DbUpdateException)
        {
            Error = "A department with that name already exists.";
        }
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        var dept = await _db.Departments.FindAsync(id);
        if (dept is null) return RedirectToPage();
        _db.Departments.Remove(dept);
        try
        {
            await _db.SaveChangesAsync();
            Message = "Department deleted.";
        }
        catch (DbUpdateException)
        {
            Error = "Cannot delete this department — remove its areas and shifts first.";
        }
        return RedirectToPage();
    }
}
