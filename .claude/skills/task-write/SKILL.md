---
name: task-write
description: Writes clear, implementation-ready GitHub issues for Tarea 5 (Directorio JSONPlaceholder) — a single issue, or an epic with one sub-issue per plan phase — with reuse search, classification, product context, business rules, acceptance criteria, testing strategy and phased deliverables. Use when the user asks to "create an epic", "write the tasks", "turn the plan into issues", "create an issue" or "task-write".
---

# Task Writer

A workflow for creating clear, implementation-ready GitHub issues for **Tarea 5 – Directorio**: a Flutter app (Android first) for the UTESA course *Programación de dispositivos móviles* that lists users from the public JSONPlaceholder API, shows each user's detail and posts, and keeps favorites offline. Stack: Flutter, MVVM by layers with `ChangeNotifier` + `ListenableBuilder` (no Riverpod/Provider), `http` for the network, local SQLite (`sqflite`) for favorites (reusing the Tarea 4 offline-first design). UI in Spanish.

API endpoints:
- `GET https://jsonplaceholder.typicode.com/users`
- `GET https://jsonplaceholder.typicode.com/posts?userId={id}`

## Purpose

Create issues that explain the user outcome, define implementation boundaries, and give developers or AI agents testable instructions. Do not create issues that only list code changes. Every issue should trace back to a numbered requirement of the assignment (1–6).

## Prerequisites

1. `gh auth status` must be authenticated. If not, stop and ask the user to run `gh auth login`.
2. Get the repo with `gh repo view --json nameWithOwner -q .nameWithOwner` (expected: `anicolasp/tarea_5`).
3. Read the source: a plan in `~/.claude/plans/`, pasted text, or an existing finding. Read `AGENTS.md` / `CLAUDE.md` / `ARQUITECTURA.md` if they exist.

## Workflow

### 1. Declare the initial checklist

Before drafting, confirm:

- [ ] Run the Reuse search first and include the real commands and results.
- [ ] Add `## Issue Classification` with all seven required fields.
- [ ] If UX surface is not `none`, include `## UX/UI Spec`.
- [ ] If multi-step flow is `yes`, include `## E2E Flow Required`.
- [ ] If risk is high or network/offline/error handling is central, list `## Unknowns to kill before coding`.
- [ ] For bugfixes and refactors, include `## Fuera de alcance`.
- [ ] If the task comes from an existing finding, include a verified `## Diagnóstico conocido`.
- [ ] Map the issue to the assignment requirement(s) it fulfills.

### 2. Search for reusable functionality first

Search the live code before writing the issue. Check:

- Models and JSON parsing: `lib/data/models/`.
- Network client and exceptions: `lib/data/remote/`.
- SQLite schema and favorites DAO: `lib/data/local/`.
- Repository: `lib/data/user_repository.dart`.
- UI state, ViewModels, screens and shared state views: `lib/ui/`.
- Android permissions: `android/app/src/main/AndroidManifest.xml`.
- Dependencies: `pubspec.yaml`.
- Existing tests: `test/`.
- The Tarea 4 reference implementation of `sqflite` when useful: `~/Desktop/tarjetas_y_pagos/lib/data/database.dart`.

Record the commands and their actual results in `## Additional context`:

```markdown
### Reuse search
- `<command or query>` → `<actual result>`
- Closest implementation: `<file:line>` — <works / does not work and why>
```

Then decide:

- **Exists and works:** request connecting or extending it, and name the file and line.
- **Exists but does not work:** explain why, with a concrete path.
- **Does not exist:** include the search that returned no result.
- **Required dependency or layer is missing:** mark the issue as blocked by the issue that adds it.

Do not claim a search was run unless it actually was.

### 3. Classify the issue first

Put `## Issue Classification` first in the issue body (right after `Parte de #<epic>` when the issue belongs to an epic):

```markdown
## Issue Classification
- **Type:** feature | bugfix | refactor | infra | docs | test
- **Layers:** flutter | sqlite | network | android | docs
- **UX surface:** none | minor | major
- **Multi-step flow:** yes | no
- **Risk:** low | medium | high
- **Offline/network:** yes | no
- **Assignment requirement:** 1 | 2 | 3 | 4 | 5 | 6 (one or more)
```

- **Offline/network:** HTTP calls, timeouts, connectivity errors, offline reads from SQLite.

Classification determines required sections:

