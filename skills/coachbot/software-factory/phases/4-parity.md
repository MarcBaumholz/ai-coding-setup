# Phase 4 · Parity — AFK, loops back to Build

**Goal**: answer "copy this from that" with a number — 31 of 40 rows done, 6 missing, 3 need
your eye — and loop the gaps back into the build until they close. Parity is a diff of two
recorded values per row, never an agent's opinion of how close it looks.

Runs when the plan names a **reference**: a design-lab mock, a prototype, a live route, an
external product page. Skip it otherwise, marked `skip: no reference`. Also standalone:

```
/software-factory parity <reference> <target>     e.g. design-lab/mocks/stage-panel  →  /coaches/[id]/stages
```

Standalone still writes `Tasks/<slug>/` and still ends in the build loop, but enters at 4.1
with no plan doc. A parity ask without a reference path is refused: the reference surface
is named by path or URL, never by description (`MISTAKES.md` 2026-08-17).

```
reference ─► extractor ─► ledger.json (frozen) ─► inspector ─► parity-diff ─┬─ open = 0 ─► Phase 5
                                                     ▲                       │
                                                     └── implementer ◄───────┘ missing / partial rows
```

## 4.1 Extract — round 0, once

Spawn the **extractor** (`qa-explorer`, read-only, `stress-test/ENVIRONMENT.md` for login):

> Drive the running reference at `<url or served mock path>`. Do not look at `<target>`.
> List every thing a user would notice is missing if it were not copied: copy, states,
> interactions, layout, behaviour. For each, write one JSON row
> `{id, type, what, probe, ref, refKind}`: `probe` is an `evaluate` expression, a network
> request to watch, or a read-only SQL query that returns the value; `ref` is what it returned
> on the reference; `refKind` is `mock` for a design-lab or static mock, `live` otherwise.
> A thing you cannot measure is `type: "visual"` with a screenshot path as `ref`.
> Placeholder copy in a mock ("Lorem", invented names) is `type: "visual"`, not `copy`.
> Return the JSON array. For a prototype's behaviour, record what it does when driven
> (input → output); never read its source.

Write it to `Tasks/<slug>/parity/ledger.json` and render `templates/parity-ledger.md` beside
it. **The ledger is frozen from here.** Rows anyone notices later go under "Found later" for
the owner; adding them mid-loop is how a parity loop never ends.

Row types and what counts as evidence:

| Type | Probe returns | Example |
| --- | --- | --- |
| copy | exact string, en and de | button label "Add stage" |
| state | the element's text or presence in loading, empty, error, disabled, focus | empty list shows the hint |
| interaction | the observable after the action | click Save → toast text in a live region |
| layout | a computed value at 375 px and at desktop width | column count, gap, overflow |
| behaviour | request payload or the row written | PATCH body carries `stageId` |
| visual | a screenshot path | anything with no number |

Layout measured on a design-lab mock is always needs-human: the mock's tokens are not the
product's (`coachbot-design/references/artifacts.md`), so its pixels never match by design.
Compare structure there (column count, order, presence), not pixels.

## 4.2 Inspect

Spawn the **inspector** (`qa-explorer`):

> Run each probe in `<ledger.json>` against `<target url>` and fill `target` with what it
> returned, `null` when the element or request is not there. Do not judge, do not read the
> reference's source, do not add rows. Return the completed JSON array.

## 4.3 Diff — code decides

```bash
node ~/project-workspace/.claude/skills/software-factory/scripts/parity-diff.mjs \
  Tasks/<slug>/parity/round-<n>.json --prev Tasks/<slug>/parity/result-<n-1>.json --json \
  > Tasks/<slug>/parity/result-<n>.json
```

Exit 0 = every row done or waived. Paste the summary line into `progress.md`. A row that
was done last round and is not now is a regression: stop and fix that first.

## 4.4 Fix and loop — Loop F

Missing and partial rows go to the **implementer** (`roles.md`) as rows: id, what, probe,
reference value, target value. Not the reference's source. Then the contract guard
(`factory-guard.sh check`) and back to 4.2.

- **Converged**: every row done or waived, and two rounds in a row closed no new gap.
- **Budget**: 4 rounds.
- **Out of budget**: the report lists the open rows, each with both values. The owner waives
  them (`waived: "<reason>"` in the ledger) or extends the budget. Never close a row by
  editing its `ref`.
- needs-human rows go to the owner as a screenshot pair at Gate 3.

## Exit

Converged or reported → Phase 5. The final `parity-diff` summary goes into the Gate 3
report verbatim.
