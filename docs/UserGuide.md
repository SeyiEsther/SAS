# Support Audit System — User Guide

Safe Start checklists for Stores and Dispatch. Paper reference: SHEF014.

---

## 1. What this system is for

This replaces the paper Safe Start checklist. Someone on shift works down the
task list for their area and shift, marks each item, adds notes where something
isn't right, and an HOD signs it off at the end.

Everything saves the moment you tap it. There is no "save" button to forget —
if you walk away mid-shift and come back later, or someone else picks it up on
the same shift, the checklist is exactly as it was left.

**One checklist exists per area, per shift, per day.** If two people open the
same area and shift on the same date, they are working on the same checklist,
not two competing copies.

---

## 2. Signing in

There is no separate login. The system recognises you from your Windows
account the moment you open it, and your name appears in the top right corner.

If the top right shows an account **number** instead of your name, your account
hasn't been linked to your name yet. An admin can fix this in a few seconds —
see *Section 9, "Someone's number is showing instead of their name"*.

### What your role lets you do

| | Anyone on shift | HOD |
|---|---|---|
| Start and fill in a checklist | Yes | Yes |
| Add notes and raise issues | Yes | Yes |
| Answer checks marked **HOD only** | No | Yes |
| Sign a checklist off as complete | No | Yes |
| Download the PDF | Yes | Yes |
| View completed checklists | Yes | Yes |

HODs are managed in Admin. Being an HOD is the only thing that unlocks
sign-off and the HOD-only checks.

---

## 3. Starting a checklist

From the home page:

1. Check the **date** — it defaults to today. Change it only if you are
   catching up on a previous day.
2. Pick your **shift** from the dropdown. Shifts are grouped by department,
   so pick the one under the right heading.
3. Pick your **area** — also grouped by department.
4. Press **Start checklist**.

If a checklist already exists for that area, shift and date, you are taken
straight into it with everything already filled in so far. You are not
starting again from scratch.

> **Area and shift must be in the same department.** If you pick the Stores
> 1st Shift with a Dispatch area, the page tells you so rather than opening a
> checklist that makes no sense.

---

## 4. The checklist screen

The bar across the top shows the date, department, area and shift you are
working on. Under it:

- **Progress** — how many of the checks are answered, and a bar filling up
  as you go.
- **Checklist details** — auditor name(s) and location. Your name is filled
  in for you; add anyone else working with you.
- **HOD sign-off** — who signed it off. Only an HOD can use this.

Below that is the checklist itself. It looks different for Stores and
Dispatch, because the two work differently.

---

## 5. Stores checklists — one task per card

Each task is a card with a number, the task, and two large buttons:

- **Done** — the task is complete and there's nothing to report.
- **Issue** — something is wrong.

Tapping either saves immediately. The card turns green down the left edge for
Done, red for Issue, and a tick appears once it's answered.

### Tasks that repeat through the shift

Some tasks have to be done more than once — for example inspecting floors and
fire exits at 9am, 11am, 1pm and 3pm. These show as four separate slots on the
card, each with its own Done and Issue buttons. Answer each slot as you do it.

The card only counts as complete once **every** slot is answered.

### Notes

When you pick **Issue**, a notes box appears. **Notes are required** — the
issue is not saved until you've written something. Say what's wrong in enough
detail that whoever picks it up afterwards knows what they're dealing with.

---

## 6. Dispatch checklists — the hourly grid

Dispatch uses the Warehouse audit, which is a grid rather than cards. The
checks are grouped into four coloured sections:

- **H&S** (green)
- **Quality** (blue)
- **Performance** (orange)
- **Morale** (purple)

Each row is one check. Under each check is a grey line telling you who is
responsible for it and, where it applies, who an issue escalates to and how
quickly.

### Answering

- **Hourly checks** have a **Y** and **N** button for every hour of the shift
  (Hr 1 to Hr 12). Answer each hour as you do the walk round.
- **Per shift** and **Daily** checks have a single **Done / Issue** pair,
  because they are only done once.

Under every check is a **Description** row where you can write notes. Unlike
the Stores cards, this box is always visible — you don't have to raise an
issue first to use it.

### Checks marked "HOD only"

Four of the Dispatch checks are the HOD's to answer, and are marked **HOD
only**:

- Shift plan, priorities and cut-off times were communicated (Shift Start Up)
- Team brief and safety message were completed
- Team concerns, support needs and training gaps were discussed
- Absence, overtime, workload and welfare concerns were reviewed

