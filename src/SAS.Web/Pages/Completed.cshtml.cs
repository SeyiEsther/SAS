using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Pages;

public class CompletedModel : PageModel
{
    private readonly AppDbContext _db;
    private readonly HistoryListService _history;

    public CompletedModel(AppDbContext db, HistoryListService history)
    {
        _db = db;
        _history = history;
    }

    public List<Department> Departments { get; set; } = new();
    public List<Area> Areas { get; set; } = new();
    public List<Shift> Shifts { get; set; } = new();

    public List<HistoryRow> Rows { get; set; } = new();

    public int? DepartmentId { get; set; }
    public int? AreaId { get; set; }
    public int? ShiftId { get; set; }
    public string? DateFrom { get; set; }
    public string? DateTo { get; set; }

    public async Task OnGetAsync(int? departmentId, int? areaId, int? shiftId, string? dateFrom, string? dateTo)
    {
        DepartmentId = departmentId;
        AreaId = areaId;
        ShiftId = shiftId;
        DateFrom = dateFrom;
        DateTo = dateTo;

        Departments = await _db.Departments.OrderBy(d => d.SortOrder).ToListAsync();
        Areas = await _db.Areas.OrderBy(a => a.SortOrder).ToListAsync();
        Shifts = await _db.Shifts.OrderBy(s => s.SortOrder).ToListAsync();

        var filter = new HistoryFilter
        {
            DepartmentId = departmentId,
            AreaId = areaId,
            ShiftId = shiftId,
            DateFrom = DateOnly.TryParse(dateFrom, out var from) ? from : null,
            DateTo = DateOnly.TryParse(dateTo, out var to) ? to : null
        };

        Rows = await _history.GetRowsAsync(filter);
    }
}
