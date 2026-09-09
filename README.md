# SAS — Support Audit System

Digital Safe Start checklists (paper reference: SHEF014) for the **Stores** and
**Dispatch** support departments. Built with ASP.NET Core 8 Razor Pages, EF Core
8 (SQL Server), and QuestPDF.

Every department, area, shift, category and task lives in the database, not in
code. Stores and Dispatch could both be deleted and re-entered through
`/Admin` with no code change and no redeployment.

## Project layout

```
SAS.sln
src/SAS.Web/            ASP.NET Core Razor Pages app
  Models/                Entity classes
  Data/AppDbContext.cs   EF Core DbContext + Fluent API configuration
  Migrations/            EF Core migrations (schema + seed data)
  Pages/                 Checklist entry, Completed list, Admin CRUD
  Services/              ChecklistService (save/progress logic), PdfExportService
docs/sql/                Plain SQL equivalents of every migration, for SSMS
```

## Prerequisites

- .NET 8 SDK
- SQL Server (any edition) reachable from where you run the app
- `dotnet-ef` tool: `dotnet tool install --global dotnet-ef --version 8.0.10`

## Configuring the connection string (never commit this)

The connection string is **not** hardcoded anywhere in the repo.
`appsettings.json` ships with an empty `ConnectionStrings:Default`, and
`appsettings.Development.json` (gitignored) is where you put your real local
value. Options, in order of preference:

1. **User secrets** (recommended for local dev):
   ```
   cd src/SAS.Web
   dotnet user-secrets set "ConnectionStrings:Default" "Server=YOUR_SERVER;Database=SasSupportAudit;User Id=...;Password=...;TrustServerCertificate=True"
   ```
2. **Environment variable**: `ConnectionStrings__Default`
3. **`appsettings.Development.json`** (gitignored — safe to edit locally, never committed)

## Applying migrations (EF CLI)

```
cd src/SAS.Web
dotnet ef database update
```

This creates the database (if it doesn't exist) and applies both migrations:
`InitialCreate` (schema) and `SeedInitialData` (Stores' four task lists
transcribed from the source documents, Consumables' empty task lists, and
Dispatch's 24-check Warehouse audit) — all in one transaction per migration.

## Applying migrations directly in SSMS (no dotnet ef tooling required)

Everything EF Core would run is also provided as plain, runnable T-SQL in
`docs/sql/`:

| File | What it does |
|---|---|
| `docs/sql/000_FullDeploy_IdempotentFromScratch.sql` | Creates the database schema **and** seeds all data, from nothing. Idempotent — safe to re-run; already-applied migrations are skipped via `__EFMigrationsHistory`. **This is the one to run in SSMS against a brand-new database.** |
| `docs/sql/001_InitialCreate.sql` | Schema only (tables, keys, unique indexes, foreign keys). |
| `docs/sql/002_SeedInitialData.sql` | Seed data only (Departments, Areas, Shifts, TaskLists, TaskItems, TaskCheckpoints) — run after 001. |
| `docs/sql/003_VerifySeedData.sql` | Verification queries, including the one confirming every Dispatch task item has `Category` populated. |

To create the database from nothing in SSMS: open a query window connected to
your target server, `CREATE DATABASE SasSupportAudit;`, switch to it, then run
`000_FullDeploy_IdempotentFromScratch.sql`. Then run `003_VerifySeedData.sql`
to confirm the seed looks right.

Every future migration in this project will ship the same way: an EF
migration plus its plain-SQL equivalent in `docs/sql/`, generated with:

```
dotnet ef migrations script <PreviousMigration> <NewMigration> -o docs/sql/NNN_NewMigration.sql
```

**Standing rule for future seed-data migrations**: any change to existing seed
rows must update them by their stable identifying fields (e.g. `Department
Name` + `Area Name`), never an insert-only-if-missing pattern that silently
skips rows that already exist.

## Running the app

```
cd src/SAS.Web
dotnet run
```

## Schema notes

- **Category-related fields** on `TaskItems` (`Category`, `Cadence`,
  `ResponsibleRole`, `EscalateToRole`, `EscalationWindow`) exist from the
  first migration and are nullable. They are `NULL` throughout for Stores
  (which has no natural category) and fully populated for Dispatch's
  Warehouse audit, seeded in the same transaction that creates the items.
- **Time-boxed items** (`IsTimeBoxed = 1`) carry their own `TaskCheckpoints`
  (e.g. `Hr 1`..`Hr 12` for Dispatch's Hourly-cadence items, `9am`/`11am`/
  `1pm`/`3pm` for the two Stores tasks that repeat at fixed times in the
  source documents) — checkpoint columns are entirely admin-editable, not a
  hardcoded hour count.
- **Continuity** (resuming a checklist someone else started) matches on
  `AreaId` + `ShiftId` + `ChecklistDate` only — enforced as a real unique
  index on `ChecklistSubmissions`, never on a person's name.
- The checklist entry page renders the **Dispatch hourly grid** (one table per
  category, colour-coded section rows, one column per hour) whenever any item
  in the task list has `Category` populated, and the **Stores card layout**
  (one task per card, Done/Issue, mandatory notes on Issue) otherwise — so the
  rendering follows the data, not a hardcoded department check.

## PDF export

`Services/PdfExportService.cs` renders a SHEF014-style PDF via QuestPDF
(Community licence), available from the checklist page and the Completed
list. A PDF is only offered for a submission that has already been
successfully written to the database — the export handler reads it back from
the database rather than the in-memory form state.
