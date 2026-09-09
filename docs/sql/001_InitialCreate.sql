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

CREATE TABLE [Departments] (
    [Id] int NOT NULL IDENTITY,
    [Name] nvarchar(200) NOT NULL,
    [SortOrder] int NOT NULL,
    [IsActive] bit NOT NULL,
    CONSTRAINT [PK_Departments] PRIMARY KEY ([Id])
);
GO

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
GO

CREATE TABLE [Shifts] (
    [Id] int NOT NULL IDENTITY,
    [DepartmentId] int NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [SortOrder] int NOT NULL,
    [IsActive] bit NOT NULL,
    CONSTRAINT [PK_Shifts] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Shifts_Departments_DepartmentId] FOREIGN KEY ([DepartmentId]) REFERENCES [Departments] ([Id]) ON DELETE NO ACTION
);
GO

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
GO

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
GO

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
GO

CREATE TABLE [TaskCheckpoints] (
    [Id] int NOT NULL IDENTITY,
    [TaskItemId] int NOT NULL,
    [Label] nvarchar(200) NOT NULL,
    [SortOrder] int NOT NULL,
    CONSTRAINT [PK_TaskCheckpoints] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_TaskCheckpoints_TaskItems_TaskItemId] FOREIGN KEY ([TaskItemId]) REFERENCES [TaskItems] ([Id]) ON DELETE CASCADE
);
GO

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
GO

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
GO

CREATE UNIQUE INDEX [IX_Areas_DepartmentId_Name] ON [Areas] ([DepartmentId], [Name]);
GO

CREATE UNIQUE INDEX [IX_ChecklistSubmissions_AreaId_ShiftId_ChecklistDate] ON [ChecklistSubmissions] ([AreaId], [ShiftId], [ChecklistDate]);
GO

CREATE INDEX [IX_ChecklistSubmissions_ShiftId] ON [ChecklistSubmissions] ([ShiftId]);
GO

CREATE INDEX [IX_ChecklistSubmissions_TaskListId] ON [ChecklistSubmissions] ([TaskListId]);
GO

CREATE INDEX [IX_CheckpointResponses_TaskCheckpointId] ON [CheckpointResponses] ([TaskCheckpointId]);
GO

CREATE UNIQUE INDEX [IX_CheckpointResponses_TaskResponseId_TaskCheckpointId] ON [CheckpointResponses] ([TaskResponseId], [TaskCheckpointId]);
GO

CREATE UNIQUE INDEX [IX_Departments_Name] ON [Departments] ([Name]);
GO

CREATE UNIQUE INDEX [IX_Shifts_DepartmentId_Name] ON [Shifts] ([DepartmentId], [Name]);
GO

CREATE INDEX [IX_TaskCheckpoints_TaskItemId_SortOrder] ON [TaskCheckpoints] ([TaskItemId], [SortOrder]);
GO

CREATE INDEX [IX_TaskItems_TaskListId_SortOrder] ON [TaskItems] ([TaskListId], [SortOrder]);
GO

CREATE INDEX [IX_TaskLists_AreaId_ShiftId_IsCurrent] ON [TaskLists] ([AreaId], [ShiftId], [IsCurrent]);
GO

CREATE INDEX [IX_TaskLists_ShiftId] ON [TaskLists] ([ShiftId]);
GO

CREATE UNIQUE INDEX [IX_TaskResponses_ChecklistSubmissionId_TaskItemId] ON [TaskResponses] ([ChecklistSubmissionId], [TaskItemId]);
GO

CREATE INDEX [IX_TaskResponses_TaskItemId] ON [TaskResponses] ([TaskItemId]);
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260909102620_InitialCreate', N'8.0.10');
GO

COMMIT;
GO

