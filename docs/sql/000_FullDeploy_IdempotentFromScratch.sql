IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE TABLE [Departments] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(200) NOT NULL,
        [SortOrder] int NOT NULL,
        [IsActive] bit NOT NULL,
        CONSTRAINT [PK_Departments] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE TABLE [Areas] (
        [Id] int NOT NULL IDENTITY,
        [DepartmentId] int NOT NULL,
        [Name] nvarchar(200) NOT NULL,
        [DefaultLocation] nvarchar(200) NULL,
        [SortOrder] int NOT NULL,
        [IsActive] bit NOT NULL,
        CONSTRAINT [PK_Areas] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Areas_Departments_DepartmentId] FOREIGN KEY ([DepartmentId]) REFERENCES [Departments] ([Id]) ON DELETE NO ACTION
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE TABLE [Shifts] (
        [Id] int NOT NULL IDENTITY,
        [DepartmentId] int NOT NULL,
        [Name] nvarchar(200) NOT NULL,
        [SortOrder] int NOT NULL,
        [IsActive] bit NOT NULL,
        CONSTRAINT [PK_Shifts] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Shifts_Departments_DepartmentId] FOREIGN KEY ([DepartmentId]) REFERENCES [Departments] ([Id]) ON DELETE NO ACTION
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE TABLE [TaskLists] (
        [Id] int NOT NULL IDENTITY,
        [AreaId] int NOT NULL,
        [ShiftId] int NOT NULL,
        [Version] int NOT NULL,
        [IsCurrent] bit NOT NULL,
        [HealthRepsReminder] nvarchar(max) NULL,
        [CreatedAt] datetime2 NOT NULL,
        [CreatedBy] nvarchar(200) NOT NULL,
        CONSTRAINT [PK_TaskLists] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_TaskLists_Areas_AreaId] FOREIGN KEY ([AreaId]) REFERENCES [Areas] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_TaskLists_Shifts_ShiftId] FOREIGN KEY ([ShiftId]) REFERENCES [Shifts] ([Id]) ON DELETE NO ACTION
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE TABLE [ChecklistSubmissions] (
        [Id] int NOT NULL IDENTITY,
        [AreaId] int NOT NULL,
        [ShiftId] int NOT NULL,
        [TaskListId] int NOT NULL,
        [ChecklistDate] date NOT NULL,
        [AuditorNames] nvarchar(max) NULL,
        [Location] nvarchar(200) NULL,
        [CreatedAt] datetime2 NOT NULL,
        [CreatedBy] nvarchar(200) NOT NULL,
        [LastEditedAt] datetime2 NULL,
        [LastEditedBy] nvarchar(200) NULL,
        [CompletedAt] datetime2 NULL,
        [CompletedBy] nvarchar(200) NULL,
        CONSTRAINT [PK_ChecklistSubmissions] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_ChecklistSubmissions_Areas_AreaId] FOREIGN KEY ([AreaId]) REFERENCES [Areas] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_ChecklistSubmissions_Shifts_ShiftId] FOREIGN KEY ([ShiftId]) REFERENCES [Shifts] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_ChecklistSubmissions_TaskLists_TaskListId] FOREIGN KEY ([TaskListId]) REFERENCES [TaskLists] ([Id]) ON DELETE NO ACTION
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE TABLE [TaskItems] (
        [Id] int NOT NULL IDENTITY,
        [TaskListId] int NOT NULL,
        [Text] nvarchar(max) NOT NULL,
        [SortOrder] int NOT NULL,
        [IsTimeBoxed] bit NOT NULL,
        [Category] nvarchar(100) NULL,
        [Cadence] nvarchar(100) NULL,
        [ResponsibleRole] nvarchar(200) NULL,
        [EscalateToRole] nvarchar(200) NULL,
        [EscalationWindow] nvarchar(100) NULL,
        CONSTRAINT [PK_TaskItems] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_TaskItems_TaskLists_TaskListId] FOREIGN KEY ([TaskListId]) REFERENCES [TaskLists] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE TABLE [TaskCheckpoints] (
        [Id] int NOT NULL IDENTITY,
        [TaskItemId] int NOT NULL,
        [Label] nvarchar(200) NOT NULL,
        [SortOrder] int NOT NULL,
        CONSTRAINT [PK_TaskCheckpoints] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_TaskCheckpoints_TaskItems_TaskItemId] FOREIGN KEY ([TaskItemId]) REFERENCES [TaskItems] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE TABLE [TaskResponses] (
        [Id] int NOT NULL IDENTITY,
        [ChecklistSubmissionId] int NOT NULL,
        [TaskItemId] int NOT NULL,
        [Status] nvarchar(20) NULL,
        [Notes] nvarchar(max) NULL,
        [UpdatedAt] datetime2 NOT NULL,
        [AnsweredBy] nvarchar(200) NULL,
        CONSTRAINT [PK_TaskResponses] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_TaskResponses_ChecklistSubmissions_ChecklistSubmissionId] FOREIGN KEY ([ChecklistSubmissionId]) REFERENCES [ChecklistSubmissions] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_TaskResponses_TaskItems_TaskItemId] FOREIGN KEY ([TaskItemId]) REFERENCES [TaskItems] ([Id]) ON DELETE NO ACTION
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE TABLE [CheckpointResponses] (
        [Id] int NOT NULL IDENTITY,
        [TaskResponseId] int NOT NULL,
        [TaskCheckpointId] int NOT NULL,
        [Ticked] bit NOT NULL,
        [TickedAt] datetime2 NULL,
        [Status] nvarchar(20) NULL,
        CONSTRAINT [PK_CheckpointResponses] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CheckpointResponses_TaskCheckpoints_TaskCheckpointId] FOREIGN KEY ([TaskCheckpointId]) REFERENCES [TaskCheckpoints] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_CheckpointResponses_TaskResponses_TaskResponseId] FOREIGN KEY ([TaskResponseId]) REFERENCES [TaskResponses] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Areas_DepartmentId_Name] ON [Areas] ([DepartmentId], [Name]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_ChecklistSubmissions_AreaId_ShiftId_ChecklistDate] ON [ChecklistSubmissions] ([AreaId], [ShiftId], [ChecklistDate]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_ChecklistSubmissions_ShiftId] ON [ChecklistSubmissions] ([ShiftId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_ChecklistSubmissions_TaskListId] ON [ChecklistSubmissions] ([TaskListId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_CheckpointResponses_TaskCheckpointId] ON [CheckpointResponses] ([TaskCheckpointId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_CheckpointResponses_TaskResponseId_TaskCheckpointId] ON [CheckpointResponses] ([TaskResponseId], [TaskCheckpointId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Departments_Name] ON [Departments] ([Name]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Shifts_DepartmentId_Name] ON [Shifts] ([DepartmentId], [Name]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_TaskCheckpoints_TaskItemId_SortOrder] ON [TaskCheckpoints] ([TaskItemId], [SortOrder]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_TaskItems_TaskListId_SortOrder] ON [TaskItems] ([TaskListId], [SortOrder]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_TaskLists_AreaId_ShiftId_IsCurrent] ON [TaskLists] ([AreaId], [ShiftId], [IsCurrent]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_TaskLists_ShiftId] ON [TaskLists] ([ShiftId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_TaskResponses_ChecklistSubmissionId_TaskItemId] ON [TaskResponses] ([ChecklistSubmissionId], [TaskItemId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_TaskResponses_TaskItemId] ON [TaskResponses] ([TaskItemId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102620_InitialCreate'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260909102620_InitialCreate', N'8.0.10');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102920_SeedInitialData'
)
BEGIN

    SET NOCOUNT ON;

    -- ===================== Departments =====================
    DECLARE @StoresId INT, @DispatchId INT;
    INSERT INTO Departments (Name, SortOrder, IsActive) VALUES (N'Stores', 1, 1);
    SET @StoresId = SCOPE_IDENTITY();
    INSERT INTO Departments (Name, SortOrder, IsActive) VALUES (N'Dispatch', 2, 1);
    SET @DispatchId = SCOPE_IDENTITY();

    -- ===================== Areas =====================
    DECLARE @StoresMainAreaId INT, @ConsumablesAreaId INT, @WarehouseAreaId INT;
    INSERT INTO Areas (DepartmentId, Name, DefaultLocation, SortOrder, IsActive) VALUES (@StoresId, N'DP1 & DP3', N'DP1 & DP3', 1, 1);
    SET @StoresMainAreaId = SCOPE_IDENTITY();
    INSERT INTO Areas (DepartmentId, Name, DefaultLocation, SortOrder, IsActive) VALUES (@StoresId, N'Consumables', N'Consumables', 2, 1);
    SET @ConsumablesAreaId = SCOPE_IDENTITY();
    INSERT INTO Areas (DepartmentId, Name, DefaultLocation, SortOrder, IsActive) VALUES (@DispatchId, N'Warehouse', N'Warehouse', 1, 1);
    SET @WarehouseAreaId = SCOPE_IDENTITY();

    -- ===================== Shifts (each department owns its own rows) =====================
    DECLARE @Stores1 INT, @Stores2 INT, @Stores3 INT, @StoresC INT;
    INSERT INTO Shifts (DepartmentId, Name, SortOrder, IsActive) VALUES (@StoresId, N'1st Shift', 1, 1); SET @Stores1 = SCOPE_IDENTITY();
    INSERT INTO Shifts (DepartmentId, Name, SortOrder, IsActive) VALUES (@StoresId, N'2nd Shift', 2, 1); SET @Stores2 = SCOPE_IDENTITY();
    INSERT INTO Shifts (DepartmentId, Name, SortOrder, IsActive) VALUES (@StoresId, N'3rd Shift', 3, 1); SET @Stores3 = SCOPE_IDENTITY();
    INSERT INTO Shifts (DepartmentId, Name, SortOrder, IsActive) VALUES (@StoresId, N'Continental Nights', 4, 1); SET @StoresC = SCOPE_IDENTITY();
    DECLARE @Dispatch1 INT, @Dispatch2 INT, @Dispatch3 INT, @DispatchC INT;
    INSERT INTO Shifts (DepartmentId, Name, SortOrder, IsActive) VALUES (@DispatchId, N'1st Shift', 1, 1); SET @Dispatch1 = SCOPE_IDENTITY();
    INSERT INTO Shifts (DepartmentId, Name, SortOrder, IsActive) VALUES (@DispatchId, N'2nd Shift', 2, 1); SET @Dispatch2 = SCOPE_IDENTITY();
    INSERT INTO Shifts (DepartmentId, Name, SortOrder, IsActive) VALUES (@DispatchId, N'3rd Shift', 3, 1); SET @Dispatch3 = SCOPE_IDENTITY();
    INSERT INTO Shifts (DepartmentId, Name, SortOrder, IsActive) VALUES (@DispatchId, N'Continental Nights', 4, 1); SET @DispatchC = SCOPE_IDENTITY();

    DECLARE @item INT, @ditem INT;

    -- ===================== Stores: DP1 & DP3 task lists =====================
    -- 1st Shift (15 items)
    DECLARE @tl1 INT;
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@StoresMainAreaId, @Stores1, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    SET @tl1 = SCOPE_IDENTITY();
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'Complete pre shift check book been done on the forklift/ ppt and pallet trucks', 10, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'Tidy the yard at both ends and ensure returns ready for collection: pallets / stillages & German returns', 20, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'order everything for today''s production (spc / AMC TRACKING sheet)', 30, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'stock check the gas at dp1 and raise any shortages. correct if needed on sap', 40, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'Check that the gas cage is tidy and all bottles stored safely, action if not', 50, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'Count pallet trailers and raise potential shortages for the next shift - Escalate any issues.', 60, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'send any parcels to consumables to be processed – first batch by 9.30am', 70, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'send any parcels to consumables to be processed – Batch 2 by 11.30am', 80, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'send any parcels to consumables to be processed – batch 3 by 1.30pm', 90, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'Inspect racking areas and report any damage, also remove any unnecessary banding or shrink wrap you find hanging from the racks', 100, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'inspect floors and fire exit and ensure they are clear of obstructions. IE: Pallets, stillages and empty crates', 110, 1, NULL, NULL, NULL, NULL, NULL);
    SET @item = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@item, N'9am', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@item, N'11am', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@item, N'1pm', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@item, N'3pm', 40);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'Check verticals on order to replace any pallets used', 120, 1, NULL, NULL, NULL, NULL, NULL);
    SET @item = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@item, N'9am', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@item, N'11am', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@item, N'1pm', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@item, N'3pm', 40);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'Inspect DP1 – move any pallets of steel over hanging the WALKWAYS and ensure coils are not exceeding the blue height restriction line', 130, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'inspect pallets in stores and ensure we have no sharp edge pallets', 140, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl1, N'sweep through the store and ensure it is tidy for the next shift.', 150, 0, NULL, NULL, NULL, NULL, NULL);

    -- 2nd Shift (15 items)
    DECLARE @tl2 INT;
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@StoresMainAreaId, @Stores2, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    SET @tl2 = SCOPE_IDENTITY();
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'has the pre shift check books been done on the forklift / ppt and the pallets trucks?', 10, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'Have the pallet trailers been counted and any potential shortages been raised for the next shift? Escalate any issues.', 20, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'Have we ordered the tx so it''s on site for 23:00 start', 30, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'Have we located everything that was booked in by the previous shift and cleared option 1 put away?', 40, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'is the mla area clean and tidy with no returned stock just sitting around. If SO, please return to the correct stores', 50, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'Check the racking for anything hanging down and correct this IE: banding, shrink wrap etc.', 60, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'Has the parcel shelf been sent to consumables to be processed? Every 2 hours', 70, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'Are racking areas safe? And all damage if any has been reported', 80, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'Are floors and fire exit clear of obstructions. IE: Pallets, stillages and empty crates', 90, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'have the scrap caps been loaded onto the Ferguson''s trailer', 100, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'Have we cycle counted the pallet trailers and corrected the stocks', 110, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'have the verticals been ordered every time we issue a pallet so we have constant stock flow?', 120, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'Are pallets of steel over hanging the WALKWAYS in dp1 and not exceeding the blue hight restriction line?', 130, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'are the operators ENSURING that we have no sharp edge pallets in the stores', 140, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl2, N'have we swept through the store and is it tidy for the next shift.', 150, 0, NULL, NULL, NULL, NULL, NULL);

    -- 3rd Shift (12 items)
    DECLARE @tl3 INT;
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@StoresMainAreaId, @Stores3, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    SET @tl3 = SCOPE_IDENTITY();
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'Has the pre shift check book been done on the forklift/ ppt and pallet trucks?', 10, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'Are racking areas safe? And all damage if any has been reported', 20, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'Are all pallets strapped and stored safely at DP1 / DP3', 30, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'Is the TX on the line and not still in stores?', 40, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'Have the parcels been sent to consumables to be processed? Every two hours on this!', 50, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'Are floors and fire exit clear of obstructions. IE: Pallets, stillages and empty crates', 60, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'Do the racks have any banding or shrink wrap hanging from them that needs removing?', 70, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'Are pallets of steel over hanging the WALKWAYS in dp1 and not exceeding the blue hight restriction line?', 80, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'Are the cycle counts done for the day and if not please ensure they are finished.', 90, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'are the operators ENSURING that we have no sharp edge pallets in the stores', 100, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'Is the put away clear for the next shift and all deliveries put away?', 110, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl3, N'have we swept through the store and is it tidy for the next shift.', 120, 0, NULL, NULL, NULL, NULL, NULL);

    -- Continental Nights (10 items)
    DECLARE @tl4 INT;
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@StoresMainAreaId, @StoresC, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    SET @tl4 = SCOPE_IDENTITY();
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl4, N'Has the pre shift check book been done on the forklift/ ppt and pallet trucks?', 10, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl4, N'Are racking areas safe? And all damage if any has been reported', 20, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl4, N'Are all pallets strapped and stored safely at DP1', 30, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl4, N'Is the coils area safe and nothing blocking the fire exit or obstructing the WALKWAYS', 40, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl4, N'Do the racks have any banding or shrink wrap hanging from them that needs removing?', 50, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl4, N'Are pallets of steel over hanging the WALKWAYS in dp1 and not exceeding the blue hight restriction line?', 60, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl4, N'Are the cycle counts done for the day and if not please ensure they are finished.', 70, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl4, N'Is the put away clear for the next shift and all deliveries put away?', 80, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl4, N'Have the scrap tables and bins been emptied for the next shift and not left so production is stopped at 07:00', 90, 0, NULL, NULL, NULL, NULL, NULL);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@tl4, N'have we swept through the store and is it tidy for the next shift. If no ask DP3 to support', 100, 0, NULL, NULL, NULL, NULL, NULL);

    -- ===================== Stores: Consumables task lists (empty, awaiting real list) =====================
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@ConsumablesAreaId, @Stores1, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@ConsumablesAreaId, @Stores2, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@ConsumablesAreaId, @Stores3, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@ConsumablesAreaId, @StoresC, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');

    -- ===================== Dispatch: Warehouse audit task lists =====================
    -- Dispatch Warehouse audit — 1st Shift
    DECLARE @dtl1 INT;
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@WarehouseAreaId, @Dispatch1, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    SET @dtl1 = SCOPE_IDENTITY();
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Walkways, fire exits and emergency routes are clear', 10, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'PPE requirements are being followed', 20, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'No unsafe stacking, damaged pallets or falling-object risks (Mezz Floor)', 30, 1, N'H&S', N'Hourly', N'Senior Operator', NULL, N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Loading bays, dock levellers and vehicle Security is safe (Rite Height)', 40, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Correct product, quantity and destination are being picked (Bay Sheets)', 50, 1, N'Quality', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Labels, paperwork and scanning are accurate (Check Scanner V Loading)', 60, 1, N'Quality', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Picking and despatch activity is on plan', 70, 1, N'Performance', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Bottlenecks, downtime and waiting vehicles are controlled', 80, 1, N'Performance', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Pre-use equipment checks are completed and defects reported (Check Booklets)', 90, 0, N'H&S', N'Per Shift', N'Senior Operator', N'HOD', N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Spill kits, first-aid and fire points are accessible', 100, 0, N'H&S', N'Per Shift', N'Senior Operator', NULL, N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Pedestrian and MHE segregation controls are effective', 110, 0, N'H&S', N'Per Shift', N'Senior Operator', N'HOD', N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Packaging standards and load security are acceptable', 120, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Damaged, quarantined or non-conforming stock is controlled On Hold Products Red Card', 130, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'FIFO/stock rotation requirements are followed where applicable (New)', 140, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Shift plan, priorities and cut-off times were communicated (Shift Start Up)', 150, 0, N'Performance', N'Per Shift', N'HOD', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Labour and equipment resources are adequate for the plan', 160, 0, N'Performance', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Shift KPIs, backlog and carry-over work were reviewed (RPS)', 170, 0, N'Performance', N'Per Shift', N'Senior Operator', N'HOD', N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Team brief and safety message were completed ( Start of Each Shift Team Brief)', 180, 0, N'Morale', N'Per Shift', N'HOD', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Team concerns, support needs and training gaps were discussed', 190, 0, N'Morale', N'Per Shift', N'HOD', NULL, N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Good performance and positive behaviours were recognised', 200, 0, N'Morale', N'Per Shift', N'Senior Operator', N'HOD', N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'General housekeeping and waste controls meet standard', 210, 0, N'H&S', N'Daily', N'Senior Operator', N'HOD', N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'A sample of completed orders was checked for accuracy ( PickList V Shipping Documents)', 220, 0, N'Quality', N'Daily', N'Senior Operator', N'HOD', N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Daily output, service, productivity and missed deadlines were reviewed ( Transport Late Runners, No Shows)', 230, 0, N'Performance', N'Daily', N'Senior Operator', NULL, N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl1, N'Absence, overtime, workload and welfare concerns were reviewed', 240, 0, N'Morale', N'Daily', N'HOD', NULL, N'Same day');

    -- Dispatch Warehouse audit — 2nd Shift
    DECLARE @dtl2 INT;
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@WarehouseAreaId, @Dispatch2, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    SET @dtl2 = SCOPE_IDENTITY();
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Walkways, fire exits and emergency routes are clear', 10, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'PPE requirements are being followed', 20, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'No unsafe stacking, damaged pallets or falling-object risks (Mezz Floor)', 30, 1, N'H&S', N'Hourly', N'Senior Operator', NULL, N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Loading bays, dock levellers and vehicle Security is safe (Rite Height)', 40, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Correct product, quantity and destination are being picked (Bay Sheets)', 50, 1, N'Quality', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Labels, paperwork and scanning are accurate (Check Scanner V Loading)', 60, 1, N'Quality', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Picking and despatch activity is on plan', 70, 1, N'Performance', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Bottlenecks, downtime and waiting vehicles are controlled', 80, 1, N'Performance', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Pre-use equipment checks are completed and defects reported (Check Booklets)', 90, 0, N'H&S', N'Per Shift', N'Senior Operator', N'HOD', N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Spill kits, first-aid and fire points are accessible', 100, 0, N'H&S', N'Per Shift', N'Senior Operator', NULL, N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Pedestrian and MHE segregation controls are effective', 110, 0, N'H&S', N'Per Shift', N'Senior Operator', N'HOD', N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Packaging standards and load security are acceptable', 120, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Damaged, quarantined or non-conforming stock is controlled On Hold Products Red Card', 130, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'FIFO/stock rotation requirements are followed where applicable (New)', 140, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Shift plan, priorities and cut-off times were communicated (Shift Start Up)', 150, 0, N'Performance', N'Per Shift', N'HOD', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Labour and equipment resources are adequate for the plan', 160, 0, N'Performance', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Shift KPIs, backlog and carry-over work were reviewed (RPS)', 170, 0, N'Performance', N'Per Shift', N'Senior Operator', N'HOD', N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Team brief and safety message were completed ( Start of Each Shift Team Brief)', 180, 0, N'Morale', N'Per Shift', N'HOD', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Team concerns, support needs and training gaps were discussed', 190, 0, N'Morale', N'Per Shift', N'HOD', NULL, N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Good performance and positive behaviours were recognised', 200, 0, N'Morale', N'Per Shift', N'Senior Operator', N'HOD', N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'General housekeeping and waste controls meet standard', 210, 0, N'H&S', N'Daily', N'Senior Operator', N'HOD', N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'A sample of completed orders was checked for accuracy ( PickList V Shipping Documents)', 220, 0, N'Quality', N'Daily', N'Senior Operator', N'HOD', N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Daily output, service, productivity and missed deadlines were reviewed ( Transport Late Runners, No Shows)', 230, 0, N'Performance', N'Daily', N'Senior Operator', NULL, N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl2, N'Absence, overtime, workload and welfare concerns were reviewed', 240, 0, N'Morale', N'Daily', N'HOD', NULL, N'Same day');

    -- Dispatch Warehouse audit — 3rd Shift
    DECLARE @dtl3 INT;
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@WarehouseAreaId, @Dispatch3, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    SET @dtl3 = SCOPE_IDENTITY();
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Walkways, fire exits and emergency routes are clear', 10, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'PPE requirements are being followed', 20, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'No unsafe stacking, damaged pallets or falling-object risks (Mezz Floor)', 30, 1, N'H&S', N'Hourly', N'Senior Operator', NULL, N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Loading bays, dock levellers and vehicle Security is safe (Rite Height)', 40, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Correct product, quantity and destination are being picked (Bay Sheets)', 50, 1, N'Quality', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Labels, paperwork and scanning are accurate (Check Scanner V Loading)', 60, 1, N'Quality', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Picking and despatch activity is on plan', 70, 1, N'Performance', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Bottlenecks, downtime and waiting vehicles are controlled', 80, 1, N'Performance', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Pre-use equipment checks are completed and defects reported (Check Booklets)', 90, 0, N'H&S', N'Per Shift', N'Senior Operator', N'HOD', N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Spill kits, first-aid and fire points are accessible', 100, 0, N'H&S', N'Per Shift', N'Senior Operator', NULL, N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Pedestrian and MHE segregation controls are effective', 110, 0, N'H&S', N'Per Shift', N'Senior Operator', N'HOD', N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Packaging standards and load security are acceptable', 120, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Damaged, quarantined or non-conforming stock is controlled On Hold Products Red Card', 130, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'FIFO/stock rotation requirements are followed where applicable (New)', 140, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Shift plan, priorities and cut-off times were communicated (Shift Start Up)', 150, 0, N'Performance', N'Per Shift', N'HOD', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Labour and equipment resources are adequate for the plan', 160, 0, N'Performance', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Shift KPIs, backlog and carry-over work were reviewed (RPS)', 170, 0, N'Performance', N'Per Shift', N'Senior Operator', N'HOD', N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Team brief and safety message were completed ( Start of Each Shift Team Brief)', 180, 0, N'Morale', N'Per Shift', N'HOD', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Team concerns, support needs and training gaps were discussed', 190, 0, N'Morale', N'Per Shift', N'HOD', NULL, N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Good performance and positive behaviours were recognised', 200, 0, N'Morale', N'Per Shift', N'Senior Operator', N'HOD', N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'General housekeeping and waste controls meet standard', 210, 0, N'H&S', N'Daily', N'Senior Operator', N'HOD', N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'A sample of completed orders was checked for accuracy ( PickList V Shipping Documents)', 220, 0, N'Quality', N'Daily', N'Senior Operator', N'HOD', N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Daily output, service, productivity and missed deadlines were reviewed ( Transport Late Runners, No Shows)', 230, 0, N'Performance', N'Daily', N'Senior Operator', NULL, N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl3, N'Absence, overtime, workload and welfare concerns were reviewed', 240, 0, N'Morale', N'Daily', N'HOD', NULL, N'Same day');

    -- Dispatch Warehouse audit — Continental Nights
    DECLARE @dtl4 INT;
    INSERT INTO TaskLists (AreaId, ShiftId, Version, IsCurrent, HealthRepsReminder, CreatedAt, CreatedBy) VALUES (@WarehouseAreaId, @DispatchC, 1, 1, NULL, SYSUTCDATETIME(), N'Seed');
    SET @dtl4 = SCOPE_IDENTITY();
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Walkways, fire exits and emergency routes are clear', 10, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'PPE requirements are being followed', 20, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'No unsafe stacking, damaged pallets or falling-object risks (Mezz Floor)', 30, 1, N'H&S', N'Hourly', N'Senior Operator', NULL, N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Loading bays, dock levellers and vehicle Security is safe (Rite Height)', 40, 1, N'H&S', N'Hourly', N'Senior Operator', N'HOD', N'Immediate');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Correct product, quantity and destination are being picked (Bay Sheets)', 50, 1, N'Quality', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Labels, paperwork and scanning are accurate (Check Scanner V Loading)', 60, 1, N'Quality', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Picking and despatch activity is on plan', 70, 1, N'Performance', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Bottlenecks, downtime and waiting vehicles are controlled', 80, 1, N'Performance', N'Hourly', N'Senior Operator', NULL, N'Same shift');
    SET @ditem = SCOPE_IDENTITY();
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 1', 10);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 2', 20);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 3', 30);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 4', 40);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 5', 50);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 6', 60);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 7', 70);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 8', 80);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 9', 90);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 10', 100);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 11', 110);
    INSERT INTO TaskCheckpoints (TaskItemId, Label, SortOrder) VALUES (@ditem, N'Hr 12', 120);
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Pre-use equipment checks are completed and defects reported (Check Booklets)', 90, 0, N'H&S', N'Per Shift', N'Senior Operator', N'HOD', N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Spill kits, first-aid and fire points are accessible', 100, 0, N'H&S', N'Per Shift', N'Senior Operator', NULL, N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Pedestrian and MHE segregation controls are effective', 110, 0, N'H&S', N'Per Shift', N'Senior Operator', N'HOD', N'Immediate');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Packaging standards and load security are acceptable', 120, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Damaged, quarantined or non-conforming stock is controlled On Hold Products Red Card', 130, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'FIFO/stock rotation requirements are followed where applicable (New)', 140, 0, N'Quality', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Shift plan, priorities and cut-off times were communicated (Shift Start Up)', 150, 0, N'Performance', N'Per Shift', N'HOD', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Labour and equipment resources are adequate for the plan', 160, 0, N'Performance', N'Per Shift', N'Senior Operator', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Shift KPIs, backlog and carry-over work were reviewed (RPS)', 170, 0, N'Performance', N'Per Shift', N'Senior Operator', N'HOD', N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Team brief and safety message were completed ( Start of Each Shift Team Brief)', 180, 0, N'Morale', N'Per Shift', N'HOD', NULL, N'Same shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Team concerns, support needs and training gaps were discussed', 190, 0, N'Morale', N'Per Shift', N'HOD', NULL, N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Good performance and positive behaviours were recognised', 200, 0, N'Morale', N'Per Shift', N'Senior Operator', N'HOD', N'Next shift');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'General housekeeping and waste controls meet standard', 210, 0, N'H&S', N'Daily', N'Senior Operator', N'HOD', N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'A sample of completed orders was checked for accuracy ( PickList V Shipping Documents)', 220, 0, N'Quality', N'Daily', N'Senior Operator', N'HOD', N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Daily output, service, productivity and missed deadlines were reviewed ( Transport Late Runners, No Shows)', 230, 0, N'Performance', N'Daily', N'Senior Operator', NULL, N'Same day');
    INSERT INTO TaskItems (TaskListId, Text, SortOrder, IsTimeBoxed, Category, Cadence, ResponsibleRole, EscalateToRole, EscalationWindow) VALUES (@dtl4, N'Absence, overtime, workload and welfare concerns were reviewed', 240, 0, N'Morale', N'Daily', N'HOD', NULL, N'Same day');


END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909102920_SeedInitialData'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260909102920_SeedInitialData', N'8.0.10');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909144714_AddPeopleAndSplitStoresAreas'
)
BEGIN
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
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909144714_AddPeopleAndSplitStoresAreas'
)
BEGIN
    CREATE INDEX [IX_People_DepartmentId] ON [People] ([DepartmentId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909144714_AddPeopleAndSplitStoresAreas'
)
BEGIN
    CREATE UNIQUE INDEX [IX_People_Role_DisplayName] ON [People] ([Role], [DisplayName]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909144714_AddPeopleAndSplitStoresAreas'
)
BEGIN

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

END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909144714_AddPeopleAndSplitStoresAreas'
)
BEGIN

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

END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909144714_AddPeopleAndSplitStoresAreas'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260909144714_AddPeopleAndSplitStoresAreas', N'8.0.10');
END;
GO

COMMIT;
GO

