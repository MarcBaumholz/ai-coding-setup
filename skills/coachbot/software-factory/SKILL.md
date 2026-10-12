---
name: software-factory
description: "Ship a CoachBot change that must not break, end-to-end, with separated agents that cannot grade their own work: a premise check and a one-screen scope yes; then a plan doc (Claude Docs) with a mock of the end result, challenged assumptions, design, interface sheet and test catalogue, built by isolated subagents and attacked by critics and a two-engine second opinion before the owner approves it; then a test author writes the contract tests and a different agent implements, with factory-guard.sh failing any edit to those tests; holdout checks the implementer never saw; a parity loop that measures how much of a reference (mock, prototype, live page) has been copied and loops the gaps back; review; adversarial QA. Three owner gates: scope, plan, quality. Use for new features, risky refactors, data or auth changes, and any \"copy this from that\" / reverse-engineer / port-this ask. Triggers on: software factory, ship reliably, build this properly, do this right, end-to-end with tests and QA, zuverlässig bauen, copy this from that, reverse engineer, parity with the mock, wie weit sind wir mit dem Nachbau. Do not use for routine low-risk work — build it directly under before-implementing; nor for a pure design discussion with no code — use brainstorming."
version: 2.0.0
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Software Factory

Agents propose, code and separate agents decide. No agent grades its own work: the test author
is not the implementer, the verifier never saw the code, the parity verdict is a script, and
the plan is attacked by agents that never saw this conversation. The owner decides three
times; everything between runs AFK.

**Not for everything.** A known one-line fix, a config change, a question: answer it directly.
Routine low-risk changes are built under `rules/before-implementing.md`. This skill is for work
that must not break, and for "copy this from that".

```
0  Understand   🟢  orchestrator · code-review-graph, Explore · names the reference, if any
   ★ GATE 1     🔴  premise check + one-screen scope yes, in chat
1  Plan         🟢  blind challenger · mock builder · design + interface sheet · test author
                    (catalogue + sealed holdouts) · plan doc · critics ×2 + second opinion ×2
                    engines · revise until a round is quiet (≤3)
   ★ GATE 2     🔴  owner approves the plan doc (revision recorded)
2  Build        🟢  per slice: test author → contract commit → guard · implementer → guard
3  Verify       🟢  /verification-loop + /ci · /verify-loop on the DoD · holdouts, report-only
4  Parity       🟢  extractor → frozen ledger → inspector → parity-diff → gaps back to 2 (≤4)
5  Review       🟢  /full-review · doctrine pass · security
6  QA stress    🟢  /stress-test as a hostile user, until 2 clean rounds
   ★ GATE 3     🔴  quality verdict: BLOCK · FIX-FIRST · SHIP
7  Ship         🔴🟢 MR → /review-mr → /babysit-mr; the merge is the owner's
```

Loops back: a design flaw found in 2-6 returns to **Gate 2**. A scope change found anywhere
returns to **Gate 1**. Patching a design flaw in place is how a clean architecture becomes a
pile of special cases. Standalone parity: `/software-factory parity <reference> <target>`
enters at Phase 4 (`phases/4-parity.md`).

## Announce every phase

At the start of each phase state its number, whether it is 🟢 AFK or 🔴 HITL, and for AFK
phases roughly how long. Track the phases in the task list, one entry per phase.

**A phase or step you drop stays in the task list**, marked `skip: <reason>` — never deleted
and never silently completed. Same for a step inside a phase. The list is what the user reads
to see what the factory actually did, so a dropped step that disappears turns the list into a
claim of full coverage. A named precondition is a fine reason; not being able to name one is
the finding.

## Read the file when you enter the phase

| Phase | File |
| --- | --- |
| 0 Understand | `phases/0-understand.md` → `gates/gate-1-scope.md` |
| 1 Plan | `phases/1-plan.md` (+ `references/plan/design-checklist.md`, `test-generators.md`) → `gates/gate-2-plan.md` |
| 2 Build | `phases/2-build.md` |
| 3 Verify | `phases/3-verify.md` |
| 4 Parity | `phases/4-parity.md` |
| 5 Review | `phases/5-review.md` |
| 6 QA stress | `phases/6-qa-stress.md` → `gates/gate-3-quality.md` |
| 7 Ship | `phases/7-ship.md` |
| Every subagent | `roles.md` — who sees what, who writes what, the brief to paste |

Do not preload them. Read the phase file, do the phase, write the artefact, move on.

## Separation — the part that makes it a factory

| Mechanism | Stops | Enforced by |
| --- | --- | --- |
| Role contracts: each subagent gets a brief and paths, never this conversation | primed reviewers, leaked design intent | `roles.md`; fresh Agent contexts |
| Test author ≠ implementer; contract commit of tests + inert stubs | the implementer loosening, deleting or skipping its own tests (LOCAL-ISSUE) | `scripts/factory-guard.sh contract` / `check` |
| Holdouts the implementer never sees, run report-only | code special-cased to the visible tests | sealed file; `/verify-loop --report-only` |
| Parity ledger with a probe and two recorded values per row | "looks close enough" | `scripts/parity-diff.mjs` |
| Blind challenger, critics, two-engine second opinion on the plan | an approved plan resting on the orchestrator's unchallenged guesses | `phases/1-plan.md` § 1.2, 1.7; Gate 2 criteria |

