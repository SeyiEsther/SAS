using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Pages;

public class CompletedModel : PageModel
{
    private readonly AppDbContext _db;

    public CompletedModel(AppDbContext db)
    {
        _db = db;
    }

    public List<Department> Departments { get; set; } = new();
    public List<Area> Areas { get; set; } = new();
    public List<Shift> Shifts { get; set; } = new();

    public List<RowVm> Rows { get; set; } = new();

    public int? DepartmentId { get; set; }
    public int? AreaId { get; set; }
    public int? ShiftId { get; set; }
    public string? DateFrom { get; set; }
    public string? DateTo { get; set; }

    public class RowVm
    {
        public int SubmissionId { get; set; }
        public int AreaId { get; set; }
        public int ShiftId { get; set; }
        public string Department { get; set; } = string.Empty;
        public string Area { get; set; } = string.Empty;
        public string Shift { get; set; } = string.Empty;
        public DateOnly Date { get; set; }
        public bool Completed { get; set; }
        public int Answered { get; set; }
        public int Total { get; set; }
        public int Issues { get; set; }
        public string? CompletedBy { get; set; }
    }

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

        var query = _db.ChecklistSubmissions
            .Include(s => s.Area).ThenInclude(a => a!.Department)
            .Include(s => s.Shift)
            .Include(s => s.TaskList).ThenInclude(l => l!.TaskItems).ThenInclude(i => i.Checkpoints)
            .Include(s => s.TaskResponses).ThenInclude(r => r.CheckpointResponses)
            .AsQueryable();

        if (areaId.HasValue) query = query.Where(s => s.AreaId == areaId.Value);
        if (shiftId.HasValue) query = query.Where(s => s.ShiftId == shiftId.Value);
        if (departmentId.HasValue) query = query.Where(s => s.Area!.DepartmentId == departmentId.Value);

        if (DateOnly.TryParse(dateFrom, out var from)) query = query.Where(s => s.ChecklistDate >= from);
        if (DateOnly.TryParse(dateTo, out var to)) query = query.Where(s => s.ChecklistDate <= to);

        var submissions = await query.OrderByDescending(s => s.ChecklistDate).ThenBy(s => s.Area!.Name).ToListAsync();

        Rows = submissions.Select(s =>
        {
            var items = s.TaskList!.TaskItems.ToList();
            var (answered, totalCount) = ChecklistService.ComputeProgress(items, s);
            var issues = ChecklistService.CountIssues(items, s);
            return new RowVm
            {
                SubmissionId = s.Id,
                AreaId = s.AreaId,
                ShiftId = s.ShiftId,
                Department = s.Area!.Department!.Name,
                Area = s.Area!.Name,
                Shift = s.Shift!.Name,
                Date = s.ChecklistDate,
                Completed = s.CompletedAt.HasValue,
                Answered = answered,
                Total = totalCount,
                Issues = issues,
                CompletedBy = s.CompletedBy
            };
        }).ToList();
    }
}
