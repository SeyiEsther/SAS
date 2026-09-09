using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Pages.Admin;

public class TaskListItemsModel : PageModel
{
    private readonly AppDbContext _db;
    public TaskListItemsModel(AppDbContext db) { _db = db; }

    public TaskList? List { get; set; }
    public List<TaskItem> Items { get; set; } = new();

    [TempData]
    public string? Message { get; set; }
    [TempData]
    public string? Error { get; set; }

    public async Task<IActionResult> OnGetAsync(int id)
    {
        List = await _db.TaskLists
            .Include(l => l.Area).ThenInclude(a => a!.Department)
            .Include(l => l.Shift)
            .FirstOrDefaultAsync(l => l.Id == id);
        if (List is null) return NotFound();

        Items = await _db.TaskItems
            .Include(i => i.Checkpoints.OrderBy(c => c.SortOrder))
            .Where(i => i.TaskListId == id)
            .OrderBy(i => i.SortOrder)
            .ToListAsync();

        return Page();
    }

    public async Task<IActionResult> OnPostCreateItemAsync(int taskListId, string text, int sortOrder, bool isTimeBoxed,
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
        Message = "Task added.";
        return RedirectToPage(new { id = taskListId });
    }

    public async Task<IActionResult> OnPostUpdateItemAsync(int id, int taskListId, string text, int sortOrder, bool isTimeBoxed,
        string? category, string? cadence, string? responsibleRole, string? escalateToRole, string? escalationWindow)
    {
        var item = await _db.TaskItems.FindAsync(id);
        if (item is null) return RedirectToPage(new { id = taskListId });
        item.Text = text.Trim();
        item.SortOrder = sortOrder;
        item.IsTimeBoxed = isTimeBoxed;
        item.Category = string.IsNullOrWhiteSpace(category) ? null : category.Trim();
        item.Cadence = string.IsNullOrWhiteSpace(cadence) ? null : cadence.Trim();
        item.ResponsibleRole = string.IsNullOrWhiteSpace(responsibleRole) ? null : responsibleRole.Trim();
        item.EscalateToRole = string.IsNullOrWhiteSpace(escalateToRole) ? null : escalateToRole.Trim();
        item.EscalationWindow = string.IsNullOrWhiteSpace(escalationWindow) ? null : escalationWindow.Trim();
        await _db.SaveChangesAsync();
        Message = "Task updated.";
        return RedirectToPage(new { id = taskListId });
    }

    public async Task<IActionResult> OnPostDeleteItemAsync(int id, int taskListId)
    {
        var item = await _db.TaskItems.FindAsync(id);
        if (item is not null)
        {
            _db.TaskItems.Remove(item);
            await _db.SaveChangesAsync();
            Message = "Task deleted.";
        }
        return RedirectToPage(new { id = taskListId });
    }

    public async Task<IActionResult> OnPostCreateCheckpointAsync(int taskItemId, int taskListId, string label, int sortOrder)
    {
        _db.TaskCheckpoints.Add(new TaskCheckpoint { TaskItemId = taskItemId, Label = label.Trim(), SortOrder = sortOrder });
        await _db.SaveChangesAsync();
        Message = "Checkpoint added.";
        return RedirectToPage(new { id = taskListId });
    }

    public async Task<IActionResult> OnPostDeleteCheckpointAsync(int id, int taskListId)
    {
        var cp = await _db.TaskCheckpoints.FindAsync(id);
        if (cp is not null)
        {
            _db.TaskCheckpoints.Remove(cp);
            await _db.SaveChangesAsync();
            Message = "Checkpoint deleted.";
        }
        return RedirectToPage(new { id = taskListId });
    }
}
