using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Pages;

public class IndexModel : PageModel
{
    private readonly AppDbContext _db;

    public IndexModel(AppDbContext db)
    {
        _db = db;
    }

    public List<Area> Areas { get; set; } = new();
    public List<Shift> Shifts { get; set; } = new();

    [BindProperty]
    public string? ChecklistDate { get; set; }
    [BindProperty]
    public int? AreaId { get; set; }
    [BindProperty]
    public int? ShiftId { get; set; }

    public string? Error { get; set; }

    public async Task OnGetAsync()
    {
        ChecklistDate ??= DateOnly.FromDateTime(DateTime.Now).ToString("yyyy-MM-dd");
        await LoadListsAsync();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        await LoadListsAsync();

        if (!AreaId.HasValue || !ShiftId.HasValue || string.IsNullOrWhiteSpace(ChecklistDate))
        {
            Error = "Pick a date, area and shift to start.";
            return Page();
        }

        var area = Areas.FirstOrDefault(a => a.Id == AreaId.Value);
        var shift = Shifts.FirstOrDefault(s => s.Id == ShiftId.Value);
        if (area is null || shift is null)
        {
            Error = "That area or shift is no longer available.";
            return Page();
        }
        if (area.DepartmentId != shift.DepartmentId)
        {
            Error = $"\"{shift.Name}\" is not a shift in {area.Department!.Name}. Pick a shift from the same department as the area.";
            return Page();
        }

        return Redirect($"/Checklist?areaId={AreaId}&shiftId={ShiftId}&date={ChecklistDate}");
    }

    private async Task LoadListsAsync()
    {
        Areas = await _db.Areas
            .Include(a => a.Department)
            .Where(a => a.IsActive && a.Department!.IsActive)
            .OrderBy(a => a.Department!.SortOrder).ThenBy(a => a.SortOrder)
            .ToListAsync();

        Shifts = await _db.Shifts
            .Include(s => s.Department)
            .Where(s => s.IsActive && s.Department!.IsActive)
            .OrderBy(s => s.Department!.SortOrder).ThenBy(s => s.SortOrder)
            .ToListAsync();
    }
}
