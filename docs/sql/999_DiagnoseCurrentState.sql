-- ============================================================================
-- SAS — read-only diagnostic. Run this against RittalSupportSW (or whichever
-- database you targeted) to see exactly what's already there before running
-- any deployment script again. Nothing here writes data.
-- ============================================================================

-- 1) Has EF's migration bookkeeping table been created, and which migrations
--    does it think have been applied?
IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NOT NULL
    SELECT * FROM [__EFMigrationsHistory];
ELSE
    SELECT N'__EFMigrationsHistory does not exist — this DB was never touched by an EF migration script.' AS Note;

-- 2) Do the domain tables exist, and how many rows does each have?
SELECT
    t.name AS TableName,
    p.rows AS ApproxRowCount
FROM sys.tables t
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE t.name IN (N'Departments', N'Areas', N'Shifts', N'TaskLists', N'TaskItems',
                  N'TaskCheckpoints', N'ChecklistSubmissions', N'TaskResponses', N'CheckpointResponses')
ORDER BY t.name;

-- 3) If Departments exists and has rows, show them — tells us whether the
--    seed actually landed correctly on an earlier run.
IF OBJECT_ID(N'[Departments]') IS NOT NULL
    SELECT * FROM Departments ORDER BY SortOrder;

-- 4) Any currently open/orphaned transaction on this session (relevant to the
--    "COMMIT has no corresponding BEGIN" error) — should be 0.
SELECT @@TRANCOUNT AS OpenTransactionCount;
