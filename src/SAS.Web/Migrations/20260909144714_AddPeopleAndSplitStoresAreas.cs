using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SAS.Web.Migrations
{
    /// <inheritdoc />
    public partial class AddPeopleAndSplitStoresAreas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "People",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    DisplayName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Username = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    Role = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    DepartmentId = table.Column<int>(type: "int", nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_People", x => x.Id);
                    table.ForeignKey(
                        name: "FK_People_Departments_DepartmentId",
                        column: x => x.DepartmentId,
                        principalTable: "Departments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_People_DepartmentId",
                table: "People",
                column: "DepartmentId");

            migrationBuilder.CreateIndex(
                name: "IX_People_Role_DisplayName",
                table: "People",
                columns: new[] { "Role", "DisplayName" },
                unique: true);

            // ---------------------------------------------------------------
            // Split Stores' combined "DP1 & DP3" area into two real areas, and
            // seed the HOD list that drives sign-off and HOD-only checks.
            //
            // Existing rows are updated by their stable identifying fields
            // (department name + area name, role + display name) — never an
            // insert-only-if-missing that leaves already-present rows stale.
            // ---------------------------------------------------------------
            migrationBuilder.Sql(@"
SET NOCOUNT ON;

DECLARE @StoresId INT = (SELECT Id FROM Departments WHERE Name = N'Stores');

IF @StoresId IS NOT NULL
BEGIN
    -- 1) The combined area becomes DP1 (identified by its current name).
    UPDATE Areas
       SET Name = N'DP1', DefaultLocation = N'DP1', SortOrder = 1
     WHERE DepartmentId = @StoresId AND Name = N'DP1 & DP3';

    -- Consumables moves down so DP3 can sit alongside DP1.
    UPDATE Areas SET SortOrder = 3
     WHERE DepartmentId = @StoresId AND Name = N'Consumables';

    DECLARE @Dp1 INT = (SELECT Id FROM Areas WHERE DepartmentId = @StoresId AND Name = N'DP1');

    -- 2) DP3 as an area in its own right.
    IF NOT EXISTS (SELECT 1 FROM Areas WHERE DepartmentId = @StoresId AND Name = N'DP3')
        INSERT INTO Areas (DepartmentId, Name, DefaultLocation, SortOrder, IsActive)
        VALUES (@StoresId, N'DP3', N'DP3', 2, 1);
    ELSE
        UPDATE Areas SET DefaultLocation = N'DP3', SortOrder = 2, IsActive = 1
         WHERE DepartmentId = @StoresId AND Name = N'DP3';

    DECLARE @Dp3 INT = (SELECT Id FROM Areas WHERE DepartmentId = @StoresId AND Name = N'DP3');

    -- 3) DP3 starts with a copy of DP1's task lists, so both areas run the
    --    same Safe Start tasks until an admin edits one of them.
    IF @Dp1 IS NOT NULL AND @Dp3 IS NOT NULL
    BEGIN
        INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy)
        SELECT @Dp3, tl.ShiftId, tl.Version, tl.IsCurrent, tl.HealthRepsReminder, SYSUTCDATETIME(), N'Split DP1/DP3'
          FROM TaskLists tl
         WHERE tl.AreaId = @Dp1
           AND NOT EXISTS (SELECT 1 FROM TaskLists x WHERE x.AreaId = @Dp3 AND x.ShiftId = tl.ShiftId);

        INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow)
        SELECT newtl.Id, ti.Text, ti.SortOrder, ti.IsTimeBoxed, ti.Category, ti.Cadence, ti.ResponsibleRole, ti.EscalateToRole, ti.EscalationWindow
          FROM TaskItems ti
          JOIN TaskLists oldtl ON oldtl.Id = ti.TaskListId AND oldtl.AreaId = @Dp1
          JOIN TaskLists newtl ON newtl.AreaId = @Dp3 AND newtl.ShiftId = oldtl.ShiftId
         WHERE NOT EXISTS (SELECT 1 FROM TaskItems x WHERE x.TaskListId = newtl.Id AND x.SortOrder = ti.SortOrder);

        INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder)
        SELECT newti.Id, tc.Label, tc.SortOrder
          FROM TaskCheckpoints tc
          JOIN TaskItems oldti ON oldti.Id = tc.TaskItemId
          JOIN TaskLists oldtl ON oldtl.Id = oldti.TaskListId AND oldtl.AreaId = @Dp1
          JOIN TaskLists newtl ON newtl.AreaId = @Dp3 AND newtl.ShiftId = oldtl.ShiftId
          JOIN TaskItems newti ON newti.TaskListId = newtl.Id AND newti.SortOrder = oldti.SortOrder
         WHERE NOT EXISTS (SELECT 1 FROM TaskCheckpoints x WHERE x.TaskItemId = newti.Id AND x.SortOrder = tc.SortOrder);
    END
END
");

            // Heads of Department — these drive sign-off and the HOD-only
            // checks in the Dispatch audit. Upserted by (Role, DisplayName).
            migrationBuilder.Sql(@"
SET NOCOUNT ON;

DECLARE @Hods TABLE (DisplayName NVARCHAR(200), SortOrder INT);
INSERT INTO @Hods (DisplayName, SortOrder) VALUES
    (N'George Thompson', 1),
    (N'Lukasz Jaworski', 2),
    (N'Alison Gilley', 3),
    (N'Piotr Pelka', 4),
    (N'Michael Tregillis', 5);

UPDATE p
   SET p.SortOrder = h.SortOrder, p.IsActive = 1
  FROM People p
  JOIN @Hods h ON h.DisplayName = p.DisplayName
 WHERE p.Role = N'HOD';

INSERT INTO People (DisplayName, Username, Role, DepartmentId, SortOrder, IsActive)
SELECT h.DisplayName, NULL, N'HOD', NULL, h.SortOrder, 1
  FROM @Hods h
 WHERE NOT EXISTS (SELECT 1 FROM People p WHERE p.Role = N'HOD' AND p.DisplayName = h.DisplayName);
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Undo the split: drop DP3's copied task lists, then fold the area
            // name back to the combined one. Submissions recorded against DP3
            // block the rollback rather than being silently deleted.
            migrationBuilder.Sql(@"
SET NOCOUNT ON;

DECLARE @StoresId INT = (SELECT Id FROM Departments WHERE Name = N'Stores');
DECLARE @Dp3 INT = (SELECT Id FROM Areas WHERE DepartmentId = @StoresId AND Name = N'DP3');

IF @Dp3 IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM ChecklistSubmissions WHERE AreaId = @Dp3)
        THROW 50001, 'Cannot roll back: checklists have already been completed against DP3.', 1;

    DELETE tc FROM TaskCheckpoints tc
      JOIN TaskItems ti ON ti.Id = tc.TaskItemId
      JOIN TaskLists tl ON tl.Id = ti.TaskListId
     WHERE tl.AreaId = @Dp3;

    DELETE ti FROM TaskItems ti
      JOIN TaskLists tl ON tl.Id = ti.TaskListId
     WHERE tl.AreaId = @Dp3;

    DELETE FROM TaskLists WHERE AreaId = @Dp3;
    DELETE FROM Areas WHERE Id = @Dp3;
END

UPDATE Areas SET Name = N'DP1 & DP3', DefaultLocation = N'DP1 & DP3'
 WHERE DepartmentId = @StoresId AND Name = N'DP1';

UPDATE Areas SET SortOrder = 2 WHERE DepartmentId = @StoresId AND Name = N'Consumables';
");

            migrationBuilder.DropTable(
                name: "People");
        }
    }
}