If you are not an HOD, the buttons on those rows are greyed out. Fill in
everything else and hand the checklist to an HOD to finish.

---

## 7. Issues that have to be escalated

Some checks say in the audit that an issue must go to the HOD, and within a
set time — *Immediate*, *Same shift*, *Next shift* or *Same day*.

When you raise an issue on one of those checks, an orange **issues to
escalate** panel appears near the top of the checklist listing each one, who
it goes to, and the window.

**The panel is a reminder, not the escalation.** You still have to actually
tell the person. The panel is there so nothing gets quietly forgotten at the
end of a shift.

---

## 8. Finishing and signing off

Only an HOD can complete a checklist.

1. The HOD picks their name in **HOD sign-off**.
2. They press **Complete checklist**.

Before it will complete, the system checks that:

- **Every** check is answered — including every hour of every hourly check
  and every time slot on a repeating task.
- **Every issue has notes.**

If something is missing, it tells you exactly which check and which hour or
slot, so you can go straight to it.

Once complete, the checklist becomes read-only and shows who signed it off and
when. It can still be viewed and downloaded, but not changed.

### Leaving it part-finished

**Leave & come back later** just takes you back to the home page. Everything
you've answered is already saved. Come back to the same area, shift and date
and carry on — or let someone else on the same shift carry on.

---

## 9. Downloading and finding checklists

### Download a PDF

**Download PDF** on the checklist screen produces a SHEF014-style PDF of the
checklist as it stands — complete or not. It shows every task, the answer,
notes, the progress count and the issue count.

The PDF is generated from what is actually saved in the database, so it always
matches what's really recorded.

### Completed checklists

**Completed** in the top bar lists every checklist — finished and in progress.
Filter by department, area, shift and date range. Each row shows progress, how
many issues were raised and who signed it off. **Open** goes to the checklist,
**PDF** downloads it.

---

## 10. Admin

**Admin** in the top bar. Everything the checklists are built from lives here
and can be changed without anyone touching the code.

| Section | What it holds |
|---|---|
| **Departments** | Stores, Dispatch |
| **Areas** | DP1, DP3, Consumables, Warehouse |
| **Shifts** | 1st, 2nd, 3rd, Continental Nights — per department |
| **Task lists** | The actual tasks, per area and shift |
| **People & roles** | Who is an HOD |

### Changing the tasks on a checklist

Admin → **Task lists** → **Edit tasks** on the row you want.

From there you can change the wording, reorder tasks, add or remove them, and
for repeating tasks add or remove the time slots (9am, Hr 1, and so on). The
hours on the Dispatch grid are just checkpoints on a task — add a thirteenth
hour and a thirteenth column appears.

> **Important:** editing a task list changes it for checklists **from now on**
> and for any in-progress checklist using it. Checklists already completed keep
> the tasks they were filled in against.
>
> If you're making a substantial change, use **New version** instead. That
> copies the list, makes the copy current, and leaves the old one attached to
> the checklists that used it.

### Adding a new area

Admin → **Areas** → add it, then Admin → **Task lists** → create a task list
for that area and each shift, then add the tasks. Until a task list exists,
opening that area tells you no checklist is set up yet.

### Someone's number is showing instead of their name

Admin → **People & roles**. The page tells you which account you're signed in
on. Put that number in the **Account name** column against the person's row and
save. Their real name then shows everywhere, and is stamped on everything they
answer.

To make someone an HOD, add them with the role **HOD** — their name must match
Active Directory, or link their account number as above.

---

## 11. If something goes wrong

**"Only an HOD can sign a checklist off"** — you aren't recognised as an HOD.
Either an HOD needs to complete it, or an admin needs to add you at Admin →
People & roles.

**"This check is the HOD's to answer"** — one of the four HOD-only Dispatch
checks. Leave it for an HOD.

**"Notes are required for an Issue"** — write the note; the issue isn't saved
until you do.

**A check won't save** — the message appears under the task in red. Most often
the network dropped briefly. Tap the answer again. Nothing is lost: only the
answers that actually reached the database are counted as saved, so anything
that failed will show as unanswered rather than silently disappearing.

**"No current task list is set up for this area and shift"** — nobody has built
the checklist for that combination yet. Admin → Task lists.

---

*Support Audit System — Rittal. Safe Start checklists, reference SHEF014.*
