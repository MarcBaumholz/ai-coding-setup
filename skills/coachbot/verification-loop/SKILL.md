---
name: verification-loop
description: "The pre-review gate: run after implementing and before /full-review — replaces /quality-gates. Self-check loop over a finished change: prove the diff is complete, in scope, simple, well-structured, actually tested, mechanically green (typecheck/lint/format/targeted-tests/sync-checks), and free of a mistake already in MISTAKES.md — then fix and re-run until the gates are green or a stop rule fires. One agent, one checklist, no fan-out. Use after implementing a change and whenever the user says: verification loop, verifikations-loop, check my change, is this good code, can this be simplified, is this out of scope, is this too big, self-check, bin ich fertig, pruefe das durch, quality gates, run the quality gate pipeline, mandatory pre-MR pipeline. Do not use to prove observable behaviour in a browser — use verify-loop; nor as a replacement for the multi-reviewer panel — use full-review after this; nor for the typecheck/lint/test pipeline alone — use ci."
version: 0.1.0
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Verification loop

The pass you run on **your own** work, before you spend tokens asking other agents
about it. It answers one question in rounds: _is this change good enough by Marc's
standards, and if not, what exactly is wrong?_

Distilled from `/ponytail review`, `/thermo-nuclear-code-quality-review`,
`mattpocock-skills:code-review`, `/felix-dev-patterns`, and `MISTAKES.md`.

## Where it sits

| Skill                   | Does                                                            | Relationship                                                            |
| ----------------------- | --------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `/ci`                   | typecheck · lint · format · tests                                | Invoked here, by Gate 11 — not a separate pre-step to run first.        |
| **this skill**          | one agent walks 11 gates, fixes, re-runs                         | The cheap converging loop. ~1 agent, minutes. Replaces `/quality-gates`. |
| `/verify-loop`          | drives the real app in a browser against the DoD                | **Behaviour**. This skill judges the code; that one proves the feature. |
| `/full-review`          | ~11 parallel reviewers, ranked findings, ship/fix/block verdict | **Runs after** this. Don't send it work this loop would have caught.    |
| `/second-opinion`       | fresh agent, no context, judges intent not implementation       | **Runs after that**, when "is this the right solution?" is still open.  |

Deliberate overlap: this loop asks the same questions the panel asks, cheaply and
serially, so the panel's expensive parallel lenses are spent on what a single careful
pass cannot see (cross-model disagreement, security, ReBAC, a11y, DB plans).

## The hard gate: no scope statement, no loop

Write these three lines before round 1. If any would be a guess, ask instead.

```
ASK        — what was actually requested, in the requester's words (quote the ticket/prompt)
DONE-WHEN  — the observable outcomes that define finished (numbered, each checkable)
NOT-DOING  — the explicit non-goals
```

Source order: Linear issue → `~/project-workspace/Tasks/<slug>/plan.md` → MR
description → the user's message in this session. **Re-read the original requirement
verbatim** — a constraint already stated there outranks any preference of yours, and
presenting a choice it already answers is a documented past mistake.

Without `ASK`/`NOT-DOING` there is no way to judge scope, and Gate 2 becomes theatre.

## Round 0 — Pin the diff

```bash
cd <the worktree the change lives in>   # not the main checkout, unless that is the one
BASE=$(git merge-base HEAD origin/dev)  # the branch point; never the moving origin/dev tip
git --no-pager diff --stat "$BASE"      # committed on this branch
git --no-pager diff --stat              # unstaged
git --no-pager diff --cached --stat     # staged
git status --porcelain | grep '^??'     # untracked — read the LINES, not the count
```

The target is the union of all four. Note the totals: **files changed** and
**net lines**. Both are judged later.

Then run the mechanical script once — it decides the decidable half of the gates in
~40s and tells you where to spend the reading:

