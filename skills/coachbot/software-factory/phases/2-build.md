# Phase 2 · Build — AFK, two agents per slice

**Goal**: turn the approved design into code, one thin vertical slice at a time,
simplest first, each slice green before the next begins.

## 2.1 Slice it

Break the work into vertical slices ordered **simplest → most complex**. A slice
is the smallest change that is independently verifiable — not a layer, not a
file. Prefer "one endpoint returns one hardcoded shape end-to-end" as slice 1
over "the whole data layer" as slice 1: the former proves the wiring, which is
where the surprises are.

Order by _risk retired per slice_. The slice that would invalidate the design if
it failed goes first among equals.

The default ladder when nothing forces another order:

```
Slice 1  Skeleton   route returns a hardcoded shape → UI renders it → clickable
Slice 2  Wiring     real migration + repository behind the same shape
Slice 3  Logic      the actual business rules
Slice 4  Edges      errors, empty, loading, permissions, i18n
```

A slice exits only when the thing it added is demonstrably reachable in the running app.
Report the slice number when you come back — "Slice 2 von 4 grün" is state the user can act
on; "am Bauen" is not.

Record the slice list in `~/project-workspace/Tasks/<slug>/progress.md` and
keep it current as you go — this file is what survives a `/compact` and lets the
next session resume without you.

## 2.2 Dependency order within a slice

| Layer        | Contents                                                                              | Local gate                  |
| ------------ | ------------------------------------------------------------------------------------- | --------------------------- |
| 1 · DB       | migration + `SECURITY LABEL` masking for PII                                          | `up → rollback → up` passes |
| 2 · Backend  | types → repository (actor-first, permission check first) → ReBAC → route → `/openapi` | `pnpm check && pnpm lint`   |
| 3 · Worker   | outbox event → dispatcher → processor, `jobId` from the event id                      | processor spec green        |
| 4 · Frontend | page → actions → gating (**with the server twin**) → i18n `en`+`de` → spec            | `pnpm check && pnpm lint`   |
| 5 · DevOps   | env var in every consuming app, CI, PostHog flag created **OFF**                      | `glab ci lint`              |

Build each layer under its area rules — `.claude/rules/*` auto-load per area
(rebac, sveltekit routes, queues, ui-components), in-repo `/migrate` — instead of
reimplementing their rules. UI work routes through `/coachbot-design`; it is the
authority on tokens, variants, and the four-states rule, and it outranks any
generic design skill.

**Never start a layer on a red gate.** Two half-built layers means debugging two
at once.

## 2.3 Contract, then implementation — two agents per slice

The agent that writes a slice's tests never writes its code. In LOCAL-ISSUE one agent did both and
quietly dropped one test-plan row and loosened another; nothing sent either back to a gate.

```
test author ──► contract commit (tests + inert stubs) ──► factory-guard.sh contract ──► GUARD OK
implementer ──► replaces the stubs, may add tests     ──► factory-guard.sh check <sha> <owned globs> ──► GUARD OK
```

1. **Contract.** Spawn the test author with its contract brief (`roles.md`). It writes the
   slice's Must rows as tests plus one inert stub per interface-sheet symbol (marker
   `factory:stub`, wrong value of the right type, never a throw) and commits them alone.
   `factory-guard.sh contract` must print `GUARD OK`: every test loads, runs, and fails on an
   assertion; none passes against the stubs. Paste the line into `progress.md` with the SHA.
2. **Implement.** Spawn the implementer with its brief (`roles.md`): owned globs, the
   contract SHA, no holdouts. Minimum code to pass, no speculative parameters. It may add its
   own tests. A test it believes is wrong becomes a dispute row (`roles.md` § Disputes),
   never an edit.
3. **Guard.** `factory-guard.sh check <contract-sha> '<owned glob>' …` must print
   `GUARD OK`. It fails on any change to a contract test or test infrastructure, any write
   outside the owned globs, any `.only`/`.skip`, and any contract test that does not pass.
   Pre-existing specs the slice had to change are listed as `REVIEW`; carry them to Gate 3.
4. **Refactor** with the tests green, against `references/doctrine/house-rules.md`, then
   re-run the guard.

The guard judges commits, so the tree must be clean. A red guard is a stop, not a retry:
read which check failed. A guard that cannot run is a failure (fail closed).

**When not to split.** A throwaway spike to learn an API, and pure-visual layout where Phase 3's
browser check is the real test. Say which one you invoked in `progress.md`; it never becomes
the default. A one-agent slice is listed as `skip: contract split — <reason>`.

## 2.4 House rules while writing

Read `references/doctrine/house-rules.md` before the first slice, not after the
review. The rules that cost the most when found late:

- Dependency direction (R2) and no logic in route handlers (R3) — structural,
  expensive to unpick.
- Qualified agent ids (N4) — a bare `agentId` is a correctness bug here.
- The server twin for every UI gate (invariant A2).
- Delete rather than layer a fallback beside old code. You have the licence for
  the paths you own; use it.

Every crossed limit gets a one-line justification in the MR. Silence is the
violation, not the crossing.

## 2.5 Fan-out rules

Parallel subagents are allowed **within** a slice, never across slices, and only
when the paths partition cleanly. Every prompt names the paths it owns (may
write) and the paths it may only read. One sole writer per file. Shared and
generated artefacts (`openapi.json` ×2, `schema.zed`, `turbo.json`, migrations,
`CLAUDE.md`) are edited by the orchestrator only, after rejoin. If two subtasks
need to write the same file they are not independent — sequence them or isolate
them in a worktree.

Adding agents to a slice that is already late usually makes it later: the
coordination cost is real and it is paid in merge conflicts. Fan out for breadth
(independent areas), not for speed on one thing.

## 2.6 Per-slice exit

A slice is done when: its Must tests pass, `pnpm check && pnpm lint` are green,
the house rules hold or are justified, and `progress.md` records it. Then the
next slice starts — not before.

## Exit

All slices green → Phase 3.
