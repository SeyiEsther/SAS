namespace SAS.Web.Models;

public class CheckpointResponse
{
    public int Id { get; set; }
    public int TaskResponseId { get; set; }
    public TaskResponse? TaskResponse { get; set; }
    public int TaskCheckpointId { get; set; }
    public TaskCheckpoint? TaskCheckpoint { get; set; }
    public bool Ticked { get; set; }
    public DateTime? TickedAt { get; set; }
    public string? Status { get; set; }
}
