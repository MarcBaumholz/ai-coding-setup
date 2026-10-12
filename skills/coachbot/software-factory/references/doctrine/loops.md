# Loops — how the factory converges instead of spinning

Every autonomous phase in this pipeline is a loop. A loop without a stop rule is
not autonomy, it is a runaway. Every loop below states: the goal, one iteration,
the convergence test, and the stop rules. When a loop stops without converging,
that is a **report to the user**, never a silent pass.

## Contents

- [The universal stop rules](#the-universal-stop-rules)
- [Loop A — Contract, then green, then refactor (Phase 2, per slice)](#loop-a--contract-then-green-then-refactor-phase-2-per-slice)
- [Loop B — Mechanical gates (Phase 3)](#loop-b--mechanical-gates-phase-3)
- [Loop C — Review remediation (Phase 5)](#loop-c--review-remediation-phase-5)
- [Loop D — QA hardening (Phase 6)](#loop-d--qa-hardening-phase-6)
- [Loop E — Discovery until dry (used inside Phases 1 and 6)](#loop-e--discovery-until-dry-used-inside-phases-1-and-6)
- [Loop F — Parity (Phase 4)](#loop-f--parity-phase-4)
- [Loop G — Holdouts and disputes (Phases 2-3)](#loop-g--holdouts-and-disputes-phases-2-3)
- [Anti-loops — patterns that look like progress](#anti-loops--patterns-that-look-like-progress)
- [Writing a contract for an unattended run (/loop, /schedule, overnight)](#writing-a-contract-for-an-unattended-run-loop-schedule-overnight)
- [Reporting a non-converged loop](#reporting-a-non-converged-loop)

## The universal stop rules

A loop halts immediately on any of these, whatever else it was doing:

1. **Converged** — the convergence test passes. Report and continue the pipeline.
2. **Same failure twice** — the identical error survives one fix attempt. Stop.
   Repeating a fix that did not work is how three hours disappear.
3. **Round budget spent** — stated per loop below.
4. **A decision only the user can make** — scope, product behaviour, a
   trade-off with no obviously right answer, anything destructive.
5. **Regression** — a previously green check goes red. Stop, revert the last
   change, report. Never fix forward through a regression inside a loop.
6. **Evidence unavailable** — the check could not run (service down, no
   credentials, browser cannot reach the app). This is a **failure**, not an
   n/a. Fail closed.

Rule 6 is the one that gets violated. A check that did not run has proven
nothing; reporting it as "skipped, looks fine" is the single most expensive lie
this pipeline can tell.

## Loop A — Contract, then green, then refactor (Phase 2, per slice)

- **Goal**: one vertical slice passes its tests and the house rules.
- **Iteration**: the test author commits the failing tests and inert stubs →
  `factory-guard.sh contract` → the implementer writes the minimum code to pass →
  `factory-guard.sh check` → refactor with the tests green → guard again. Two agents; the
  author of the tests never writes the code (`roles.md`).
- **Convergence**: slice tests green, `pnpm check && pnpm lint` green, house-rule
  limits respected or justified.
- **Budget**: 5 rounds per slice.
- **Extra stop**: a test that passes against the inert stubs is a broken test; the contract
  guard refuses it. A red guard is never retried as is: read the failing check.

## Loop B — Mechanical gates (Phase 3)

- **Goal**: `pnpm run ci` green plus the conditional sync checks.
- **Iteration**: run → read the failure verbatim → fix the cause, not the symptom
  → re-run.
- **Convergence**: all green.
- **Budget**: 3 rounds.
- **Extra stop**: never make a check pass by weakening it — deleting an
  assertion, loosening a type, adding a skip, widening a threshold. That is a
  blocking violation, reported as such.

## Loop C — Review remediation (Phase 5)

- **Goal**: no Critical or High finding survives.
- **Iteration**: fix confirmed findings → re-run Loop B → re-run only the
  reviewers whose area changed.
- **Convergence**: zero Critical, zero High, or the user has explicitly accepted
  a High.
- **Budget**: 3 rounds.
- **Extra stop**: disagreement between two reviewers is signal, not noise. Do
  not average it away — surface both positions and let the user pick.

## Loop D — QA hardening (Phase 6)

- **Goal**: no reproducible user-facing break at severity P0/P1.
- **Iteration**: run the lanes → verify each reported break by reproducing it
  yourself → fix P0/P1 → **re-run the lane that found it plus the lanes that
  touch the changed code**, not just the one bug.
- **Convergence**: two consecutive rounds produce no new P0/P1 finding.
- **Budget**: 4 rounds.
- **Extra stop**: a fix that requires a design change goes back to Gate 2, it
  does not get patched inside the QA loop.

The two-consecutive-clean-rounds rule matters: a single clean round after a fix
usually means the lane got lucky, not that the class of bug is gone.

## Loop E — Discovery until dry (used inside Phases 1 and 6)

For open-ended searches — what could break, what cases exist, what an attacker
could do — a count target ("find 10 bugs") stops too early and misses the tail.
Instead: keep generating until **two consecutive rounds surface nothing new**,
deduplicating against everything seen so far (including rejected candidates, or
the loop never terminates).

## Loop F — Parity (Phase 4)

- **Goal**: every ledger row done or waived.
- **Iteration**: inspector fills target values → `parity-diff.mjs` computes verdicts →
  missing and partial rows go to the implementer → guard → inspect again.
- **Convergence**: `parity-diff` exits 0, and two rounds in a row closed no new gap.
- **Budget**: 4 rounds. Out of budget: report the open rows with both values; the owner
  waives or extends.
- **Extra stops**: a row done last round and not now (regression) is fixed before anything
  else. The ledger is frozen after round 0; rows found later go to the owner, never into the
  loop. Never close a row by editing its reference value.

## Loop G — Holdouts and disputes (Phases 2-3)

- **Holdouts**: a failing holdout returns to the implementer as the failing observable only.
  Budget 3 rounds; the same holdout failing twice after a fix stops and goes to the owner.
- **Disputes**: one round trip each (implementer row → test author with the spec → fixed or
  stands). Budget 3 per slice; a fourth means the interface sheet or spec is wrong → Gate 2.

## Anti-loops — patterns that look like progress

| Anti-loop         | Tell                                 | What to do                                   |
| ----------------- | ------------------------------------ | -------------------------------------------- |
| Whack-a-mole      | Each fix breaks something else       | Stop. The design is wrong; return to Gate 2. |
| Green by deletion | Coverage or assertions shrink        | Blocking violation. Revert.                  |
| Retry-until-green | A flaky test passes on the third run | File the flake, treat the run as red.        |
| Widening the net  | Scope grows each round               | Stop. New scope is a new ticket.             |
| Confidence drift  | Later rounds report "should be fine" | Demand the same evidence as round one.       |

## Writing a contract for an unattended run (/loop, /schedule, overnight)

The phases above are loops the factory drives itself, turn by turn. A
different case is handing a task to `/loop` or `/schedule` to run **unattended
across many turns** with no one reading each step. That needs a tighter
contract up front, because nobody is there to catch drift mid-run. Five parts,
all required:

1. **Objective** — one sentence, one concrete outcome. Not a backlog.
2. **Constraints** — what must NOT change: public API, files, libraries,
   conventions. State scope boundaries explicitly ("do not refactor unrelated
   code, do not add dependencies") — an unattended run has nothing else
   stopping scope creep.
3. **Validation command** — the exact shell command that proves progress
   (`pnpm run ci`, a specific test file). The run re-checks against this after
   every change, not against its own judgement.
4. **Stop condition** — verifiable, not vibes: "stop when X passes" or "when
   further progress needs a decision only the user can make." Reuse the
   universal stop rules above (same failure twice, regression, evidence
   unavailable) as the default floor even when the contract doesn't restate
   them.
5. **Anti-gaming clause, stated explicitly** — "do not delete, skip, weaken,
   or narrow a test to make the stop condition pass" and "do not create a new
   ADR" (ADRs require the user's explicit approval per Gate 2 — an unattended
   run must never pre-approve one on its own). This is Loop B's "green by
   deletion" anti-loop, made an explicit instruction because there is no
   reviewer mid-run to catch it.

Keep the objective itself short (a few sentences); if the task needs more
detail, put it in a file (`progress.md` or a task spec) and have the contract
point to it. Long objectives dilute the one thing that matters: the stop
condition.

## Reporting a non-converged loop

State four things, in this order: what the goal was, which stop rule fired, the
exact evidence (command, output, screenshot path), and the smallest decision you
need from the user to continue. Do not bury it under what did work.
