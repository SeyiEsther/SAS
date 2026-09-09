using Microsoft.AspNetCore.Mvc;
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

    public ChecklistController(ChecklistSaveService save, ChecklistCompletionService completion)
    {
        _save = save;
        _completion = completion;
    }

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

        await _save.SaveTaskResponseAsync(req.SubmissionId, req.ItemId, req.Status, req.Notes, req.Actor ?? "Unknown");
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

        await _save.SaveCheckpointResponseAsync(req.SubmissionId, req.ItemId, req.CheckpointId, req.Status, req.Notes, req.Actor ?? "Unknown");
        return Ok(new { ok = true });
    }

    public record SaveNotesRequest(int SubmissionId, int ItemId, string? Notes, string? Actor);

    [HttpPost("save-notes")]
    public async Task<IActionResult> SaveNotes([FromBody] SaveNotesRequest req)
    {
        await _save.SaveNotesAsync(req.SubmissionId, req.ItemId, req.Notes, req.Actor ?? "Unknown");
        return Ok(new { ok = true });
    }

    public record SaveMetaRequest(int SubmissionId, string? AuditorNames, string? Location, string? Actor);

    [HttpPost("save-meta")]
    public async Task<IActionResult> SaveMeta([FromBody] SaveMetaRequest req)
    {
        var ok = await _save.SaveMetaAsync(req.SubmissionId, req.AuditorNames, req.Location, req.Actor ?? "Unknown");
        return ok ? Ok(new { ok = true }) : NotFound();
    }

    public record CompleteRequest(int SubmissionId, string? CompletedBy);

    [HttpPost("complete")]
    public async Task<IActionResult> Complete([FromBody] CompleteRequest req)
    {
        var result = await _completion.CompleteAsync(req.SubmissionId, req.CompletedBy ?? "Unknown");
        if (!result.Success)
        {
            return BadRequest(new { error = result.Error });
        }
        return Ok(new { ok = true });
    }
}
