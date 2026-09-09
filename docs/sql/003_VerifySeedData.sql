-- ============================================================================
-- SAS — Support Audit System
-- Verification queries for the seeded configuration data.
-- Run against the Rittal_Support database (or whatever you named it) after
-- applying 001_InitialCreate.sql and 002_SeedInitialData.sql (or the combined
-- 000_FullDeploy_IdempotentFromScratch.sql).
-- ============================================================================

-- 1) Departments, areas and shifts exist and are active.
SELECT Id, Name, SortOrder, IsActive FROM Departments ORDER BY SortOrder;

SELECT a.Id, d.Name AS Department, a.Name AS Area, a.DefaultLocation, a.SortOrder, a.IsActive
FROM Areas a JOIN Departments d ON d.Id = a.DepartmentId
ORDER BY d.SortOrder, a.SortOrder;

SELECT s.Id, d.Name AS Department, s.Name AS Shift, s.SortOrder, s.IsActive
FROM Shifts s JOIN Departments d ON d.Id = s.DepartmentId
ORDER BY d.SortOrder, s.SortOrder;

-- 2) One current task list per Area + Shift combination that has been seeded,
--    and the item counts match what was transcribed from source documents:
--    Stores/DP1 & DP3 = 15, 15, 12, 10 for 1st/2nd/3rd/Continental Nights;
--    Stores/Consumables = 0 for all four shifts (awaiting the real list);
--    Dispatch/Warehouse = 24 for all four shifts.
SELECT
    d.Name AS Department,
    a.Name AS Area,
    sh.Name AS Shift,
    tl.Version,
    tl.IsCurrent,
    COUNT(ti.Id) AS ItemCount
FROM TaskLists tl
JOIN Areas a ON a.Id = tl.AreaId
JOIN Shifts sh ON sh.Id = tl.ShiftId
JOIN Departments d ON d.Id = a.DepartmentId
LEFT JOIN TaskItems ti ON ti.TaskListId = tl.Id
GROUP BY d.Name, a.Name, sh.Name, tl.Version, tl.IsCurrent, d.SortOrder, a.SortOrder, sh.SortOrder
ORDER BY d.SortOrder, a.SortOrder, sh.SortOrder;

-- 3) THE key check: every Dispatch task item has Category populated
--    (and, for completeness, the other four category-related fields too).
--    This should return ZERO rows — any row returned is a seeding defect.
SELECT
    d.Name AS Department,
    a.Name AS Area,
    sh.Name AS Shift,
    ti.Id AS TaskItemId,
    ti.Text,
    ti.Category,
    ti.Cadence,
    ti.ResponsibleRole,
    ti.EscalateToRole,
    ti.EscalationWindow
FROM TaskItems ti
JOIN TaskLists tl ON tl.Id = ti.TaskListId
JOIN Areas a ON a.Id = tl.AreaId
JOIN Departments d ON d.Id = a.DepartmentId
JOIN Shifts sh ON sh.Id = tl.ShiftId
WHERE d.Name = N'Dispatch'
  AND (ti.Category IS NULL OR ti.Cadence IS NULL OR ti.ResponsibleRole IS NULL OR ti.EscalationWindow IS NULL);
-- Expected result: 0 rows.

-- 3b) Positive confirmation — count of Dispatch task items WITH Category populated,
--     should equal 24 per task list (4 task lists x 24 = 96 total).
SELECT
    sh.Name AS Shift,
    COUNT(*) AS DispatchItemsWithCategory
FROM TaskItems ti
JOIN TaskLists tl ON tl.Id = ti.TaskListId
JOIN Areas a ON a.Id = tl.AreaId
JOIN Departments d ON d.Id = a.DepartmentId
JOIN Shifts sh ON sh.Id = tl.ShiftId
WHERE d.Name = N'Dispatch' AND ti.Category IS NOT NULL
GROUP BY sh.Name, sh.SortOrder
ORDER BY sh.SortOrder;

-- 4) Conversely, Stores task items must have Category left NULL throughout
--    (never forced on items that have no natural category). Should be 0 rows.
SELECT ti.Id, ti.Text, ti.Category
FROM TaskItems ti
JOIN TaskLists tl ON tl.Id = ti.TaskListId
JOIN Areas a ON a.Id = tl.AreaId
JOIN Departments d ON d.Id = a.DepartmentId
WHERE d.Name = N'Stores' AND ti.Category IS NOT NULL;
-- Expected result: 0 rows.

-- 5) Time-boxed items have checkpoints, and non-time-boxed items don't.
SELECT ti.Id, ti.Text, ti.IsTimeBoxed, COUNT(tc.Id) AS CheckpointCount
FROM TaskItems ti
LEFT JOIN TaskCheckpoints tc ON tc.TaskItemId = ti.Id
GROUP BY ti.Id, ti.Text, ti.IsTimeBoxed
HAVING (ti.IsTimeBoxed = 1 AND COUNT(tc.Id) = 0)
    OR (ti.IsTimeBoxed = 0 AND COUNT(tc.Id) > 0);
-- Expected result: 0 rows.

-- 6) Dispatch's 8 Hourly items each have exactly 12 checkpoints (Hr 1..Hr 12);
--    the two Stores time-boxed items each have exactly 4 (9am/11am/1pm/3pm).
SELECT ti.Id, ti.Text, ti.Cadence, COUNT(tc.Id) AS CheckpointCount
FROM TaskItems ti
JOIN TaskCheckpoints tc ON tc.TaskItemId = ti.Id
WHERE ti.IsTimeBoxed = 1
GROUP BY ti.Id, ti.Text, ti.Cadence
ORDER BY ti.Id;

-- 7) Uniqueness constraints are real database constraints, not just app-level
--    checks — confirm the indexes exist.
SELECT
    i.name AS IndexName,
    i.is_unique,
    OBJECT_NAME(i.object_id) AS TableName,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS Columns
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.is_unique = 1
  AND OBJECT_NAME(i.object_id) IN (N'Areas', N'Shifts', N'ChecklistSubmissions', N'TaskResponses', N'CheckpointResponses', N'Departments')
GROUP BY i.name, i.is_unique, i.object_id
ORDER BY TableName;

-- 8) Sanity: no orphaned TaskLists (every Area/Shift pair on a TaskList belongs
--    to the same Department).
SELECT tl.Id, a.DepartmentId AS AreaDept, sh.DepartmentId AS ShiftDept
FROM TaskLists tl
JOIN Areas a ON a.Id = tl.AreaId
JOIN Shifts sh ON sh.Id = tl.ShiftId
WHERE a.DepartmentId <> sh.DepartmentId;
-- Expected result: 0 rows.
