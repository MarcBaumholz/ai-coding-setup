# CI/CD doctrine

## Contents

- [Position](#position)
- [The deployment pipeline](#the-deployment-pipeline)
- [Fail-closed rules](#fail-closed-rules)
- [Branch and release policy](#branch-and-release-policy)
- [Observability as a gate](#observability-as-a-gate)
- [Rollback and blast radius](#rollback-and-blast-radius)
- [Pipeline smells](#pipeline-smells)
- [DORA metrics](#dora-metrics)
- [Not yet bootstrapped in this repo (audit 2026-08-03, still true 2026-09-02)](#not-yet-bootstrapped-in-this-repo-audit-2026-08-03-still-true-2026-09-02)
- [Sources](#sources)

## Position

The pipeline is the only opinion that cannot be argued with, so it is where our
standards must live. Humble and Farley's central claim in _Continuous Delivery_ — that
software should be **always releasable**, and that the path from commit to production
should be a single automated, repeatable, auditable pipeline — is not a productivity
optimization; it is a correctness strategy. Small changes, delivered continuously, are
easier to reason about, easier to test, easier to attribute when something breaks, and
cheaper to reverse. The DORA research then supplied the empirical backing: throughput
and stability are not a trade-off. The teams that deploy most often are also the teams
with the lowest change-failure rate, because frequent deployment forces the automation,
the small batches, and the reversibility that make failures rare and cheap.

In an agent-driven factory this matters more, not less. Agents produce diffs faster than
humans can read them, which means the pipeline is doing a growing share of the actual
reviewing. Two consequences follow and they are the spine of this document. First,
**every gate must be able to distinguish "ran and passed" from "did not run", and must
report the second as a failure.** A pipeline that can be green while a check was skipped
is not a quality system, it is a rubber stamp with a CPU bill. Second, **work in
progress lives behind a feature flag on a short-lived branch, not on a long-lived
branch.** Long branches convert small, reviewable changes into a large, unreviewable
merge, which is exactly the failure mode a fast code generator amplifies.

Our concrete flow: short-lived branch → MR to `dev` → `dev` auto-deploys to
`app.example.test` → MR from `dev` to `main` → **manual** production pipeline trigger →
verify in production. Merging to `main` does not ship. Nobody should ever say "it's
merged" and mean "it's live".

## The deployment pipeline

The commit stage must be fast enough that a developer or agent waits for it; the later
stages may be slower but must be automatic. Every stage below is a **gate**: it can
block promotion, and it fails closed.

| Stage                                                      | Gate                                                                                                                                                                                                                                 | Runtime budget                     | On failure                                                                                                                                             |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Pre-commit (local)**                                     | Format, lint on changed files, typecheck the touched package, affected unit tests                                                                                                                                                    | < 60 s                             | Fix locally. Never `--no-verify`; if the hook is wrong, fix the hook in the same MR                                                                    |
| **Commit stage**                                           | `pnpm check` (typecheck all), `pnpm lint`, `pnpm format:check`, full unit tier, build all packages, OpenAPI regenerated-and-unchanged check, migration up/down/up                                                                    | < 10 min                           | Pipeline red. No merge. Fix forward on the branch; do not re-run hoping for a different result                                                         |
| **Integration stage** — **merge train only in this repo** | Vitest integration tier against real Postgres + Redis (+ SpiceDB when authz changed), seeded via the standard seed. Assert the number of tests that ran. **This stage does not run on the MR pipeline** (`.gitlab/ci/quality.yml`), so anything service-touching must be proven **locally** before push — see invariant D4 and Phase 3.1 | < 15 min | In the merge train: red, no merge. Before push: a local run that did not happen is a **fail**, not an n/a. If the DB container failed to come up, that is **red**, not skipped |
| **Acceptance stage**                                       | Deploy to `next`, then browser journeys via chrome-devtools MCP over the critical paths (login, start a coaching session, upload to KB, publish an agent), plus the four-states check on changed surfaces                            | < 20 min                           | Block promotion to `main`. A journey failure is a product failure until proven to be a harness failure, and proving that requires a fix to the harness |
| **Quality/eval stage** (agent, prompt, graph, RAG changes) | `@coachbot/eval-datasets` offline benchmark, gated on `gatedCorrectness`; latency/token/cost budgets; judge-dropout is a blocking reason                                                                                             | < 30 min, nightly + on trigger     | Block promotion. Never wave through as n/a                                                                                                             |
| **Security stage**                                         | Dependency audit (`pnpm audit`, high/critical block), secret scan on the diff, SpiceDB schema diff reviewed when `schema.zed` changed, ReBAC review agent on any route/repository change, EU-AI-Act/PII masking check on new columns | < 10 min, parallel with acceptance | Blocker. A new high-severity dependency CVE blocks the merge or ships with a written, time-boxed exception naming an owner                             |
| **Deploy to `next` (dev tier)**                            | Automatic on merge to `dev`. Migrations applied by the deploy task before the new revision takes traffic; expand/contract means this is safe                                                                                         | < 10 min                           | Automatic rollback of the revision. Migrations do **not** auto-roll-back — that is why they must be backward compatible                                |
| **Deploy to production**                                   | **Manual trigger** on `main`. Requires: `next` green for the change, the flag default known, the rollback plan stated in the MR                                                                                                      | < 15 min                           | Roll back the revision or kill the flag, whichever is faster. Then post-mortem                                                                         |
| **Verify in production**                                   | Smoke the changed journey against `app.example.test`, watch error rate / latency / cost dashboards for the agreed window (default 30 min), confirm the new alert fires on a synthetic trigger                                             | 30 min observation                 | Kill switch first, investigate second. "Verified" means someone looked at the numbers, not that the deploy job exited 0                                |

Two structural rules from Humble & Farley that the table encodes: **build the artifact
once and promote the same artifact through environments** (never rebuild per
environment), and **fail fast** — put the cheapest, most-likely-to-fail checks earliest,
so the 10-minute stage catches what would otherwise waste the 20-minute stage.

## Fail-closed rules

1. **A check that did not run is a FAIL.** Not "n/a", not "skipped", not "will run
   nightly". Every gate reports one of `passed | failed | did-not-run`, and
   `did-not-run` blocks. This covers: a test tier whose database container never came
   up, an LLM judge that errored, a lint step that matched zero files and exited 0, a
   coverage threshold satisfied because coverage was never collected, a Langfuse task
   that was dropped, and a job with `allow_failure: true`.
2. **No green from a partial run.** Gates assert on _counts_, not just exit codes: the
   expected number of test files, cases, eval tasks, and judged samples. A run with
   fewer than expected is red even if every test that ran passed. This is the only
   defence against a silently shrinking suite.
3. **No merge on a red pipeline.** No exceptions, no "the failure is unrelated", no
   admin override. If the failure is genuinely unrelated and blocking everyone, the fix
   is to fix or quarantine the flake on `dev` first — with an issue and an owner — and
   then merge.
4. **No "retry until green".** Re-running a failed job is permitted exactly once, and
   only alongside a filed issue naming the flaky test and an owner. A job that needs two
   retries is a defect report. CI must not be configured to auto-retry test jobs;
   auto-retry converts intermittent production bugs into invisible ones.
5. **No `allow_failure: true` on a quality gate.** If a check is not trustworthy enough
   to block, it is not trustworthy enough to display; delete it or fix it.
6. **No skipping the pipeline.** `[skip ci]`, `--no-verify`, and manual-only quality
   jobs are prohibited on anything that reaches `dev`.
7. **No manual step between build and deploy other than the production trigger.** Any
   other manual step is an undocumented dependency waiting to be forgotten at 2am.
8. **Secrets never enter the pipeline log.** A secret-scan hit on a diff blocks the
   merge and rotates the secret; deleting the commit is not sufficient.

## Branch and release policy

- **Trunk-ish with short-lived branches.** A branch lives hours to two days. If it is
  older than that, it is a merge risk and should be split. Rebase onto the target rather
  than accumulating merge commits (`/rebase`).
- **Feature flags for incomplete work, not long branches.** Incomplete code ships to
  production dark, behind a release toggle, default OFF. This is the mechanism that
  makes short branches possible — Fowler's release toggles exist precisely to decouple
  deploy from release. Our flags live in `FEATURE_FLAGS` in
  `packages/analytics/src/feature-flags.ts`, are created in both PostHog projects, are
  gated server-side authoritatively (UI gating is a nicety), and `LOCAL_FLAG_OVERRIDES`
  is ignored in production by design.
- **Flags are temporary.** Every release toggle carries an owner and a removal date in
  its registry entry. A toggle older than its date is technical debt with a conditional
  attached; removing it is a task, not an aspiration. Permanent operational kill
  switches and ops toggles are a different category and are labelled as such.
- **Conventional Commits, always.** MR titles are squash-merged and feed `git-cliff`
  release notes: `type(scope): lowercase description`, ~70 chars, no trailing period.
  `feat` / `fix` / `perf` appear in release notes; `chore` / `refactor` / `test` /
  `docs` / `build` / `revert` do not. Scope matches the app or package directory. A
  wrong title is a wrong changelog, which is a wrong incident timeline.
- **One MR, one concern.** A diff that mixes a refactor with a behaviour change cannot
  be reviewed and cannot be reverted cleanly. Split it.
- **Progressive delivery for anything risky.** Flag on for internal users → one pilot
  org → percentage rollout → full. Each step has a stated observation window and a
  stated abort condition, decided _before_ the rollout starts.

## Observability as a gate

A feature is not done when it works; it is done when you would find out that it stopped
working. Before "done":

- **Logs.** Structured, at the right boundary: `locals.logger` in routes, `getLogger()`
  in services, `getDbLogger()` in repositories. Every error path logs the detail and
  returns a generic message to the user. Every log line carries the correlation id, the
  actor, the org, and the project — a log you cannot filter to one tenant is a log you
  cannot use during an incident. No PII in log bodies.
- **Traces.** An OpenTelemetry span around every external call (Postgres, Redis,
  SpiceDB, LLM provider, embedding provider) and around the feature's own unit of work,
  with the stated latency budget recorded as a span attribute so the dashboard and the
  code cannot drift apart. LLM calls additionally produce a Langfuse trace with model,
  tokens, cost, and latency.
- **Metrics.** At minimum: request rate, error rate, and p95/p99 latency for the new
  surface; job throughput, failure count, and dead-letter depth for a new queue; token
  and cost per operation for an LLM path. If you cannot name the metric that would move
  when this breaks, you have not finished designing it.
- **One alert with a named owner.** Not a dashboard — an alert, with a threshold derived
  from the budget, a runbook link, and a human's name. An alert nobody owns is a
  notification. Verify it fires: trigger it synthetically once before calling the
  feature done.
- **An SLO for anything user-facing that matters,** with an error budget. Google's error
  budget policy is the model: if the budget for the trailing four-week window is
  exhausted, feature work on that surface stops and reliability work starts, until the
  service is back inside its SLO. The policy's value is that it is agreed in advance, in
  writing, so the decision is not relitigated during an incident.

## Rollback and blast radius

Decide the reversal mechanism **before** deploying, and write it in the MR. Three
mechanisms, in order of preference:

1. **Flag kill switch — seconds, no deploy.** The default for any new behaviour. This is
   the primary reason new work ships behind a flag. Requirement: the OFF path must be
   tested, not merely assumed — there is a test that runs with the flag off, and it runs
   in CI. A kill switch nobody has exercised is a kill switch that fails when used.
2. **Revision rollback — minutes.** Redeploy the previous known-good artifact. Only safe
   if the database is compatible with both versions, which is exactly what expand/
   contract guarantees.
3. **Forward fix — the rest.** Where state has already been written that the old code
   cannot read, or where the rollback itself is riskier than the fix.

**Migration reversibility (expand/contract).** Every migration has a real `down`, and
every schema change is decomposed so that old and new code can run simultaneously:

- _Expand_: add the new nullable column / new table / new index concurrently. Deploy.
- _Migrate_: dual-write both old and new, backfill in resumable batches. Deploy.
- _Contract_: switch reads to the new shape behind a flag, verify, then drop the old
  column in a **later** release, once no deployed code reads it.

Never rename in place, never add `NOT NULL` without a default in one step, never drop a
column in the same release that stops writing it, never take a long exclusive lock on a
large live table (`CREATE INDEX CONCURRENTLY`, batched `UPDATE`s). A destructive
migration is effectively irreversible in production: `down` restores the schema, not the
data. Treat any migration that drops or truncates as requiring an explicit backup
confirmation and a second reviewer.

**Forward-fix vs rollback decision rule.** Roll back when the blast radius is growing,
when the cause is unknown, or when the fix is not already written and tested. Forward-fix
only when _all_ of: the cause is understood, the fix is small and tested, the pipeline is
green and fast, and the current impact is bounded and tolerable for the pipeline's
duration. Under uncertainty, always reverse first and diagnose from the artifact — the
cost of an unnecessary rollback is one deploy; the cost of a wrong forward-fix is a
second incident on top of the first.

**Blast radius sizing, before the deploy.** Who is affected if this is wrong (one org,
one cohort, everyone)? Is bad data _written_ — and if so, is it detectable and
repairable, or silent and permanent? Silent, permanent data corruption is the one
category where the rollout must be slowest and the verification strictest, because no
kill switch un-writes a row.

## Pipeline smells

Recurring failure patterns in the pipeline itself. Each is a defect in the quality
system, and a defect in the quality system outranks a defect in the product, because it
silently disables every other rule in this document.

| Smell                                                     | Why it is dangerous                                                                                      | The fix                                                                                       |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| A job with `allow_failure: true` on a quality check       | Produces a green pipeline over a red check. The most common way a fail-closed policy is quietly repealed | Make it blocking or delete it                                                                 |
| Exit code 0 on zero matched files                         | A lint or test invocation whose glob stopped matching passes forever                                     | Assert on counts; fail when the count is below the expected floor                             |
| Auto-retry on test jobs                                   | Converts an intermittent production bug into an invisible one                                            | Remove auto-retry; one manual retry, with an issue filed                                      |
| Environment-specific rebuilds                             | The artifact tested is not the artifact deployed                                                         | Build once, promote the same artifact                                                         |
| Long-running branch with a "will rebase later" note       | The merge becomes unreviewable and the revert becomes impossible                                         | Split into flagged increments and merge daily                                                 |
| Manual step in the middle of the pipeline                 | An undocumented dependency on one person's memory                                                        | Automate it, or move it to the single production trigger                                      |
| A check that only runs nightly but gates nothing          | Failures accumulate unowned; the report becomes wallpaper                                                | Either gate on it or delete it. An ungated check is documentation                             |
| Migration and code change in separate MRs                 | Breaks the ordering guarantee the deploy relies on                                                       | Ship expand/contract steps as deliberate, ordered releases with the pairing stated in each MR |
| Secrets read from a developer's machine into the pipeline | Unreproducible builds and an unrotatable credential                                                      | Pipeline secrets come from the secret manager only                                            |
| A dashboard where an alert should be                      | Nobody watches dashboards at 3am                                                                         | One alert, one threshold, one named owner, one runbook                                        |

## DORA metrics

The four keys from Forsgren, Humble and Kim's _Accelerate_ and the ongoing DORA / State
of DevOps research — two throughput measures and two stability measures, always read as
a set:

| Metric                              | What we measure                                                                           | Where it comes from                  |
| ----------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------ |
| **Deployment frequency**            | Production deploys per week (the manual `main` trigger)                                   | Pipeline history                     |
| **Lead time for changes**           | First commit on the branch → running in production, median and p90                        | Commit timestamp vs deploy timestamp |
| **Change failure rate**             | Share of production deploys requiring a rollback, kill-switch flip, or hotfix within 24 h | Incident/rollback log, kept honestly |
| **Failed deployment recovery time** | Detection → service restored, median                                                      | Incident log                         |

**Honest caveats.** These are _team_ diagnostics, not individual performance measures,
and the moment they are used for evaluation they stop measuring anything — every one of
them is trivially gameable (split deploys to raise frequency, decline to call incidents
incidents to lower failure rate). They measure delivery _capability_, not product value:
a team can be elite on all four while shipping features nobody wants. Small samples are
noisy — a two-person team's quarterly change-failure rate is one incident away from
looking terrible. Recovery time in particular is dominated by detection, which is why
the observability gate above is upstream of it. And the published benchmark bands move
year to year and vary by context; the useful comparison is your own trend over time, not
the DORA cluster label. Use them to find the constraint — long lead time points at batch
size and pipeline runtime; high change-failure rate points at test and review gates;
slow recovery points at observability and rollback tooling — and then go fix the
constraint, not the number.

## Not yet bootstrapped in this repo (audit 2026-08-03, still true 2026-09-02)

No dependency-cruiser, madge, knip, semgrep, `pnpm audit`, or ESLint complexity rule is wired
into CI; `verification-loop/gates.sh --deep` runs madge/knip ad hoc via npx. Bootstrap order,
cheapest real win first, one `chore(ci):` MR per step, never all at once: dependency-cruiser
(rules `no-circular`, `no-package-to-app`, `no-deep-package-import`) → ESLint `complexity` /
`max-lines-per-function` warn-only → per-package coverage thresholds (`@coachbot/database`,
`@coachbot/permissions`, `@coachbot/agents` first) → knip → `pnpm audit --audit-level=high`
with `allow_failure` until the baseline is clean. Starter configs:
`archive/2026-09-02/skills/code-quality/references/enforcement.md`.

## Sources

- Jez Humble & David Farley, _Continuous Delivery_, Addison-Wesley, 2010 — https://continuousdelivery.com/
- Martin Fowler, "Deployment Pipeline" — https://martinfowler.com/bliki/DeploymentPipeline.html
- Martin Fowler, "Continuous Integration" — https://martinfowler.com/articles/continuousIntegration.html
- Martin Fowler, Software Delivery Guide — https://martinfowler.com/delivery.html
- Pete Hodgson / Martin Fowler, "Feature Toggles (aka Feature Flags)" — https://martinfowler.com/articles/feature-toggles.html
- Nicole Forsgren, Jez Humble, Gene Kim, _Accelerate_, IT Revolution, 2018 — https://itrevolution.com/product/accelerate/
- DORA research program and State of DevOps reports — https://dora.dev/research/
- Google Cloud, "Use Four Keys metrics to measure your DevOps performance" — https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance
- Paul Hammant, Trunk Based Development — https://trunkbaseddevelopment.com/
- Google SRE Workbook, "Error Budget Policy" — https://sre.google/workbook/error-budget-policy/
- Google SRE Workbook, "Implementing SLOs" — https://sre.google/workbook/implementing-slos/
- Conventional Commits specification — https://www.conventionalcommits.org/en/v1.0.0/
- git-cliff, changelog generation from conventional commits — https://git-cliff.org/
- PostgreSQL, `CREATE INDEX CONCURRENTLY` and safe DDL — https://www.postgresql.org/docs/current/sql-createindex.html
