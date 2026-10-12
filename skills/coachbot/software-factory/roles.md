# Roles — who sees what, who writes what

Separation is real only when each role is **denied** something specific. The "must not
see" column is the point of this file. Every subagent gets file paths and the brief below,
never this conversation (the Agent tool starts a fresh context unless you fork it; never
fork for these roles).

## The table

| Role | Agent | Sees | Must not see | Writes |
| --- | --- | --- | --- | --- |
| Orchestrator | main session | everything | — | `Tasks/<slug>/`, the plan doc, shared generated files after rejoin |
| Blind challenger | `general-purpose` | the owner's words, the repo | the orchestrator's assumptions and draft | nothing; its own assumption list |
| Mock builder | `general-purpose` + `/coachbot-design` | the owner's words, `00-understanding.md` | the design draft | the mock (design-lab folder or a doc drawing) |
| Critics, 2 by default | `architecture-review` + one area agent | the plan export, the repo | this conversation, each other | nothing; findings only |
| Second opinion, 2 engines | `/second-opinion` (Claude + `codex:codex-rescue`) | `requirement.md`, the plan export | everything else | nothing; a verdict |
| Test author | `general-purpose` | the pasted Scope + DoD section, interface sheet, test catalogue, repo read-only | `plan.md`: design rationale, rejected alternatives, slice order | the test catalogue and holdouts in its reply (Plan); the contract commit (Build) |
| Implementer | `general-purpose` | spec, design, interface sheet, contract tests read-only | holdouts, the holdout path | source in its owned paths, extra tests, dispute rows |
| Verifier | Sonnet running `/verify-loop --report-only` | holdouts, app URL | the diff, the design | nothing; observations with evidence |
| Parity extractor | `qa-explorer` | the running reference | the target | ledger rows: probe + reference value |
| Parity inspector | `qa-explorer` | the frozen ledger, the running target | reference source code | the target value per row |
| Review, QA | `/full-review`, `/stress-test` | as those skills define | — | as those skills define |

Two critics by default: `architecture-review` plus the one area agent whose paths the change
touches most (`backend-review`, `frontend-review`, `database-optimizer`, `ux-flow-review`,
`rag-review`, `multi-agent-architect`, `prompt-engineer`). Up to five when the change touches
auth, money, migrations or deletion. A critic not run is listed as `skip: <reason>`.

## Briefs

Paste these, fill the angle brackets, add nothing about your own reasoning. A brief that says
what you think the risky part is has primed the role.

### Blind challenger

> Read-only. The owner asked, verbatim: `<Tasks/<slug>/requirement.md>`. The codebase is at
> `<repo>`. List every assumption a builder would have to make to do this: data shape and
> volume, who may do it, what happens on failure, what already exists, what is out of scope.
> For each: is it checkable in the repo (then check it, cite `file:line`), or a decision only
> the owner can make? Return a numbered list. Do not propose a design.

The orchestrator diffs this list against its own ledger. Every assumption only one side
listed becomes a row in the plan doc's assumptions table, marked `challenged by: challenger`.

### Mock builder

> Build a mock of what the owner will see when `<slug>` is done. Requirement:
> `<requirement.md>`. Today's state: `<00-understanding.md>`. UI change: follow
> `/coachbot-design` → `references/artifacts.md` (design-lab mock, `check-prototype` must
> pass) and return the folder path and a screenshot path. No UI: return a drawing spec of the
> end state and one realistic sample of the output (CLI text, API response, report). Every
> name and number invented and marked as such.

### Test author — Plan stage

> You own `Tasks/<slug>/03-test-plan.md`; everything else is read-only. Write the test catalogue for `<slug>` from: the spec below (the plan's "Scope
> and Definition of Done" section, pasted), interface sheet `<Tasks/<slug>/interface-sheet.md>`,
> generators `references/plan/test-generators.md`. Do not open `plan.md` or ask why the design
> is shaped as it is. One row per case: id, case, layer, expected observable,
> Must/Should/Could. Write it to
> `Tasks/<slug>/03-test-plan.md`. Then pick 3-8 behaviour cases a builder would most likely
> satisfy by special-casing, phrase each as `action → observable`, and return them **in your
> reply only** — never in the file, which the implementer reads.

### Test author — contract commit (per slice)

> You own: the test files for slice `<n>` and one stub per interface-sheet symbol the slice
> needs. Read-only: everything else. Write the Must rows of slice `<n>` as tests. Each stub
> carries the comment `factory:stub` and returns a wrong value of the right type (`0`, `''`,
> `[]`, an empty object of the declared shape, or does nothing). A stub never throws: a
> throwing stub turns even `toBeDefined()` red and hides a vacuous test. Commit as
> `test(<scope>): contract for <slice>`. Then run
> `bash ~/project-workspace/.claude/skills/software-factory/scripts/factory-guard.sh contract`
> and fix your tests until it prints `GUARD OK`.

### Implementer (per slice)

> You own: `<globs>`. Read-only: everything else. Make the contract tests of commit
> `<sha>` pass by replacing the `factory:stub` stubs. You may add tests. You may not
> modify, delete or rename any file the contract commit added that is not a stub, nor any
> test infrastructure (configs, setup, fixtures, mocks, test-utils), nor add `.only`/`.skip`.
> If a contract test is wrong, append one row to `Tasks/<slug>/disputes.md`:
> `| <test id> | <file:line> | what the test asserts | why it contradicts the spec, quoting it |`
> and stop work on that test. Finish with
> `factory-guard.sh check <sha> '<glob>' ...` printing `GUARD OK`.

### Verifier

> Report-only: run `/verify-loop --report-only` against these items at `<url>`:
> `<holdout lines>`. Do not read the repository diff. Return per item: pass / fail /
> not-verified, with the evidence (screenshot path or evaluate value).

### Parity extractor and inspector

See `phases/4-parity.md`; both briefs live there with the ledger format.

## Holdouts — where they live

The Plan-stage test author returns them in its reply. The orchestrator writes them to
`~/project-workspace/Tasks/<slug>/sealed/holdouts.md` and never names that path in an
implementer brief. This is a speed bump, not a sandbox: the implementer shares the
filesystem. When a holdout fails, the implementer receives only the failing observable
(`expected X, saw Y at <url>`), never the scenario list.

## Disputes

A dispute row goes to the test author with the spec and nothing else: not the implementer's
code, not the orchestrator's opinion. The answer is one of: test fixed (new contract commit,
guard re-run), or test stands (row closed with the spec line that supports it). Budget:
three disputes per slice. A fourth means the interface sheet or the spec is wrong → back to
Gate 2. Every dispute is listed at Gate 3.