```bash
G=~/project-workspace/.claude/skills/verification-loop/gates.sh
$G                # static gates + the existing design/a11y/i18n/collision scripts, ~40s
$G --tests        # + lint · check · test scoped to the touched workspaces
$G --coverage     # + per-changed-file coverage % (implies --tests)
$G --deep         # + cycles · dead exports · complexity · red-test · migration round-trip
```

`gates.sh` judges the tree it is run from and pins any base you pass to its merge-base
with `HEAD`, so run it from the worktree under review. Afterwards read
`git status --porcelain`: `--deep` runs `red-test.sh`, which rewrites tracked files.

Default every round. `--tests` once the static gates are green, `--coverage` before the
verdict, `--deep` before an MR or on anything touching migrations.

If the tree holds changes you did not write (another session, another worktree),
stop and report the volume — never `git checkout --`, `git reset`, or a bare
`git stash`. Park narrowly: `git stash push -m "<whose, what, why>" -- <paths>`.

---

# The eleven gates

Each gate: what it asks · how it is checked · what fails it. A gate is **green**,
**failed** (must fix), or **noted** (deliberate, justified in one line). "Not
measurable — `<tool>` not installed" is a legitimate result; "assumed fine" is not.

| Gates | Read when | File |
| --- | --- | --- |
| 1 Completeness · 2 Scope · 3 Simplicity · 4 Structure · 5 Not breaking | every round, in order | [references/gates-1-5.md](references/gates-1-5.md) |
| 6 Tests · 7 Mistake replay · 8 Self-critique · 9/9b Design, a11y, browser · 10 Parallel work · 11 Pipeline | every round, in order; 9/9b only if the diff touches UI | [references/gates-6-11.md](references/gates-6-11.md) |

---

# The loop

```
round n:  run gates 1–8  →  classify findings  →  fix the unambiguous  →  round n+1 on the affected gates only
```

**Fix in-loop** when the cause is unambiguous from the evidence: a missing `de.json`
key, an untracked file, a double log, a dead branch, a `yagni:` inlining, an extracted
helper, a missing regression test. Apply it, re-run **that gate only**, continue.

**Do not fix in-loop** — escalate to the user: anything in `NOT-DOING`, a public
contract change, a migration rewrite, a structural reframing that touches files you
do not own, or a finding where you are genuinely unsure. Say you are unsure; never
self-approve past it.

**Ownership** still applies: fix only inside the paths this change owns. Shared and
generated artifacts (both `openapi.json`, `schema.zed`, `turbo.json`, migrations,
`CLAUDE.md`) are edited by the orchestrator, not mid-loop. Outside your area, run
`~/.claude/scripts/wt-files.sh <path>` first.

## Stop rules — the loop ends when any fires

1. All gates green or noted-with-justification.
2. **The same finding survives two fix attempts** — stop, report it as unresolved
   with both attempts. Do not try a third variation.
3. **5 rounds.** Report state, name what is still red.
4. A decision only Marc can make (scope, contract, trade-off).
5. Round n produced no fixes and no new findings — converged.
6. The change turned out to need a redesign, not a fix. Stop and say so — that is a
   `/second-opinion` or `/brainstorming` moment, not another round.

Never loop silently. Each round emits one line per gate.

**A gate you do not run stays in the table.** Its State cell reads `skip:` plus the reason —
`skip: no UI in this diff`, `skip: red-test needs a clean tree`, `skip: no migration`. Never
delete the row and never leave the cell blank. A skipped gate that vanishes is
indistinguishable from a gate that passed, and that is exactly how the red-test rule reached
0-of-25 compliance while the doctrine called it mandatory. The reason is the whole value: a
skip with a real precondition behind it is fine, a skip you cannot name is a finding.

## Rationalisations — the sentence that defeats each gate

Every gate here has one excuse that turns it off, and the excuse always arrives as a
reasonable thought. When you catch yourself thinking the left column, the right column
is the answer. No exceptions, and rephrasing the excuse does not make it a new one.

