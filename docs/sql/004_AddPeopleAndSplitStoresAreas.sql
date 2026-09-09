BEGIN TRANSACTION;
GO

CREATE TABLE [People] (
    [Id] int NOT NULL IDENTITY,
    [DisplayName] nvarchar(200) NOT NULL,
    [Username] nvarchar(200) NULL,
    [Role] nvarchar(50) NOT NULL,
    [DepartmentId] int NULL,
    [SortOrder] int NOT NULL,
    [IsActive] bit NOT NULL,
    CONSTRAINT [PK_People] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_People_Departments_DepartmentId] FOREIGN KEY ([DepartmentId]) REFERENCES [Departments] ([Id]) ON DELETE SET NULL
);
GO

CREATE INDEX [IX_People_DepartmentId] ON [People] ([DepartmentId]);
GO

CREATE UNIQUE INDEX [IX_People_Role_DisplayName] ON [People] ([Role], [DisplayName]);
GO


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

GO


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

GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260909144714_AddPeopleAndSplitStoresAreas', N'8.0.10');
GO

COMMIT;
GO

