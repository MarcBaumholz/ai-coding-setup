---
name: full-review
description: "The one review entry. route.sh picks the reviewers from the changed paths: always greptile-review in its state lens (claims, every file, Greptile's recurring patterns), plus its callers lens on server, data, infra or auth diffs, thermo-nuclear (structure, file size) and a security lens; path-triggered backend, database, frontend, design, ux, devops, rag agents; ponytail above 150 lines or on new files; Codex only on migration/auth/permission paths or in `deep`. Every reviewer runs on Sonnet. Returns ONE ranked, deduped report with a predicted Greptile score and a ship/fix/block verdict. Use whenever the user says: review, review this, review the diff/branch/MR, do a full review, run all reviewers, code review, before push. Review-only — /verification-loop runs the mechanical gates before it. Do not use for typecheck/lint/tests alone — use ci; nor for a verdict unprimed by this conversation — use second-opinion; nor when only over-engineering matters — use ponytail review."
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Full Review — routed, Sonnet, Greptile-shaped

Goal: when the MR is opened, Greptile's one review finds nothing new. Greptile costs a paid
review per push, so the workflow is: review locally → fix → push once → open the MR late.
Every reviewer here runs on **Sonnet**. The orchestrator (you) only routes, dedupes and reports.

## Step 1 — Route

Resolve the actual checkout, target branch, base SHA and reviewed head first. For an MR,
read its target and diff refs; never silently substitute `origin/dev` or the primary checkout.
Capture the route output and non-test line count. Pass the same range and worktree to every
reviewer; flag any runtime substitution. A reviewer that could not run is not a clean review.

```bash
cd <captured-worktree>
bash ~/project-workspace/.claude/skills/full-review/route.sh [base] [--deep]
```

The script prints `run <reviewer> <reason>` and `skip <reviewer> <reason>` lines. Spawn every
`run` line and copy every `skip` line into the report. Do not add or drop a reviewer by
judgement; if the routing is wrong, fix `route.sh` and `route.test.sh`, not this run.
Pass `--deep` for auth, money, migrations, deletion, a published API shape, or when asked.
If the user named files, review only those and say so.

| `run` name | Spawn as |
| --- | --- |
| `greptile-review:state`, `greptile-review:callers` | agent `greptile-review`, one spawn per lens; add to the prompt `Lens: <state|callers>` and `Intent: git log --format='%s%n%b' <base>..HEAD` (plus the `Tasks/` spec if one exists) |
| `thermo-nuclear` | `general-purpose`, loads `skills/thermo-nuclear-code-quality-review/SKILL.md` |
| `ponytail` | `general-purpose`, loads `skills/ponytail/SKILL.md`, review mode |
| `security` | `general-purpose`, loads `skills/security-audit/SKILL.md` in guidance mode and `skills/full-review/references/coachbot-security-checklist.md`; runs alongside ReBAC on server diffs |
| `rebac-security-review`, `backend-review`, `database-optimizer`, `frontend-review`, `design-review`, `ux-flow-review`, `devops-review`, `rag-review` | agent of that name |
| `codex` | agent `codex:codex-rescue`, read-only, `/codex:adversarial-review` scoped to the risk files `route.sh` named (all files in deep). Runtime missing → `skip codex — runtime unavailable` |

Deep also adds `/felix-dev-patterns` (review mode), `architecture-review` and `product-review`.

**Spawn all in ONE message, each with `model: "sonnet"`** (Codex runs its own model). Skill
lenses run inside a `general-purpose` subagent that reads the skill and returns findings only.
Never use the built-in `/review` or `code-review`.

## Step 2 — The spawn prompt

Fill in `<NAME>`:

