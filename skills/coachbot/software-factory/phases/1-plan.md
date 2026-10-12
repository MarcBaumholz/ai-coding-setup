# Phase 1 · Plan — AFK, then ★ Gate 2

**Goal**: a plan doc the owner can approve or attack line by line: what it will look like,
what it rests on, how it is built, how it is tested. Most of the factory's time goes here.
A wrong plan built perfectly is the expensive failure; a wrong plan caught here costs a
comment.

Entry: Gate 1 passed (scope yes in chat). Still no implementation code. Types, signatures
and schemas are allowed; they are plan artefacts.

```
requirement.md ──┬─► blind challenger ─────────┐
                 ├─► mock builder ──────────────┤
                 └─► orchestrator: design,      ├─► plan.md ─► plan doc ─► challenge round ─┐
                     interface sheet ──► test   │                 ▲                         │
                     author: catalogue+holdouts ┘                 └──── revise, ≤3 rounds ◄─┘
```

## 1.1 Freeze the requirement

Write the owner's words, verbatim and unedited, to `Tasks/<slug>/requirement.md`. Every
reviewer in this phase reads that file, never your paraphrase. Paraphrase is where your
interpretation enters.

## 1.2 Assumptions — yours, then a blind one

Write your own ledger first, before asking anything: every assumption, including the ones
that feel obvious. Status: LOOKED-UP (cite it) · ASSUMED · CONFIRMED / REJECTED (owner
answered). **A fact is looked up, a decision is asked.**

In parallel, spawn the **blind challenger** (`roles.md`). It sees only the requirement and the
repo. Every assumption only one side listed is a row in the plan doc's assumptions table,
with who challenged it and the verdict: held, overturned, or open.

Then grill (`mattpocock-skills:grilling`) only the decisions still ASSUMED, one at a time,
each with your recommended answer, in this order of cost:

1. Scope boundary — what is explicitly not in this change?
2. Unhappy paths — failure, empty, forbidden, too large, concurrent.
3. Who may do it — roles, project, what a non-permitted user sees.
4. Data — how many, how big, how often.
5. Done — the observable outcome that means it worked.
6. Reversibility — flag, migration down path, kill switch.

If `references/doctrine/coachbot-invariants.md` answers a question, it is LOOKED-UP.

## 1.3 Mock of the end result — always

Spawn the **mock builder** (`roles.md`) as soon as the requirement is frozen; it runs while
you design. UI change: a clickable design-lab mock via `/coachbot-design`, its screenshot
in the doc, the link beside it. No UI: a drawing of the end state plus one realistic sample of
what the owner will see (CLI output, API response, report). The mock section sits at the top
of the plan doc, because it is where the owner pushes back most.

When the mock and the design disagree, the disagreement is a Decision-needed question, not
something you settle quietly.

## 1.4 Design and interface sheet

Work through `references/plan/design-checklist.md`: seam, module sketch, dependency
direction, data, failure and scale, authorization, threat model, observability, rejected
alternatives (at least two), ADR if hard to reverse, provenance block. Then the simplicity
pass: run `/ponytail` over the design itself and record what it removed, or one sentence per
rejected cut.

Write the **interface sheet** (`templates/interface-sheet.md`): every signature, route path,
DOM test id and ARIA name, error shape and i18n key that tests will touch. It is what lets
the test author work without the design rationale. The implementer cannot change it later;
a change is a dispute.

## 1.5 Test catalogue — by the test author

Spawn the **test author, Plan stage** (`roles.md`). It sees spec + interface sheet +
`references/plan/test-generators.md`, not the design. It writes `03-test-plan.md` and returns
the holdouts in its reply; you write those to `Tasks/<slug>/sealed/holdouts.md` and never
name that path to an implementer. Then add the slice order (simplest to most complex, each
slice naming what it retires and the paths it owns).

## 1.6 Write the plan, then the doc

Write `Tasks/<slug>/plan.md` first, following `templates/plan-doc.md`. The file is the
source of truth: it survives a compact and it is what the reviewers read. Then publish it as a
**Claude Docs** doc (Artifact `quickstart` intent `document`, publish with the Docs
`type_url`, outline with one `pending` block per section, then one `update` per section so
the owner can watch it fill). Draw the flow and anything with a shape as a widget
(`guide topic.diagram`), and read each drawing back as a screenshot before moving on.

Fallback: when the plan is mostly a visual mock, an HTML artifact via `/coachbot-design`.

## 1.7 Challenge round — critics and second opinion, in parallel

Cut the "Critics and second opinion" section out of a copy, `plan-review-copy.md`, so no
reviewer sees an earlier round's findings. Spawn in one message, each reading
`requirement.md` and that copy, none seeing another:

- **Two critics** (`roles.md` § Critics). They return findings, never approval; "looks good"
  requires the list of what was checked.
- **`/second-opinion` on the plan**: the Claude reviewer and `codex:codex-rescue` get the
  skill's plan mode. A Codex job may run in the
  background; collect it with `codex-companion.mjs status <job> --wait` then `result <job>`.
  Save both verdicts as `Tasks/<slug>/second-opinion-{claude,codex}.md`.

Reconcile every finding: the plan changes, or a one-line rebuttal is recorded. Verify a
finding against the code before accepting it; a confident reviewer is not evidence. Two
engines disagreeing is a Decision-needed question for the owner, named as such.

## 1.8 Loop until a round is quiet

Re-run 1.7 on the revised plan until a round adds no blocking finding. Budget: 3 rounds.
Each round's findings and what they changed stay visible in the doc. Out of budget with a
block still open → present it as a Decision-needed question, never as resolved.

## 1.9 Leverage check

One sentence before the gate: is there a config change, a deletion, or a doc that gets 80 %
of the outcome? The owner decides; you put it on the table.

## Exit

Sync `plan.md` with any edit the owner made in the doc (read the doc, `sinceRev`). Then
→ **Gate 2** (`gates/gate-2-plan.md`). Record the approved doc revision in `progress.md`.
