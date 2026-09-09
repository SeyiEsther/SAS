using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Pages.Admin;

public class AreasModel : PageModel
{
    private readonly AdminService _admin;
    public AreasModel(AdminService admin) { _admin = admin; }

    public List<Area> Areas { get; set; } = new();
    public List<Department> Departments { get; set; } = new();

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task OnGetAsync()
    {
        Departments = await _admin.GetDepartmentsAsync();
        Areas = await _admin.GetAreasAsync();
    }

    public async Task<IActionResult> OnPostCreateAsync(int departmentId, string name, string? defaultLocation, int sortOrder)
    {
        var result = await _admin.CreateAreaAsync(departmentId, name, defaultLocation, sortOrder);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostUpdateAsync(int id, int departmentId, string name, string? defaultLocation, int sortOrder, bool isActive)
    {
        var result = await _admin.UpdateAreaAsync(id, departmentId, name, defaultLocation, sortOrder, isActive);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        var result = await _admin.DeleteAreaAsync(id);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }
}
