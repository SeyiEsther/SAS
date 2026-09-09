using Microsoft.EntityFrameworkCore;
using SAS.Web.Models;

namespace SAS.Web.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Department> Departments => Set<Department>();
    public DbSet<Area> Areas => Set<Area>();
    public DbSet<Shift> Shifts => Set<Shift>();
    public DbSet<TaskList> TaskLists => Set<TaskList>();
    public DbSet<TaskItem> TaskItems => Set<TaskItem>();
    public DbSet<TaskCheckpoint> TaskCheckpoints => Set<TaskCheckpoint>();
    public DbSet<ChecklistSubmission> ChecklistSubmissions => Set<ChecklistSubmission>();
    public DbSet<TaskResponse> TaskResponses => Set<TaskResponse>();
    public DbSet<CheckpointResponse> CheckpointResponses => Set<CheckpointResponse>();
    public DbSet<Person> People => Set<Person>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Department>(e =>
        {
            e.Property(x => x.Name).IsRequired().HasMaxLength(200);
            e.HasIndex(x => x.Name).IsUnique();
        });

        modelBuilder.Entity<Area>(e =>
        {
            e.Property(x => x.Name).IsRequired().HasMaxLength(200);
            e.Property(x => x.DefaultLocation).HasMaxLength(200);
            e.HasIndex(x => new { x.DepartmentId, x.Name }).IsUnique();
            e.HasOne(x => x.Department)
                .WithMany(d => d.Areas)
                .HasForeignKey(x => x.DepartmentId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Shift>(e =>
        {
            e.Property(x => x.Name).IsRequired().HasMaxLength(200);
            e.HasIndex(x => new { x.DepartmentId, x.Name }).IsUnique();
            e.HasOne(x => x.Department)
                .WithMany(d => d.Shifts)
                .HasForeignKey(x => x.DepartmentId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<TaskList>(e =>
        {
            e.Property(x => x.HealthRepsReminder).HasColumnType("nvarchar(max)");
            e.Property(x => x.CreatedBy).IsRequired().HasMaxLength(200);
            e.HasOne(x => x.Area)
                .WithMany(a => a.TaskLists)
                .HasForeignKey(x => x.AreaId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Shift)
                .WithMany(s => s.TaskLists)
                .HasForeignKey(x => x.ShiftId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => new { x.AreaId, x.ShiftId, x.IsCurrent });
        });

        modelBuilder.Entity<TaskItem>(e =>
        {
            e.Property(x => x.Text).IsRequired().HasColumnType("nvarchar(max)");
            e.Property(x => x.Category).HasMaxLength(100);
            e.Property(x => x.Cadence).HasMaxLength(100);
            e.Property(x => x.ResponsibleRole).HasMaxLength(200);
            e.Property(x => x.EscalateToRole).HasMaxLength(200);
            e.Property(x => x.EscalationWindow).HasMaxLength(100);
            e.HasOne(x => x.TaskList)
                .WithMany(l => l.TaskItems)
                .HasForeignKey(x => x.TaskListId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => new { x.TaskListId, x.SortOrder });
        });

        modelBuilder.Entity<TaskCheckpoint>(e =>
        {
            e.Property(x => x.Label).IsRequired().HasMaxLength(200);
            e.HasOne(x => x.TaskItem)
                .WithMany(t => t.Checkpoints)
                .HasForeignKey(x => x.TaskItemId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => new { x.TaskItemId, x.SortOrder });
        });

        modelBuilder.Entity<ChecklistSubmission>(e =>
        {
            e.Property(x => x.AuditorNames).HasColumnType("nvarchar(max)");
            e.Property(x => x.Location).HasMaxLength(200);
            e.Property(x => x.CreatedBy).IsRequired().HasMaxLength(200);
            e.Property(x => x.LastEditedBy).HasMaxLength(200);
            e.Property(x => x.CompletedBy).HasMaxLength(200);
            e.HasOne(x => x.Area)
                .WithMany()
                .HasForeignKey(x => x.AreaId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Shift)
                .WithMany()
                .HasForeignKey(x => x.ShiftId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.TaskList)
                .WithMany()
                .HasForeignKey(x => x.TaskListId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => new { x.AreaId, x.ShiftId, x.ChecklistDate }).IsUnique();
        });

        modelBuilder.Entity<TaskResponse>(e =>
        {
            e.Property(x => x.Status).HasMaxLength(20);
            e.Property(x => x.Notes).HasColumnType("nvarchar(max)");
            e.Property(x => x.AnsweredBy).HasMaxLength(200);
            e.HasOne(x => x.ChecklistSubmission)
                .WithMany(c => c.TaskResponses)
                .HasForeignKey(x => x.ChecklistSubmissionId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.TaskItem)
                .WithMany()
                .HasForeignKey(x => x.TaskItemId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => new { x.ChecklistSubmissionId, x.TaskItemId }).IsUnique();
        });

        modelBuilder.Entity<Person>(e =>
        {
            e.Property(x => x.DisplayName).IsRequired().HasMaxLength(200);
            e.Property(x => x.Username).HasMaxLength(200);
            e.Property(x => x.Role).IsRequired().HasMaxLength(50);
            e.HasOne(x => x.Department)
                .WithMany()
                .HasForeignKey(x => x.DepartmentId)
                .OnDelete(DeleteBehavior.SetNull);
            e.HasIndex(x => new { x.Role, x.DisplayName }).IsUnique();
        });

        modelBuilder.Entity<CheckpointResponse>(e =>
        {
            e.Property(x => x.Status).HasMaxLength(20);
            e.HasOne(x => x.TaskResponse)
                .WithMany(r => r.CheckpointResponses)
                .HasForeignKey(x => x.TaskResponseId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.TaskCheckpoint)
                .WithMany()
                .HasForeignKey(x => x.TaskCheckpointId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => new { x.TaskResponseId, x.TaskCheckpointId }).IsUnique();
        });
    }
}