- UX surface `minor` or `major` → include `## UX/UI Spec`.
- Multi-step flow `yes` → include `## E2E Flow Required`.
- Risk `high` or Offline/network `yes` → include `## Unknowns to kill before coding` (empty list allowed if none remain, stated explicitly).

### 4. Describe the product context

```markdown
## Product context
**User story:** As a [role], I want [goal] so that [benefit].
**Flow position:** Where this fits (lista de usuarios → detalle + publicaciones → favoritos).
**Assignment requirement:** The numbered requirement(s) this satisfies, quoted briefly.
```

Identify the smallest valuable slice.

### 5. Explain what needs to change

```markdown
## What needs to change
**Current UX:** What the user sees or cannot do today.
**Expected UX:** What the user should be able to do.

**Current code:** Verified current implementation (file:line).
**Expected code:** The intended behavior or integration.
```

### 6. Specify business rules and unresolved decisions

For tasks with logic, state the rules explicitly: parsing, state transitions (`Loading → Success | Empty | Error | Offline`), retry behavior, and side effects. Project invariants to restate when they apply:

- The app must never crash on a network or parsing error; every failure becomes an `Error` or `Offline` UI state with a "Reintentar" action.
- No-internet (`SocketException` / `ClientException`) is shown as a distinct, clear message from other errors.
- Favorites are read only from SQLite and must display with no network.
- ViewModels never call `notifyListeners` after `dispose`.

For pure UI wiring, use:

```markdown
## Business rules: N/A — UI wiring only
```

For a bugfix or refactor, add `## Fuera de alcance`. Name what must not change and why. State that if implementation requires changes outside the agreed scope, the implementer must stop and report.

When the issue is based on another agent's finding, review, or incident, add `## Diagnóstico conocido` and verify every `file:line` reference against live code.

### 7. Lifecycle mapping when relevant

When the issue loads data or owns a screen, add `## Lifecycle` stating which lifecycle hook triggers which load (Flutter `initState` / `AppLifecycleState.resumed` / `paused` / `dispose` ↔ Android `onCreate` / `onResume` / `onPause` / `onDestroy`). Otherwise use `## Lifecycle: N/A`.

### 8. Define database design when needed

If tables, columns, or migrations are involved, document:

- Tables and columns, including SQLite types, nullability, defaults, and primary keys.
- The DB version and `onCreate` / `onUpgrade` steps.
- Model `toJson` / `fromJson` changes in `lib/data/models/`.

If no database changes are needed, use:

```markdown
## Database design: N/A — no schema changes
```

### 9. List files and ownership boundaries

Include 2–5 specific paths in `## Key files to modify`, ordered by importance.

For work that may run in parallel, add `## Exclusive files` with the exact files owned by the issue. If two issues share exclusive files, schedule them sequentially and record the dependency. Avoid vague directory-only lists.

### 10. Write testable acceptance criteria

```markdown
## Acceptance criteria
- [ ] User-visible behavior meets the expected outcome.
- [ ] Loading, empty, error, offline and success states are handled when applicable.
- [ ] The app does not crash when the network is off or the API fails.
- [ ] Relevant edge cases and business rules are verified.
- [ ] `flutter analyze` passes with no issues.
- [ ] `flutter test` passes, with new tests for the added logic.
```

Include at least one user-visible criterion and any relevant offline criterion. Never use vague statements such as "works correctly."

### 11. Define the testing strategy

For tasks with logic, specify:

- **Unit:** models (`fromJson`/`toJson`), ApiClient with `http`'s `MockClient`, ViewModels with a fake repository.
- **DB:** `sqflite_common_ffi` with an in-memory database.
- **Widget:** screens and state views with `flutter_test`.
- **Manual / E2E:** the flow on an Android emulator, including airplane mode; optionally driven with Marionette in a debug build.

For pure UI wiring, use:

```markdown
## Testing strategy: Manual — verify UI wiring on the emulator
```

### 12. Split medium and large work into phases

For medium or larger features, add `## Phased deliverables` with an ordered sequence, a checklist per phase, and a concrete Definition of Done for each phase. For small tasks (1–2 files, under about an hour), one phase is enough.

Typical order for this project: data (models, ApiClient, manifest) → local (sqflite, repository) → UI state + ViewModels → screens + navigation → lifecycle → tests → docs (`ARQUITECTURA.md`).

### 13. Assign the agent and apply labels

Add `## Assigned agent` (default: `claude`). Labels:

- `task` on every sub-issue, plus `fase-N` for its phase.
- `epic` on the epic.
- `bug`, `enhancement` or `documentation` as applicable.

### 14. Add UX/UI specification when required

When UX surface is `minor` or `major`, include `## UX/UI Spec` with:

- Screens affected and how they are reached (bottom nav tab, push from list).
- An ASCII wireframe.
- Initial, loading, empty, error, offline and success states as relevant.
- Interaction logic, navigation, and failure behavior.
- Visual criteria: Material 3, light/dark, small screens, accessibility.
- The `ValueKey` of every interactive element (e.g. `users.item.3`, `detail.favorite`) so Marionette can drive it.
- Exact Spanish microcopy for titles, buttons, empty states, and errors (e.g. "Sin conexión a Internet", "Reintentar").

Omit the entire section when UX surface is `none`.

### 15. Add an E2E flow when required

When Multi-step flow is `yes`, include `## E2E Flow Required` with:

- The user journey as numbered steps, with the expected result of each step (including an airplane-mode step when offline behavior applies).
- Preconditions.
- Specific end-to-end acceptance criteria.
- Setup notes: debug build, Android emulator or device.

Omit the entire section when Multi-step flow is `no`.

### 16. Include additional context

Use `## Additional context` for dependencies (`#issues` that must be merged first, or "None"), scope exclusions, blockers, and reuse-search evidence.

### 17. Right-size the issue

| Size | Scope |
|---|---|
| XS | 1–2 files, under 30 minutes |
| S | 2–4 files, around 30–60 minutes |
| M | 4–8 files, around 1–3 hours |
| L | 8–15 files, around 3–6 hours; must have phased deliverables |
| XL | over 15 files or over 6 hours; split into smaller issues |

Large initiatives belong in an epic. Agents implement the individual issues, not the epic itself.

### 18. Show the draft and wait for approval

Show the user the epic title (if any), the list of issues with size and phase, and one complete issue body. **Do not create anything in GitHub until the user approves.**

### 19. Create the issues in GitHub

1. Create missing labels: `gh label create epic --color 5319e7 -f`, `gh label create task --color 0e8a16 -f`, and `gh label create fase-N --color c5def5 -f` per phase.
2. Write each body to a file in the scratchpad and create the sub-issues first, saving their numbers:
   ```bash
   gh issue create --title "[users]: verb + outcome" --body-file <path> --label "task,fase-1,enhancement"
   ```
3. Create the epic with the epic template and the `epic` label.
4. Edit each sub-issue to add `Parte de #<epic>` as the first line of its body (`gh issue edit N --body-file <path>`).
5. Report the epic link and a `# | title | phase | size` table.

For a single standalone issue, skip the epic steps.

## Epic template

```markdown
## Goal
<product summary in 3–4 lines>

## Assignment requirements
<table: requirement 1–6 → issue(s) that cover it>

## Key decisions
<short table taken from the plan>

## Tasks
- [ ] #N Phase 1 — ...
- [ ] #N Phase 2 — ...

## Workflow
One branch and one PR per task, in order. After the user authorizes the merge, `main` is updated (`git pull`) and the next task is picked.

## Full plan
<plan path or link>
```

## Definition of Done (every sub-issue)

A PR from a `feat/<n>-<slug>` branch that closes the issue (`Closes #N`), is reviewed, and is **merged only with the user's explicit authorization**.

## Final adherence checklist

Before creating the issues, verify:

- [ ] Reuse search ran before drafting and its real results are recorded.
- [ ] `## Issue Classification` is first (after `Parte de #<epic>`) and contains all seven fields.
- [ ] Every assignment requirement 1–6 is covered by at least one issue.
- [ ] Product context explains the user value.
- [ ] Business rules, project invariants and unknowns are explicit.
- [ ] Lifecycle, database design, key files, and exclusive files are included when applicable.
- [ ] Acceptance criteria are specific, testable, and include `flutter analyze` and `flutter test`.
- [ ] Testing strategy is defined.
- [ ] Medium/large tasks have phased deliverables; XL tasks are split.
- [ ] Labels and agent assignment are set.
- [ ] Required UX/UI (with `ValueKey`s and microcopy) and E2E sections are present.

If any required check fails, do not create the issue yet. Complete the missing research or specification first.

## Rules

- **Never merge** PRs or branches without the user's explicit authorization for that specific merge.
- Do not create issues, labels or Projects before the user approves the draft.
- Do not include sensitive or personal data in issues.