Both scripts have self-tests: `bash scripts/factory-guard.test.sh` and
`node --test scripts/parity-diff.test.mjs`. Run them after editing either script.

This is Level 4, not a "dark factory": the owner approves scope, plan and merge, and no
unattended run commits or pushes (`references/doctrine/loops.md`, unattended contract).

## The doctrine

Always in force, referenced by name rather than pasted:

| File | What it governs |
| --- | --- |
| `references/doctrine/house-rules.md` | File/function size, coupling, DRY, naming, comments, errors. Read before Build, enforce in Review. |
| `references/doctrine/coachbot-invariants.md` | What is true about this system. A design violating one is wrong however clean. Read before Gate 2. |
| `references/doctrine/loops.md` | Every loop's convergence test and stop rules (A-G). The fail-closed principle. |
| `references/doctrine/testing-doctrine.md` | Layers, budgets, case generation, test anti-patterns. |
| `references/doctrine/security-doctrine.md` | Threat model template, per-surface checklist, LLM risks. |
| `references/doctrine/ci-cd-doctrine.md` | Pipeline stages, fail-closed rules, rollback, DORA. |
| `references/books/*.md` | Ten books, each with enforceable rules and where it is wrong for a 2026 TypeScript codebase. Used by the critics and the Review doctrine pass. |

## What this delegates to

Never reimplement these; call them.

| Need | Skill or agent |
| --- | --- |
| Grill the remaining decisions | `mattpocock-skills:grilling` |
| Mock of the end result | `/coachbot-design` (`references/artifacts.md`) |
| Plan doc | Claude Docs via the Artifact tool (`quickstart` intent `document`) |
| Critics | `architecture-review` + one area agent (`roles.md`) |
| Unprimed verdict on the plan | `/second-opinion` plan mode (Claude + `codex:codex-rescue`) |
| Simplicity | `/ponytail` |
| Ticket | `/create-issue`; MR via `/create-mr` |
| Area implementation | `.claude/rules/*` auto-load per area; `/migrate`, `/openapi` |
| Mechanical gates | `/verification-loop`, `/ci`, `~/.claude/scripts/red-test.sh` |
| Browser proof, holdouts | `/verify-loop` (holdouts with `--report-only`) |
| Parity extraction and inspection | `qa-explorer` agent |
| Review panel, security | `/full-review`, `/coachbot-security-audit`, `rebac-security-review` |
| Adversarial QA | `/stress-test` |
| MR to merge | `/review-mr`, `/babysit-mr` |
| Session handover | `mattpocock-skills:handoff` |

## The five rules that make it reliable

1. **Decide before you build.** Nothing is generated on top of an unstated assumption. Every
   assumption is a row in the plan doc with who challenged it.
2. **Fail closed.** A check that did not run has proven nothing. Reporting it as "n/a" or
   "should be fine" is the most expensive lie this pipeline can tell; it blocks.
3. **Evidence, not adjectives.** Every "done" carries command output, a screenshot path, or a
   computed value, pasted from the script that produced it.
4. **A clean report is a suspicious report.** Nothing found means the environment was broken
   or the checks were timid. Say which.
5. **Explain it or don't ship it.** Every decision survives a reviewer's challenge: why this,
   why not the alternatives, what breaks if it is wrong.

## Artefacts

All under `~/project-workspace/Tasks/<slug>/`, never an in-repo `tasks/`. Templates in
`templates/`.

```
00-understanding.md  requirement.md  plan.md  plan-review-copy.md  interface-sheet.md
03-test-plan.md      sealed/holdouts.md       second-opinion-{claude,codex}.md
disputes.md          parity/ledger.json  parity/result-<n>.json   07-qa-report.md  progress.md
```

The plan doc (Claude Docs) is the view the owner approves; `plan.md` is its source and what
reviewers read. ADRs live in the repo at `docs/architecture/<topic>.md`, committed with the
change (`references/plan/design-checklist.md` item 10).

`progress.md` is written as you go and survives a `/compact`. **On invocation, check whether
it exists — if it does, read it and re-enter at the recorded phase**, announcing which. A
`progress.md` from v1 (phases 1 Frame … 8 Ship) maps: Frame/Design/Test plan → Plan, 4 → 2,
5 → 3, 6 → 5, 7 → 6, 8 → 7.

## Fan-out ownership

Whenever more than one agent writes: every brief names the paths it **owns** and the paths it
may only **read**; one writer per file; partition by directory or package, never by feature.
Shared and generated artefacts (`openapi.json` ×2, `schema.zed`, `turbo.json`, migrations,
`CLAUDE.md`) are edited only by the orchestrator after rejoin. For the implementer the owned
globs are also passed to `factory-guard.sh check`, which fails any write outside them.

## Harness correction

When a run deviates from a rule, fix the **rule** — this skill, a `.claude/rules/` file, or
`CONTEXT.md` — not only the code in front of you. Append to `MISTAKES.md` the moment a real
mistake is found, with one checkable prevention rule. A run that slid through on thin evidence
gets fixed in the evidence criterion, not in the prompt; a rule the guard could check gets a
case in `factory-guard.test.sh`.
