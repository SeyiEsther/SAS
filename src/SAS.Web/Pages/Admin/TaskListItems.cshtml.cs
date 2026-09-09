using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Pages.Admin;

public class TaskListItemsModel : PageModel
{
    private readonly AdminService _admin;
    public TaskListItemsModel(AdminService admin) { _admin = admin; }

    public TaskList? List { get; set; }
    public List<TaskItem> Items { get; set; } = new();

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task<IActionResult> OnGetAsync(int id)
    {
        List = await _admin.GetTaskListWithItemsAsync(id);
        if (List is null) return NotFound();

        Items = await _admin.GetTaskItemsAsync(id);
        return Page();
    }

    public async Task<IActionResult> OnPostCreateItemAsync(int taskListId, string text, int sortOrder, bool isTimeBoxed,
        string? category, string? cadence, string? responsibleRole, string? escalateToRole, string? escalationWindow)
    {
        var result = await _admin.CreateTaskItemAsync(taskListId, text, sortOrder, isTimeBoxed, category, cadence, responsibleRole, escalateToRole, escalationWindow);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage(new { id = taskListId });
    }

    public async Task<IActionResult> OnPostUpdateItemAsync(int id, int taskListId, string text, int sortOrder, bool isTimeBoxed,
        string? category, string? cadence, string? responsibleRole, string? escalateToRole, string? escalationWindow)
    {
        var result = await _admin.UpdateTaskItemAsync(id, text, sortOrder, isTimeBoxed, category, cadence, responsibleRole, escalateToRole, escalationWindow);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage(new { id = taskListId });
    }

    public async Task<IActionResult> OnPostDeleteItemAsync(int id, int taskListId)
    {
        var result = await _admin.DeleteTaskItemAsync(id);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage(new { id = taskListId });
    }

    public async Task<IActionResult> OnPostCreateCheckpointAsync(int taskItemId, int taskListId, string label, int sortOrder)
    {
        var result = await _admin.CreateCheckpointAsync(taskItemId, label, sortOrder);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage(new { id = taskListId });
    }

    public async Task<IActionResult> OnPostDeleteCheckpointAsync(int id, int taskListId)
    {
        var result = await _admin.DeleteCheckpointAsync(id);
        Message = result.Message;
        Error = result.Error;
        return RedirectToPage(new { id = taskListId });
    }
}
