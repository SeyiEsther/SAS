using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Pages.Admin;

public class ShiftsModel : PageModel
{
    private readonly AdminService _admin;
    public ShiftsModel(AdminService admin) { _admin = admin; }

    public List<Shift> Shifts { get; set; } = new();
    public List<Department> Departments { get; set; } = new();

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task OnGetAsync()
    {
        Departments = await _admin.GetDepartmentsAsync();
        Shifts = await _admin.GetShiftsAsync();
    }

    public async Task<IActionResult> OnPostCreateAsync(int departmentId, string name, int sortOrder)
    {
        var result = await _admin.CreateShiftAsync(departmentId, name, sortOrder);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostUpdateAsync(int id, int departmentId, string name, int sortOrder, bool isActive)
    {
        var result = await _admin.UpdateShiftAsync(id, departmentId, name, sortOrder, isActive);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        var result = await _admin.DeleteShiftAsync(id);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }
}
