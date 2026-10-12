# Phase 6 · QA stress — AFK, iterate until converged

**Goal**: find what a real user does that we did not think of, in a real
browser, and fix it — repeating until the feature stops producing new
user-facing breaks.

Phase 3 proved the feature does what the spec says. This phase asks what happens
when someone does something else.

## 6.1 Think as the user first, not as the tester

Before spawning anything, write the user's session in your own words. Not test
cases — a story. For a coach creator in Studio: they open the feature with an
unclear goal, they try the obvious thing, it half-works, they retry, they leave
mid-flow and come back tomorrow, they do it on a laptop with a flaky connection
while a colleague edits the same coach.

Then ask the three questions that generate the good lanes:

1. **What would they naturally try that we never implemented?**
2. **Where would they be interrupted, and what state does that leave behind?**
3. **What would they submit that we did not anticipate?** (the wrong file type,
   200 MB, an empty one, one full of prompt-injection text, the same one twice)

These become concrete lane steps. Grounding the lanes in a plausible session is
what separates a QA pass from clicking every button.

## 6.2 Run `/stress-test`

Hand it the feature and let it do what it is built for: write the
product-grounded charter, pick lanes from its `LANES.md` (job-to-be-done,
boundaries, cross-surface consistency, lifecycle, permissions, resilience,
adversarial content), fan out one `qa-explorer` per lane in parallel, verify the
findings itself, and return a ranked report plus a hardening backlog.

Feed it two extra inputs this pipeline has and it does not:

- The **adversarial rows from the Phase 1 test catalogue** that no automated test
  covers.
- The **threat model from the Phase 1 plan** — every trust boundary deserves one lane
  that crosses it with a hostile payload.

Its own rules apply and are worth restating because they are the ones that make
a QA report trustworthy: a lane reporting "works correctly" with no evidence
counts as **not run**, and seven clean lanes means the environment was broken or
the lanes were too timid — say which.

## 6.3 The fix loop — Loop D

For each finding, in severity order:

1. **Reproduce it yourself** before fixing. An unreproduced finding is a
   hypothesis; fixing hypotheses is how phantom complexity enters a codebase.
2. Fix P0 and P1. Log P2 and questions to the hardening backlog with a ticket.
3. **Add a regression test** at the lowest layer that would have caught it. A
   browser bug fixed without a unit or integration test comes back.
4. Re-run Phase 3.1, then **re-run the lane that found it plus every lane that
   touches the changed code** — not just the failing lane.

**Converged** = two consecutive rounds with no new P0/P1. Budget: 4 rounds.

Use the severity scale from `/stress-test`'s `LANES.md` — **P0 / P1 / P2 /
question** — never a private one. Note the collision: `P0` in the *test plan*
meant must-pass priority, so the test plan now uses Must/Should/Could and P0-P2
is QA severity only.

A finding whose fix requires a design change does **not** get patched here. It
goes back to Gate 2 with the evidence. Patching a design flaw inside a QA loop
is how a clean architecture becomes a pile of special cases.

## 6.4 Non-browser QA

The lanes cannot reach: queue re-delivery, cron, migration rollback against real
data, cache invalidation, rate limits, alerting. Exercise these by hand here and
state the method and result for each. They are the ones that break in
production precisely because nothing automated looks at them.

## 6.5 The report

Use `templates/qa-report.md`. Four sections:

- **Findings**, ranked, each with severity (P0/P1/P2/question), reproduction steps, evidence
  (screenshot path, console output, network entry), and status (fixed / backlog
  / needs-decision).
- **Fixed this round**, with the regression test that now covers each.
- **Coverage and gaps** — which lanes ran, what they exercised, and **what
  nobody looked at**. This is the section that makes the rest credible.
- **Honest verdict** — would you ship this to a paying customer, and what is the
  worst thing that could still happen.

## Exit

→ **Gate 3** (`gates/gate-3-quality.md`).
