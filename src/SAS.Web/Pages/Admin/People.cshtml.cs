using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Pages.Admin;

public class PeopleModel : PageModel
{
    private readonly AdminService _admin;
    private readonly AccessService _access;

    public PeopleModel(AdminService admin, AccessService access)
    {
        _admin = admin;
        _access = access;
    }

    public List<Person> People { get; set; } = new();
    public List<Department> Departments { get; set; } = new();
    public string CurrentUserLabel { get; set; } = "";
    public string CurrentAccountName { get; set; } = "";
    public bool CurrentUserIsHod { get; set; }

    public static readonly string[] Roles = [PersonRole.Hod, PersonRole.SeniorOperator];

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task OnGetAsync()
    {
        People = await _admin.GetAllPeopleAsync();
        Departments = await _admin.GetDepartmentsAsync();
        CurrentUserLabel = await _access.CurrentDisplayNameAsync();
        CurrentAccountName = _access.CurrentAccountName;
        CurrentUserIsHod = await _access.IsHodAsync();
    }

    public async Task<IActionResult> OnPostCreateAsync(string displayName, string? username, string role, int? departmentId, int sortOrder)
    {
        var result = await _admin.CreatePersonAsync(displayName, username, role, departmentId, sortOrder);
        Finish(result);
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostUpdateAsync(int id, string displayName, string? username, string role, int? departmentId, int sortOrder, bool isActive)
    {
        var result = await _admin.UpdatePersonAsync(id, displayName, username, role, departmentId, sortOrder, isActive);
        Finish(result);
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        var result = await _admin.DeletePersonAsync(id);
        Finish(result);
        return RedirectToPage();
    }

    private void Finish(AdminResult result)
    {
        Message = result.Message;
        Error = result.Error;
        _access.InvalidatePeopleCache();
    }
}
