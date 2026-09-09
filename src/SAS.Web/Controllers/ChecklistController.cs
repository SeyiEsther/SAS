using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;
using SAS.Web.Services;

namespace SAS.Web.Controllers;

/// <summary>
/// The save/complete API consumed by the checklist entry page's JS. Kept
/// separate from the Razor Page (which only ever does the initial GET
/// render) so every write path lives in one small, testable surface — the
/// same split TL uses between its Pages and its Controllers.
/// </summary>
[ApiController]
[Route("api/checklist")]
[AutoValidateAntiforgeryToken]
public class ChecklistController : ControllerBase
{
    private readonly ChecklistSaveService _save;
    private readonly ChecklistCompletionService _completion;
    private readonly AccessService _access;
    private readonly AppDbContext _db;

    public ChecklistController(ChecklistSaveService save, ChecklistCompletionService completion, AccessService access, AppDbContext db)
    {
        _save = save;
        _completion = completion;
        _access = access;
        _db = db;
    }

    /// <summary>
    /// The audit assigns some checks to the HOD (ResponsibleRole = "HOD").
    /// Those can only be answered by an HOD — enforced here, not just hidden
    /// in the UI.
    /// </summary>
    private async Task<IActionResult?> DenyIfNotAllowedAsync(int itemId)
    {
        var item = await _db.TaskItems.AsNoTracking().FirstOrDefaultAsync(i => i.Id == itemId);
        if (item is null) return NotFound(new { error = "Check not found." });

        if (!await _access.CanAnswerAsync(item))
        {
            return StatusCode(StatusCodes.Status403Forbidden,
                new { error = "This check is the HOD's to answer. Ask an HOD to complete it." });
        }
        return null;
    }

    /// <summary>Whoever is signed in gets stamped on the answer — not a name typed into a box.</summary>
    private string Actor(string? supplied) =>
        string.IsNullOrWhiteSpace(_access.CurrentUser.Label) ? (supplied ?? "Unknown") : _access.CurrentUser.Label;

    public record SaveTaskRequest(int SubmissionId, int ItemId, string Status, string? Notes, string? Actor);

    [HttpPost("save-task")]
    public async Task<IActionResult> SaveTask([FromBody] SaveTaskRequest req)
    {
        if (req.Status != ResponseStatus.Done && req.Status != ResponseStatus.Issue)
        {
            return BadRequest(new { error = "Invalid status." });
        }
        if (req.Status == ResponseStatus.Issue && string.IsNullOrWhiteSpace(req.Notes))
        {
            return BadRequest(new { error = "Notes are required for an Issue." });
        }

        var denied = await DenyIfNotAllowedAsync(req.ItemId);
        if (denied is not null) return denied;

        await _save.SaveTaskResponseAsync(req.SubmissionId, req.ItemId, req.Status, req.Notes, Actor(req.Actor));
        return Ok(new { ok = true });
    }

    public record SaveCheckpointRequest(int SubmissionId, int ItemId, int CheckpointId, string Status, string? Notes, string? Actor);

    [HttpPost("save-checkpoint")]
    public async Task<IActionResult> SaveCheckpoint([FromBody] SaveCheckpointRequest req)
    {
        if (req.Status != ResponseStatus.Done && req.Status != ResponseStatus.Issue)
        {
            return BadRequest(new { error = "Invalid status." });
        }

        var denied = await DenyIfNotAllowedAsync(req.ItemId);
        if (denied is not null) return denied;

        await _save.SaveCheckpointResponseAsync(req.SubmissionId, req.ItemId, req.CheckpointId, req.Status, req.Notes, Actor(req.Actor));
        return Ok(new { ok = true });
    }

    public record SaveNotesRequest(int SubmissionId, int ItemId, string? Notes, string? Actor);

    [HttpPost("save-notes")]
    public async Task<IActionResult> SaveNotes([FromBody] SaveNotesRequest req)
    {
        var denied = await DenyIfNotAllowedAsync(req.ItemId);
        if (denied is not null) return denied;

        await _save.SaveNotesAsync(req.SubmissionId, req.ItemId, req.Notes, Actor(req.Actor));
        return Ok(new { ok = true });
    }

    public record SaveMetaRequest(int SubmissionId, string? AuditorNames, string? Location, string? Actor);

    [HttpPost("save-meta")]
    public async Task<IActionResult> SaveMeta([FromBody] SaveMetaRequest req)
    {
        var ok = await _save.SaveMetaAsync(req.SubmissionId, req.AuditorNames, req.Location, Actor(req.Actor));
        return ok ? Ok(new { ok = true }) : NotFound();
    }

    public record CompleteRequest(int SubmissionId, string? CompletedBy);

    [HttpPost("complete")]
    public async Task<IActionResult> Complete([FromBody] CompleteRequest req)
    {
        if (!await _access.CanSignOffAsync())
        {
            return StatusCode(StatusCodes.Status403Forbidden,
                new { error = "Only an HOD can sign a checklist off." });
        }

        var result = await _completion.CompleteAsync(req.SubmissionId, req.CompletedBy ?? Actor(null));
        if (!result.Success)
        {
            return BadRequest(new { error = result.Error });
        }
        return Ok(new { ok = true });
    }
}
