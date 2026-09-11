using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Services;

public class HistoryRow
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

public class HistoryFilter
{
    public int? DepartmentId { get; set; }
    public int? AreaId { get; set; }
    public int? ShiftId { get; set; }
    public DateOnly? DateFrom { get; set; }
    public DateOnly? DateTo { get; set; }
}

public class HistoryListService
{
    private readonly AppDbContext _db;

    public HistoryListService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<List<HistoryRow>> GetRowsAsync(HistoryFilter filter)
    {
        var query = _db.ChecklistSubmissions
            .Include(s => s.Area).ThenInclude(a => a!.Department)
            .Include(s => s.Shift)
            .Include(s => s.TaskList).ThenInclude(l => l!.TaskItems).ThenInclude(i => i.Checkpoints)
            .Include(s => s.TaskResponses).ThenInclude(r => r.CheckpointResponses)
            .AsQueryable();

        if (filter.AreaId.HasValue) query = query.Where(s => s.AreaId == filter.AreaId.Value);
        if (filter.ShiftId.HasValue) query = query.Where(s => s.ShiftId == filter.ShiftId.Value);
        if (filter.DepartmentId.HasValue) query = query.Where(s => s.Area!.DepartmentId == filter.DepartmentId.Value);
        if (filter.DateFrom.HasValue) query = query.Where(s => s.ChecklistDate >= filter.DateFrom.Value);
        if (filter.DateTo.HasValue) query = query.Where(s => s.ChecklistDate <= filter.DateTo.Value);

        var submissions = await query.OrderByDescending(s => s.ChecklistDate).ThenBy(s => s.Area!.Name).ToListAsync();

        return submissions.Select(s =>
        {
            var items = s.TaskList!.TaskItems.ToList();
            var (answered, total) = ChecklistProgress.ComputeProgress(items, s);
            var issues = ChecklistProgress.CountIssues(items, s);
            return new HistoryRow
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
                Total = total,
                Issues = issues,
                CompletedBy = s.CompletedBy
            };
        }).ToList();
    }
}
