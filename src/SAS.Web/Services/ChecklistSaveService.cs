using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Services;

public class ChecklistSaveService
{
    private readonly AppDbContext _db;

    public ChecklistSaveService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<TaskResponse> SaveTaskResponseAsync(int submissionId, int taskItemId, string status, string? notes, string actor)
    {
        var response = await _db.TaskResponses
            .FirstOrDefaultAsync(r => r.ChecklistSubmissionId == submissionId && r.TaskItemId == taskItemId);

        if (response is null)
        {
            response = new TaskResponse
            {
                ChecklistSubmissionId = submissionId,
                TaskItemId = taskItemId
            };
            _db.TaskResponses.Add(response);
        }

        response.Status = status;
        response.Notes = notes;
        response.UpdatedAt = DateTime.UtcNow;
        response.AnsweredBy = string.IsNullOrWhiteSpace(actor) ? "Unknown" : actor;

        await TouchSubmissionAsync(submissionId, actor);
        await _db.SaveChangesAsync();
        return response;
    }

    public async Task<CheckpointResponse> SaveCheckpointResponseAsync(int submissionId, int taskItemId, int checkpointId, string status, string? notes, string actor)
    {
        var response = await _db.TaskResponses
            .Include(r => r.CheckpointResponses)
            .FirstOrDefaultAsync(r => r.ChecklistSubmissionId == submissionId && r.TaskItemId == taskItemId);

        if (response is null)
        {
            response = new TaskResponse
            {
                ChecklistSubmissionId = submissionId,
                TaskItemId = taskItemId
            };
            _db.TaskResponses.Add(response);
            await _db.SaveChangesAsync();
        }

        if (notes is not null)
        {
            response.Notes = notes;
        }
        response.UpdatedAt = DateTime.UtcNow;
        response.AnsweredBy = string.IsNullOrWhiteSpace(actor) ? "Unknown" : actor;

        var cp = response.CheckpointResponses.FirstOrDefault(c => c.TaskCheckpointId == checkpointId);
        if (cp is null)
        {
            cp = new CheckpointResponse
            {
                TaskResponseId = response.Id,
                TaskCheckpointId = checkpointId
            };
            _db.CheckpointResponses.Add(cp);
        }

        cp.Status = status;
        cp.Ticked = true;
        cp.TickedAt = DateTime.UtcNow;

        await TouchSubmissionAsync(submissionId, actor);
        await _db.SaveChangesAsync();
        return cp;
    }

    public async Task SaveNotesAsync(int submissionId, int taskItemId, string? notes, string actor)
    {
        var response = await _db.TaskResponses
            .FirstOrDefaultAsync(r => r.ChecklistSubmissionId == submissionId && r.TaskItemId == taskItemId);

        if (response is null)
        {
            response = new TaskResponse { ChecklistSubmissionId = submissionId, TaskItemId = taskItemId };
            _db.TaskResponses.Add(response);
        }

        response.Notes = notes;
        response.UpdatedAt = DateTime.UtcNow;
        response.AnsweredBy = string.IsNullOrWhiteSpace(actor) ? "Unknown" : actor;

        await TouchSubmissionAsync(submissionId, actor);
        await _db.SaveChangesAsync();
    }

    public async Task<bool> SaveMetaAsync(int submissionId, string? auditorNames, string? location, string actor)
    {
        var submission = await _db.ChecklistSubmissions.FindAsync(submissionId);
        if (submission is null) return false;

        submission.AuditorNames = auditorNames;
        submission.Location = location;
        submission.LastEditedAt = DateTime.UtcNow;
        submission.LastEditedBy = string.IsNullOrWhiteSpace(actor) ? "Unknown" : actor;
        await _db.SaveChangesAsync();
        return true;
    }

    private async Task TouchSubmissionAsync(int submissionId, string actor)
    {
        var submission = await _db.ChecklistSubmissions.FindAsync(submissionId);
        if (submission is null) return;
        submission.LastEditedAt = DateTime.UtcNow;
        submission.LastEditedBy = string.IsNullOrWhiteSpace(actor) ? "Unknown" : actor;
    }
}
