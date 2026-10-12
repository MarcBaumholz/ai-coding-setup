# Plan doc — <feature>

The outline of `Tasks/<slug>/plan.md` and of the Claude Docs doc built from it. Section order
is fixed: the owner reads top-down and stops when something is wrong, so the things they push
back on most come first. Lead sentence of every section = its point, never "This section…".

Linear: <URL> · Branch: <name> · Slug: `<slug>` · Round: <n of 3>

## Decision needed
| Id | Question | My default and why |
| --- | --- | --- |
Engine disagreements from the second opinion go here as their own question.

## Mock of the end result
UI: the design-lab mock's screenshot + link to the clickable version.
No UI: a drawing of the end state + one realistic sample of what the owner will see.

## Flow
Drawn: trigger → chain of effects → what the user sees. More than ~8 steps: split it.

## Assumptions challenged
| Id | Assumption | Source | Challenged by | Verdict |
| --- | --- | --- | --- | --- |
Source: owner / looked-up `file:line` / my guess. Verdict: held · overturned (what changed) · open.
An empty table blocks Gate 2.

## Scope and Definition of Done
In scope (3-7 bullets) · out of scope (specific, never "everything else").
| # | Action | What is true afterwards |
| --- | --- | --- |
Success metric: one number and its source (PostHog event, Langfuse score, SQL), or the line
`none — enablement/refactor only`.

## Design
Seam · module sketch with interfaces · dependency direction · data (indexes with their
query, transaction boundaries, migration reversibility, masking) · failure and scale ·
authorization and query-level scoping · threat model · observability · rejected alternatives
(≥2) · what `/ponytail` removed · ADR link if hard to reverse. Checklist:
`references/plan/design-checklist.md`.

## Interface sheet
Link to `Tasks/<slug>/interface-sheet.md` (`templates/interface-sheet.md`).

## Test catalogue and slices
Counts by layer and priority, the fail-closed list, the numeric gates. Holdouts: the count
only, never the cases. Slice order: each slice, what it retires, the paths it owns.

## Critics and second opinion
| Round | Reviewer | Finding | Severity | What changed |
| --- | --- | --- | --- | --- |
Second opinion: reviewer A verdict · reviewer B verdict · where they disagree.

## Risks and not in this change
| Id | Risk | Mitigation |
| --- | --- | --- |
Not in this change: deferred items, each with its follow-up.

## Sources
Every page or file a claim rests on.