> Review the captured diff in `<WORKTREE>` against `<BASE_SHA>`, at `<HEAD_SHA>`;
> include staged/unstaged changes once. Use these refs, not another checkout's moving tip.
> Apply the `<NAME>` review only.
>
> **Step 0 — before reading the diff**, write two lines from the touched area alone: what a
> correct change here must do, and what it must not break.
>
> **Step 1 — context from the graph, not whole files.** For each changed exported symbol,
> call `get_review_context_tool` or `get_impact_radius_tool` (code-review-graph MCP,
> `detail_level: minimal`, `max_depth: 1`). Read a full file only when the graph has no entry.
>
> **Step 2 — review.** For each behaviour the change claims to add or fix, name the line that
> wires it in and ask which test goes red if that line is deleted. Wiring with no red test is
> a finding.
>
> **Findings:** `P1|P2 · file:line · <pattern id or one-off> · defect · failure: input → wrong
> result · fix`. P1 = a user, tenant or deploy hits wrong behaviour; P2 = real but contained.
> No finding without a concrete failure. No style nits. Unclear cases go in Not checked.
> A failure you found is a finding even when a comment calls it "Not handled" or a trade-off;
> never file it as a note or under Not checked.
> For each matching pattern, record checked | not checked, with source evidence. On UI
> files, inspect icons and field-error associations in every render arm, including moved
> code. On private-data paths, follow exceptions and traces as well as normal log calls.
> On flags, compare entry points, targeting and unknown/off behavior. On time-based state,
> compare TTL with the actual retry/effective-date horizon and inspect timeout cancellation.
> Do not edit files, do not spawn agents.
>
> **End with:** `Checked:` what you verified and how · `Not checked:` what is in scope but
> unverified, and why. An empty Not checked claims total coverage.

## Step 3 — Consolidate

1. **Dedupe** by `file:line` + defect; note every reviewer that raised it (two = higher confidence).
2. **Verify each P1 yourself** against the code before it reaches the report: does the
   failing input exist on this branch? A reviewer that assumed a callsite gets pushed back
   with the `file:line` that disproves it.
3. **Separate axes:** correctness/security apart from structure/over-engineering.
4. **Union the Not checked lists.** A reviewer without a coverage block did not follow the prompt; say so.
   Keep the evidence rung on every finding: source is rung 2, unproven; a proposed gate
   does not reach rung 4 until its bad-case check runs. Predicted score is not bot acceptance.
5. **An all-clean panel on a non-trivial diff is a spawn or scoping failure until shown
   otherwise.** Check each Checked list names real files before reporting SHIP.

## Step 4 — Report

```
## Review — <N> findings · predicted Greptile <x>/5
Ran: <names> · <skip lines from route.sh>

### Must-fix (P1 correctness / security)
- P1 · file:line · G07 · defect — [greptile-review, backend-review] — rung 2, unproven — fix

### Should-fix (P2)
- P2 · file:line · one-off · defect — [reviewer] — rung 2, unproven — fix

### Structure (thermo / ponytail) — net lines
- file:line — cut or reshape — net: -N

### Not checked
- <area> — <why> — [reviewer]

### Verdict: SHIP | FIX-FIRST | BLOCK — <one line>
Needs Marc (0-3): <question no reviewer can answer — why — file:line>
```

Predicted score: 5 when no P1 is left; 4 when one P1 or three or more P2s; 3 or lower when
several P1s. **BLOCK** on any P1 security/data-loss, **FIX-FIRST** on any other P1, else SHIP.
The verdict is advisory; Marc approves. A conditional verdict says what it is conditional on.

## Step 5 — Fix, then push once

Restate each finding, verify it, YAGNI-check any "do it properly" (grep for the caller), push
back with evidence when it is wrong. Ask about every unclear finding before fixing any. Fix
P1s, re-run only the reviewers whose findings were fixed, then push once and open the MR.
After Greptile's review: `bash .claude/skills/review-mr/greptile-gate.sh <iid>`.
Offer `/second-opinion` when the panel came back all-minor or before anything hard to reverse.

## Step 6 — Record (the Greptile loop reads this)

1. Save the report to `~/project-workspace/Triage/reviews/<YYYY-MM-DD>-<branch with / as ->.md`,
   with the branch name on its first line. The loop matches it to the MR by branch and counts
   mechanical file/line mismatches as escape candidates. Confirm the same defect and that the
   report predates the first bot review before claiming a local-review miss; later reports
   and line proximity cannot measure before-push recall.
2. Append one row to `~/project-workspace/Triage/review-ledger.tsv`:
   `date branch reviewers must_fix should_fix quality needs_marc rejected_by_marc verdict`.
   Fill `rejected_by_marc` on the next turn from Marc's reply; `?` if he did not say.

## Cost

Always 3 Sonnet reviewers (greptile state lens, thermo, security), callers on server, data,
infra/auth paths or >150 source lines; ReBAC also runs on server paths. Design runs on
existing Svelte controls too. These routing additions raise cost; recall benefit is unproven.
Other reviewers remain path-triggered; a docs-only diff runs 1.
Measured cost and recall: `Tasks/greptile-patterns/TUNING-2026-09-30.md`. Pattern maintenance: `greptile/LOOP.md`, run by the scheduled
`greptile-loop` task every three days.