| The thought | The answer |
| --- | --- |
| "Should be green now" | Then run it. Confidence is rung 1, and rung 1 carries the word `unproven`. |
| "`pnpm check` passed, so it builds" | A type check is not a build and a lint is not a compile. Different command, different gate. |
| "Tests passed on the last round" | A fresh run in this round, or the cell reads `skip:` with the reason. |
| "The test is obviously right, skipping red-test" | Red-test exists because obviously-right tests scored 0-of-25. Revert the source or write `not tested, because X`. |
| "That gate does not really apply here" | Then the row says `skip:` plus the precondition. A skip you cannot name is a finding. |
| "The subagent reported it fixed" | Read the diff yourself. An agent's success report is rung 1. |
| "It is just a comment / just formatting" | Gate 2 is scope. Just-anything still has to be in the commit it belongs to. |
| "One more variation will fix it" | Stop rule 2 fired at two. A third variation is the loop running silently. |

No expression of satisfaction before the evidence. "Done", "clean", "all green" and
"perfect" are claims, and a claim without its command is rung 1 regardless of tone.

## Verdict

| Verdict          | When                                                                                                                                                                                                      |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **SHIP** ✅      | Gates 1, 2, 5, 6, 7, 11 green. Gate 3/4 findings noted and optional.                                                                                                                                      |
| **FIX-FIRST** ⚠️ | An incomplete branch, a scope violation, a broken guardrail (missing server gate, unmasked PII, breaking change with no coexistence path), an unmutation-checked new test, a repeated documented mistake. |
| **BLOCK** 🛑     | A correctness or security defect, a new dependency cycle, or a structural regression the change cannot carry.                                                                                             |
| **RETHINK** 🔄   | Stop rule 6. The implementation is fine and the approach is wrong.                                                                                                                                        |

Quality findings never block on their own. A `SHIP` with 300 deletable lines listed
is a legitimate outcome — it is Marc's call whether to take them.

## Report

```
## Verification loop — round <n> · <verdict>

ASK: <one line>            NOT-DOING: <one line>
Diff: <F> files · +<A>/-<D> · net <N>

| Gate | State | Finding |
| ---- | ----- | ------- |
| 1 Completeness | ✅ / ⚠️ | ... |
| 2 Scope        | ... | missing / extra / wrong |
| 3 Simplicity   | ... | net: -N lines possible |
| 4 Structure    | ... | ... |
| 5 Not breaking | ... | ... |
| 6 Tests        | ... | mutation-checked: yes/no |
| 7 Mistake replay | ... | rule <X> — hit / clear |
| 8 Self-critique  | ... | ... |
| 9 Design + a11y  | ... | design-audit categories · new axe violations |
| 9b Browser evidence | ... | N screenshots / blocked: <why> / none |
| 10 Parallel work | ... | dirty collision / ordinary rebase / clear |
| 11 Mechanical pipeline | ... | /ci status · flag/Dockerfile/CI-yaml checks |

### Fixed this round
- <file:line> — <what> — re-verified by <command / gate>

### Unresolved
- <finding> — <why not fixed> — <who decides>

### Evidence
| Check | Command | Result | Rung |
| ----- | ------- | ------ | ---- |
<!-- Rung per CLAUDE.md: 5 reproduced in app · 4 ran it · 3 bad case impossible
     · 2 pointed at the line · 1 said so. Below 4 the Result cell says `unproven`. -->


### Risk left
<remaining risk · untested scenarios · assumptions · rollback>

### Needs Marc's eyes, ranked
<authorization boundaries → state mutation & migrations → complex business rules
 → external integrations → concurrency/idempotency → architecture exceptions>
```

Every row in **Evidence** names a command that actually ran, with its real result.
No claim in the report may rest on an assertion.

## Handoff

`SHIP` → follow the pre-MR chain in `~/project-workspace/.claude/CLAUDE.md`
("Before any MR: /verification-loop, then /full-review, then the hand-off"), then
`/create-mr` for the MR itself.
`FIX-FIRST` / `BLOCK` → fix, run this loop again from Round 0.
`RETHINK` → `/second-opinion` or `/brainstorming`.
