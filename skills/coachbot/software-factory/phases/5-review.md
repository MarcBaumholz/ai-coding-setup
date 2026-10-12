# Phase 5 · Review — AFK

**Goal**: independent judgement on code that already passes its own tests. Tests
prove the code does what you thought; review asks whether what you thought was
right.

## 5.1 The panel

Run **`/full-review`**. It fans out every reviewer in parallel over the diff —
correctness vs spec (`mattpocock-skills:code-review`), over-engineering (`/ponytail review`), structure and
abstraction (`/thermo-nuclear-code-quality-review`), `/felix-dev-patterns`, an
adversarial pass on a different model (via the `codex:codex-rescue` agent; **if the codex plugin is unavailable, skip it and declare the panel single-model in the report** — a panel that is decorrelated in name only is worse than an honest one), plus the
conditional agents by touched area (`backend-review`, `frontend-review`,
`rebac-security-review`, `ux-flow-review`, `database-optimizer`,
`design-review`) — and returns one ranked, deduped report.

Do not substitute a single narrow reviewer. Running only the structure reviewer
leaves security, resilience, migration safety, backwards-compatibility and
accessibility unchecked, and the report will not say so.

## 5.2 The doctrine pass

`/full-review` checks this repo's conventions. Add one agent that checks the
_doctrine_ — the part no existing reviewer covers. Give it the diff plus:

- `references/doctrine/house-rules.md` — the hard limits, with the requirement
  that every crossed limit carries a justification.
- `references/books/clean-code.md` and `books/refactoring-fowler.md` — smells
  and the named move that fixes each.
- `references/books/philosophy-of-software-design.md` — module depth: is any new
  module a shallow pass-through? Did an extraction make things worse?
- `references/books/legacy-code-feathers.md` — did we add code with no seam,
  making the next change harder?

Its output format: `file:line · rule violated · the named refactoring that fixes
it · risk of doing it now`.

## 5.3 Security pass

`/full-review` already spawns `/security-audit` and `rebac-security-review`
conditionally on the touched files. **Do not spawn them again.** This step is a
*checklist read* over their output, plus the LLM/RAG rows no automated reviewer
covers, against `references/doctrine/security-doctrine.md`. If the conditional
agents did not fire because the file signals missed, spawn them now and say so.
Non-negotiable checks:

- Every UI gate has a server-side twin.
- Every new query proves tenant/project scope **in the query**, not only via a
  permission check.
- Every new permission has an allow test and a deny test.
- New PII or user-content columns carry a `SECURITY LABEL` masking rule.
- No `err.message`, id, or SQL in a user-facing message.
- For LLM/RAG surfaces: retrieved content is treated as untrusted input, tool
  agency is bounded, and PII in prompts and traces is accounted for.

## 5.4 Remediate — Loop C

Fix confirmed findings, re-run Phase 3.1, then re-run only the reviewers whose
area changed. Max 3 rounds. Where two reviewers disagree, surface both positions
— the disagreement is the signal, and averaging it away loses the finding.

Never self-approve past a finding you are not confident about. Say you are
unsure and let the user decide; that is cheaper than being wrong quietly.

## 5.5 Optional but recommended — the unprimed opinion

Every reviewer above ran on a prompt you wrote, so the whole panel inherits your
premises: it audits the solution it was handed and never asks whether it is the
right solution. `/second-opinion` hands a fresh agent the requirement verbatim
and has it derive what a correct solution looks like _before_ seeing the code.

Offer it when the panel came back all-minor and that felt too easy, after three
or more iterations on the same code, or before anything hard to reverse.

## Exit

→ Phase 6. Findings and their resolutions go into the Gate 3 report.
