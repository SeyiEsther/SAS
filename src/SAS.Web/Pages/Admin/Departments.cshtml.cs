using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Pages.Admin;

public class DepartmentsModel : PageModel
{
    private readonly AdminService _admin;
    public DepartmentsModel(AdminService admin) { _admin = admin; }

    public List<Department> Departments { get; set; } = new();

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task OnGetAsync()
    {
        Departments = await _admin.GetDepartmentsAsync();
    }

    public async Task<IActionResult> OnPostCreateAsync(string name, int sortOrder)
    {
        var result = await _admin.CreateDepartmentAsync(name, sortOrder);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostUpdateAsync(int id, string name, int sortOrder, bool isActive)
    {
        var result = await _admin.UpdateDepartmentAsync(id, name, sortOrder, isActive);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        var result = await _admin.DeleteDepartmentAsync(id);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }
}
