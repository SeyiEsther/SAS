using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Services;

namespace SAS.Web.Controllers;

[ApiController]
[Route("api/checklist/pdf")]
public class PdfController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly PdfExportService _pdf;

    public PdfController(AppDbContext db, PdfExportService pdf)
    {
        _db = db;
        _pdf = pdf;
    }

    [HttpGet]
    public async Task<IActionResult> Get(int areaId, int shiftId, string date)
    {
        if (!DateOnly.TryParse(date, out var checklistDate)) return BadRequest("Invalid date.");

        var area = await _db.Areas.Include(a => a.Department).FirstOrDefaultAsync(a => a.Id == areaId);
        var shift = await _db.Shifts.FirstOrDefaultAsync(s => s.Id == shiftId);
        if (area is null || shift is null) return NotFound();

        var submission = await _db.ChecklistSubmissions
            .Include(s => s.TaskResponses).ThenInclude(r => r.CheckpointResponses)
            .FirstOrDefaultAsync(s => s.AreaId == areaId && s.ShiftId == shiftId && s.ChecklistDate == checklistDate);
        if (submission is null) return NotFound();

        var taskList = await _db.TaskLists
            .Include(l => l.TaskItems.OrderBy(i => i.SortOrder)).ThenInclude(i => i.Checkpoints.OrderBy(c => c.SortOrder))
            .FirstOrDefaultAsync(l => l.Id == submission.TaskListId);
        if (taskList is null) return NotFound();

        var bytes = _pdf.Export(submission, taskList, taskList.TaskItems.ToList(), area, shift, area.Department!);
        var fileName = $"SafeStart_{area.Department!.Name}_{area.Name}_{shift.Name}_{checklistDate:yyyy-MM-dd}.pdf".Replace(" ", "_");
        return File(bytes, "application/pdf", fileName);
    }
}
