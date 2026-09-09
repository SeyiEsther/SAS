using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Pages.Admin;

public class TaskListsModel : PageModel
{
    private readonly AdminService _admin;
    public TaskListsModel(AdminService admin) { _admin = admin; }

    public List<TaskList> Lists { get; set; } = new();
    public List<Area> Areas { get; set; } = new();
    public List<Shift> Shifts { get; set; } = new();

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task OnGetAsync()
    {
        Areas = await _admin.GetAreasAsync();
        Shifts = await _admin.GetShiftsAsync();
        Lists = await _admin.GetTaskListsAsync();
    }

    public async Task<IActionResult> OnPostCreateAsync(int areaId, int shiftId, string? healthRepsReminder)
    {
        var result = await _admin.CreateTaskListAsync(areaId, shiftId, healthRepsReminder, "Admin");
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostNewVersionAsync(int sourceId)
    {
        var result = await _admin.CreateNewVersionAsync(sourceId, "Admin");
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostSetCurrentAsync(int id)
    {
        var result = await _admin.SetCurrentTaskListAsync(id);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage();
    }
}
