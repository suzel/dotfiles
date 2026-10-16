---
name: sdd
disable-model-invocation: true
description: >
  Spec-driven development for large or multi-module work. Write a capability map and one
  spec per module before any code. Use when the user starts a new project or a feature that
  spans several modules or takes more than about 30 minutes, or says "spec", "sdd" or
  "capability map". Skip for typo fixes and single-file changes with clear requirements.
---

<skill name="sdd">

<objective>
Write the spec before the code. The spec is the contract between you and the user: what is
built, why, and how "done" is judged. Plans and code never go into it.
</objective>

<layout>
```
specs/
  MAP.md                # one per project
  <module-id>/
    SPEC.md             # approved contract, changes only on purpose
    TASKS.md            # plan + checklist, changes with every task
```
Module ids are kebab-case and stable. If the project already has a spec system (OpenSpec,
Spec Kit), keep its format and storage and follow only the rules below.
</layout>

<rules priority="critical">
1. **Two approval gates only:** `MAP.md` and each `SPEC.md`. After writing one, summarize it,
   list open questions, ask for approval and **end the turn**. Do not write the next artifact in
   the same turn. `TASKS.md` and implementation run without stopping to check in.
2. **Spec says what, never how.** No technical approach, no task list. Those belong in `TASKS.md`.
3. **Do not repeat what the repo already states** (code style, commands in README/CLAUDE.md).
   Link to it.
4. **Spec changes before code changes.** Edit `SPEC.md` only for a deliberate scope or decision
   change, and say so. Ticking tasks touches `TASKS.md` only.
5. **Assumptions first.** List them and ask for corrections before writing a spec.
6. **Single-module work:** skip `MAP.md`, write one `SPEC.md` and `TASKS.md`.
</rules>

<workflow>
0. **Map** (only if the request holds several independently shippable capabilities). Write
   `specs/MAP.md`: a table of `id | responsibility | depends_on | status | order`. Dependencies
   point one way. Modules that depend on each other get merged. Status is `draft`, `approved`,
   `in-progress` or `done`. Gate: user approves the map.
1. **Specify**, per module in `order`. Write `specs/<id>/SPEC.md` from the template below.
   Gate: user approves the spec.
2. **Tasks.** Write `specs/<id>/TASKS.md` and continue without asking.
3. **Implement** one task at a time, run its `verify`, tick it off.
4. **Close.** Every `SC-n` must be covered by a done task whose `verify` passed. Report any
   uncovered criterion. Then set the module to `done` in `MAP.md`.

Work one module at a time: steps 1-4 finish for a module before the next module's spec is
written. Later modules stay `draft` with only their `MAP.md` row.

Context: load `MAP.md`, the current module's `SPEC.md` and `TASKS.md`, and only the `Interfaces`
section of its `depends_on` modules.
</workflow>

<spec_template>
```markdown
---
id: <module-id>
depends_on: []
---

# <Title>

## Objective
What, why, for whom. 2-4 sentences.

## Success criteria
<!-- EARS: When/While/If…then/Where … the system shall … Write numeric thresholds directly. -->
- SC-1: ...

## Out of scope
- ...

## Interfaces
<!-- Only with several modules. Use module ids. -->
- Provides: ...
- Consumes: <id>.<name>

## Boundaries
- Always: ...
- Ask first: ...
- Never: ...

## Decisions
<!-- Optional. One line each: decision, reason. -->

## Open questions
- ...
```
</spec_template>

<tasks_template>
```markdown
# Plan
Order, risks, checkpoints. A few lines.

# Tasks
- [ ] T1 <description>
  - covers: SC-1
  - acceptance: ...
  - verify: <exact command>
  - files: ...
```
A task fits one focused session and touches about five files or fewer. Order by dependency.
</tasks_template>

</skill>
