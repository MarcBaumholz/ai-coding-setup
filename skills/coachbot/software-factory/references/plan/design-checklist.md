# Design checklist — Phase 1 § 1.4

**Goal**: a design that a reviewer can attack before it costs anything to
change. Most pipelines skip this, and it is the reason their code is "clean" at
the line level and wrong at the structure level. Called from `phases/1-plan.md`.

Still no implementation code. Types, schemas and signatures are allowed —
they are design artefacts.

## 1. Produce the design

Write the Design section of `~/project-workspace/Tasks/<slug>/plan.md`
(`templates/plan-doc.md`). It must contain:

1. **The seam** — where does this change enter the system, and what is the
   smallest boundary that contains it? Name the module that owns the new
   responsibility in one sentence with no "and".
2. **Module sketch** — for each new or changed module: its interface (the
   signatures), its responsibility, and what it hides. Judge each against
   _depth_: a module is good when its interface is small relative to the
   functionality behind it. A module whose interface is as large as its
   implementation is a cost with no benefit — delete it and inline.
3. **Dependency direction** — a diagram or an ordered list proving imports flow
   UI → route → service → repository → domain, with no cycles.
4. **Data design** — tables, columns, indexes (each justified by a named query),
   migration reversibility (expand/contract if not trivially reversible), masking
   for PII, and the transaction boundary for every multi-row invariant.
5. **Failure and scale** — expected volume, latency budget, what happens on
   partial failure, idempotency of every write path, retry policy, and where
   backpressure lives.
6. **Authorization** — the ReBAC relations touched, and the _query-level_ tenant
   scoping (invariant I3: a permission check does not isolate projects).
7. **Threat model** — fill the table in `references/doctrine/security-doctrine.md`.
   Assets, actors, trust boundaries, entry points. For anything LLM- or
   upload-adjacent, do the LLM section too.
8. **Observability** — what gets logged, traced, and measured, and which alert
   would tell us this broke in production.
9. **Rejected alternatives** — at least two, each with the reason it lost. A
   design with no rejected alternatives was not designed, it was typed.
10. **ADR** — if the decision is hard to reverse (schema shape, public API
    shape, a new dependency, a new service boundary), write one using
    `templates/adr.md`.

    **An ADR goes into the repo, not into `Tasks/`**: `docs/architecture/<topic>.md`,
    committed with the change that implements it. Everything else this phase
    produces is a task artefact and correctly lives outside git — an ADR is not.
    It is the answer to "why is it built this way" that a teammate, a future
    session, an `Explore` subagent, and the knowledge graphs all need to find
    **from inside the checkout**. In `Tasks/` it is invisible to every one of
    them, and the decision gets silently re-litigated in six weeks.

    `docs/architecture/` already holds `knowledge-retrieval.md`,
    `message-feedback-langfuse.md` and `moderation-scope.md` — match their shape
    rather than inventing a parallel `docs/adr/`. **Read the existing ones before
    designing in an area they cover**, and when this change contradicts one, say
    so in the new file and update the old one in the same MR. A stale ADR is
    worse than a missing one: it is a wrong answer with authority.

**Provenance block, always.** Three short lists so a wrong inference is caught here at the
cost of a sentence instead of a slice: what the user explicitly gave (ticket text, stated
constraints) · what you **assumed** and why · what the codebase already delivers today
(from Phase 0, with `file:line`). Plus an explicit **not in this change** list — deferred,
out of scope, follow-up ticket — which is the Gate 1 scope statement made concrete.

## 2. Simplicity pass — mandatory

Run `/ponytail` over the design itself, not the code. Three questions:

- Does this need to exist at all, or is it YAGNI dressed as foresight?
- Which piece can be deleted with the outcome still met?
- Is there a standard-library, platform, or already-in-repo answer we are
  reimplementing? (Phase 0's prior-art section is the input here.)

The output is either a smaller design or one sentence per rejected
simplification saying why it does not work. Both are acceptable; silence is not.

## 3. Critic lenses

`phases/1-plan.md` § 1.7 runs two critics by default (`roles.md`); up to five for auth,
money, migrations or deletion. This table is what each lens checks and where it is grounded.
Every critic **returns findings, not approval**: "looks good" requires the list of what it
checked and why nothing was wrong.

| Critic       | Lens                                                                    | Grounding file                                                                                                            |
| ------------ | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Architecture | dependency rule, module depth, package-by-feature, coupling, cycles     | `books/clean-architecture.md`, `books/philosophy-of-software-design.md`, `books/fundamentals-of-software-architecture.md` |
| Simplicity   | YAGNI, premature abstraction, second-system effect, "delete it"         | `books/mythical-man-month.md`, `/ponytail`                                                                                |
| Data & scale | DDIA rules, transactions, idempotency, indexes, migration reversibility | `books/designing-data-intensive-applications.md`                                                                          |
| Security     | threat model completeness, authz at query level, LLM risks              | `doctrine/security-doctrine.md`                                                                                           |
| CoachBot fit | invariants, rules, prior art, reuse                                     | `doctrine/coachbot-invariants.md` + `.claude/rules/`                                                                      |

Use the `architecture-review` agent for the decomposition into DB / backend / worker /
frontend / devops work if the change spans more than one area. Disagreement between two
critics is signal: show both positions in the plan doc rather than picking quietly.
