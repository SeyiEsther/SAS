# SAS — Support Audit System

Digital Safe Start checklists (paper reference: SHEF014) for the **Stores** and
**Dispatch** support departments. Built with ASP.NET Core 8 Razor Pages, EF Core
8 (SQL Server), and QuestPDF.

Every department, area, shift, category and task lives in the database, not in
code. Stores and Dispatch could both be deleted and re-entered through
`/Admin` with no code change and no redeployment.

## Project layout

Structured to match the conventions of `github.com/SeyiEsther/TL` (the
Production Audit System): Razor Pages only ever render (GET); every write
goes through a Controller; business logic lives in Services, not in
PageModels or Controllers.

```
SAS.sln
src/SAS.Web/            ASP.NET Core app (Razor Pages + API Controllers)
  Models/                Entity classes
  Data/AppDbContext.cs   EF Core DbContext + Fluent API configuration
  Migrations/            EF Core migrations (schema + seed data)
  Pages/                 GET-only: checklist entry render, Completed list, Admin CRUD forms
  Controllers/           The writable surface — every save/complete/PDF request
    ChecklistController    Save task, save checkpoint, save notes, save meta, complete
    PdfController           GET /api/checklist/pdf — exports what's already saved in the DB
  Services/              One service per concern, mirroring TL's Services/ split
    ChecklistLoadService    Find-or-create a submission, load its task list (continuity)
    ChecklistSaveService    Every individual autosave write
    ChecklistCompletionService  Validates and performs sign-off
    HistoryListService      Filterable Completed-checklists query
    AdminService            Full CRUD for every configuration table
    PdfExportService        QuestPDF rendering
    ChecklistProgress       Shared "is this item answered / how many issues" helpers
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

**There is exactly one file to run for a normal deploy:
`docs/sql/000_FullDeploy_IdempotentFromScratch.sql`.** It creates the schema
and seeds all the data, and it's idempotent — it checks
`__EFMigrationsHistory` before doing anything, so running it again on a
database that already has this schema is a safe no-op, not an error.

**Before running anything**, run `docs/sql/999_DiagnoseCurrentState.sql`
first — it's read-only and tells you whether the target database already has
this schema (and, if so, whether the seed data landed correctly). If it
already does, you don't need to run a deploy script at all.

| File | What it does | When to run it |
|---|---|---|
| `docs/sql/999_DiagnoseCurrentState.sql` | Read-only: shows `__EFMigrationsHistory`, table row counts, and current Departments. | **Run this first, always.** |
| `docs/sql/000_FullDeploy_IdempotentFromScratch.sql` | Schema + seed, idempotent. | The only script you need for a normal deploy or re-deploy. |
| `docs/sql/003_VerifySeedData.sql` | Verification queries, including the one confirming every Dispatch task item has `Category` populated. | After 000, to confirm the seed looks right. |
| `docs/sql/001_InitialCreate.sql` | Schema only — **not idempotent**, plain `CREATE TABLE`. | Reference only / advanced use (e.g. scripting just this one migration for a change-review tool). **Never run this against a database that might already have the schema** — it will fail with "already exists" on every table, exactly like the error from Sept 9: that happened because 001 was run again on top of a database 000 had already deployed successfully. |
| `docs/sql/002_SeedInitialData.sql` | Seed data only — **not idempotent**, plain `INSERT`. | Same caveat as 001: reference only, never run on a database that already has the seed rows. |

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

## Matching TL's structure — what was and wasn't carried over

Per your instruction, the app's architecture now mirrors
`github.com/SeyiEsther/TL`: Controllers own every write, Services are split
one-per-concern, `Program.cs` persists Data Protection keys the same way TL
does (so antiforgery tokens survive an app-pool recycle), and the
`AddAntiforgery` header convention (`X-CSRF-TOKEN`) matches TL's exactly.

One thing was **not** carried over: TL's Windows/Active-Directory
authentication (`Microsoft.AspNetCore.Authentication.Negotiate`,
`PortalAccessFilter`, `UserService`). Nothing in the original spec for this
project asked for a login system or role-gated access, so adding one would be
scope beyond what was requested. If you do want checklist access restricted
to authenticated users (AD-integrated, matching TL), say so explicitly and
I'll add it the same way TL does it.

## PDF export

`Services/PdfExportService.cs` renders a SHEF014-style PDF via QuestPDF
(Community licence), available from the checklist page and the Completed
list. A PDF is only offered for a submission that has already been
successfully written to the database — the export handler reads it back from
the database rather than the in-memory form state.
