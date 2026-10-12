# Phase 3 · Verify — AFK

**Goal**: mechanical proof that the change works, before any human judgement is
spent on it. Reviewers should never be the ones to discover a type error.

Two independent things happen here and neither substitutes for the other:
the machine checks (3.1) and the empirical check (3.2).

## 3.1 Mechanical gates — Loop B

1. **`/verification-loop`** on the slice; it wraps `/ci` in Gate 11.
2. **`/ci`** — `pnpm run ci`: typecheck, lint, format, unit tests, build. Fix
   the cause, not the symptom. Max 3 rounds.
3. **Conditional sync checks CI does not do for you**, by touched area:

   | If you touched            | Prove                                                                      |
   | ------------------------- | -------------------------------------------------------------------------- |
   | API schemas / routes      | both `openapi.json` copies regenerated and committed together (`/openapi`) |
   | A migration               | `up → rollback → up` passes locally                                        |
   | `schema.zed`              | `zed validate` passes                                                      |
   | UI strings                | the key exists in **both** `en.json` and `de.json`                         |
   | A feature flag            | created OFF in staging **and** prod                                        |
   | An env var                | present in **every** consuming app's `env.ts`                              |
   | Anything service-touching | integration tests run **locally** — CI only runs them in the merge train   |

4. **The test plan's Must rows all have a passing test.** Walk the plan and mark
   each row: passing / missing / deliberately deferred. A missing Must row is a red
   gate, not a note.

Never make a check pass by weakening it. Deleting an assertion, loosening a
type, adding a skip, or widening a threshold to reach green is a blocking
violation and gets reported as one.

## 3.2 Empirical verification — `/verify-loop`

Run `/verify-loop` against the **Definition of Done from the spec**. It brings
the instance up, drives the real app in a browser, screenshots each DoD item,
checks console and network, fixes the unambiguous, and stops on its own rules.

Use `chrome-devtools-fast` when only you need to see it; escalate to
`chrome-devtools-headless` for anything requiring clicks, console, network, or
a viewport change. Headed only when the user will actually look at the window —
and note that both headless servers run isolated, so **authenticated Studio and
Chat routes need the headed server**.

Prefer `evaluate` over a screenshot where a computed value answers the question:
it is cheaper and it can be asserted on.

Delegate the loop as a **Sonnet** subagent — it executes against a criterion the
spec already fixed, and `~/project-workspace/.claude/CLAUDE.md` § "Browser
verification" covers why that is safe while a judging reviewer is not. Then run
the loop's **Step 6**: post the report
and its uploaded screenshots as one note on the MR. Evidence that lives only in
this session cannot be weighed at Gate 3, and this is a pipeline whose whole
premise is that a "done" claim carries proof.

### The items the loop cannot check

Migration rollback, queue idempotency under real re-delivery, cron behaviour,
cache invalidation, alerting. `/verify-loop` will flag them as
not-browser-checkable. **Prove them here by hand and state how.** This is the
most common place for a "done" claim to be quietly untrue.

## 3.3 Holdouts — the checks the implementer never saw

The contract tests catch an edited test. They cannot catch code special-cased to the inputs
those tests use. The holdouts can, because the implementer never saw them.

Spawn the **verifier** (`roles.md`): a Sonnet agent running `/verify-loop --report-only`
with the lines from `Tasks/<slug>/sealed/holdouts.md` and the app URL, nothing else. Report-only
means the loop records and never fixes: a verifier that fixes code has become a second
implementer that read the holdouts. Backend holdouts the browser cannot reach (rows written,
ReBAC allow/deny) run as a script or SQL query by the orchestrator, output pasted.

A failing holdout goes to the implementer as the failing observable only — `expected X, saw Y
at <url>` — then back through the guard and this step. Loop G: budget 3 rounds; the same
holdout failing twice after a fix stops the loop and goes to the owner.

## 3.4 Output

A verification report listing, per DoD item: the evidence (command output,
screenshot path, or computed value), and pass / fail / not-verified. The word
"should" is not evidence. A DoD item with no evidence is `not-verified`, and
`not-verified` is a failure — fail closed.

## Exit

All green → Phase 4 when the plan names a reference, else Phase 5. Non-converged loop → report per `doctrine/loops.md`.
