# Test generators — read by the Plan-stage test author

**Goal**: enumerate what must be true, before writing code that makes it true.
Tests are cheap to generate and expensive to get _wrong_, so the scarce resource
is not test count — it is **non-redundant coverage of real failure modes**.

The full method lives in `references/doctrine/testing-doctrine.md`. This phase is
the procedure.

## 1. Derive the case catalogue

Work through every generator below against the design. Use Loop E
(`doctrine/loops.md`): keep going until two consecutive passes surface nothing
new, deduplicating as you go.

| Generator           | Ask                                                                             |
| ------------------- | ------------------------------------------------------------------------------- |
| Happy path          | The one sentence from the DoD, per role that may do it.                         |
| Equivalence classes | What distinct kinds of input exist? One case per class.                         |
| Boundaries          | 0, 1, max, max+1, empty string, empty list, exactly-at-limit.                   |
| Error paths         | Every `throw`, every non-2xx, every rejected promise in the design.             |
| Permissions         | Every role × allow **and** deny. Cross-project access denied.                   |
| Idempotency         | Run it twice. Run it twice concurrently. Replay the queue message.              |
| State machine       | Every legal transition, and at least three illegal ones.                        |
| Persistence         | Survives a reload. Survives a server restart. Correct after rollback.           |
| Time                | Timezone, DST, expiry exactly now, clock skew, ordering under equal timestamps. |
| Content             | Unicode, emoji, RTL, 10k characters, HTML/markdown injection, null bytes.       |
| Scale               | Empty dataset, 1 item, 1000 items, pagination edges.                            |
| Failure injection   | Dependency times out, returns 500, returns malformed data, disk full.           |
| Regression          | Every bug this change is adjacent to that already had a fix.                    |
| Adversarial         | What a hostile user submits — this feeds Phase 6's lanes too.                   |

Write the catalogue to `~/project-workspace/Tasks/<slug>/03-test-plan.md`
via `templates/test-plan.md`. Each row: id, case, layer, expected observable
outcome, priority (Must / Should / Could — deliberately **not** P0/P1/P2, which is QA severity in Phase 6).

Expect 40–120 rows for a real feature. If you have fewer than 20, you have not
run the generators; if you have 400, you are testing the same knowledge many
times — collapse them.

## 2. Assign to layers

Every case gets exactly one home. The wrong layer is worse than no test.

| Layer        | Proves                                                                                              | Must not                        | Tool                                   | Budget                                                       |
| ------------ | --------------------------------------------------------------------------------------------------- | ------------------------------- | -------------------------------------- | ------------------------------------------------------------ |
| Unit         | Pure logic, branching, boundaries, formatting                                                       | Touch DB, network, or the clock | Vitest                                 | milliseconds; the bulk of the catalogue                      |
| Integration  | Repository + real Postgres, ReBAC allow/deny, queue processor idempotency, migration up→rollback→up | Assert on UI text               | Vitest + docker services               | seconds; run locally — CI only runs these in the merge train |
| Browser E2E  | The DoD as a user performs it, the three async states, cross-surface consistency                    | Duplicate unit coverage         | chrome-devtools MCP via `/verify-loop` | one per DoD item                                             |
| Offline eval | LLM/graph behaviour, judged                                                                         | Gate on a raw judge score       | `@coachbot/eval-datasets`              | only if agent behaviour changed                              |

**Deterministic beats semantic wherever the rule is exact.** A substring check, a
traversal assertion, or a status-code assertion is worth more than an LLM judge
for anything with a precise answer. Judges are for fuzzy behaviour only.

## 3. Define the gates numerically

State, in the plan, what green means: which cases are Must, what the mutation- or
branch-coverage expectation is for the new code, what the runtime budget is, and
which checks are **fail-closed** (a check that could not run is a failure, never
an n/a).

## 4. Sanity-check the plan against the anti-patterns

Reject rows that would produce: a test asserting on a mock, a snapshot with no
claim, a test coupled to private structure, a test that still passes if the
feature is deleted, or a test whose failure message would not tell you what
broke. The last one is the best single filter — write the failure message first.

## Exit

→ back to the orchestrator; the catalogue goes into the plan doc and to **Gate 2** (`gates/gate-2-plan.md`).
