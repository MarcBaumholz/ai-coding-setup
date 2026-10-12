# House rules — the hard limits

The non-negotiable, checkable part of the doctrine. Everything here is either
mechanically verifiable or answerable yes/no by a reviewer. Judgement lives in
`references/books/`; this file is what a gate enforces.

Severity: **block** = do not proceed past the gate · **fix** = fix before MR ·
**note** = record, decide later.

## Contents

- [Size and shape](#size-and-shape)
- [Responsibility and coupling](#responsibility-and-coupling)
- [Duplication (DRY, correctly applied)](#duplication-dry-correctly-applied)
- [Naming](#naming)
- [Comments](#comments)
- [Errors and edges](#errors-and-edges)
- [Deletion licence](#deletion-licence)
- [The escape hatch](#the-escape-hatch)

## Size and shape

| #   | Rule                                                                                                                        | Check                     | Severity          |
| --- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------- | ----------------- |
| S1  | A source file is ≤ 300 lines. 200 is the target. (mirrored by verification-loop Gate 4 and thermo-nuclear)                  | `wc -l` on changed files  | fix (block > 500) |
| S2  | A function over ~40 lines is a prompt to ask whether decomposition would help — never an automatic fix. See the note below. | read the diff             | note              |
| S3  | Nesting depth ≤ 3. A fourth level means an extraction is missing.                                                           | read the diff             | fix               |
| S4  | ≤ 4 positional parameters. Beyond that, one options object with a named type.                                               | read the diff             | fix               |
| S5  | One exported concept per file; the filename names it.                                                                       | filename vs exports       | fix               |
| S6  | A Svelte component is ≤ 250 lines including markup; extract sub-components past that.                                       | `wc -l`                   | fix               |
| S7  | Cyclomatic complexity of a function ≤ 10.                                                                                   | reviewer judgement / lint | note              |

These are smell thresholds, not laws of nature. A 350-line file that is one
cohesive state machine is fine; a 150-line file doing three unrelated jobs is
not. **Crossing a limit requires a one-line justification in the MR, not
silence.** Never satisfy a limit by moving code into a shallow pass-through
module — that trades a long file for a worse architecture.

**S2 is deliberately the weakest rule here**, and it is the one an agent will
over-apply. The house position (stated in full in
`references/books/philosophy-of-software-design.md`, identical wording in
`clean-architecture.md`) is: _Martin governs the arrows between boxes;
Ousterhout governs the inside of a box._ At the boundary — dependency direction,
one axis of change, no framework types inward — the rules are structural and
they block. Inside a function, length is not a target and **must never become a
lint rule** (`max-lines-per-function` stays off; enabling it needs an ADR).

Extract only when the extracted unit is _deeper_ than the code it replaces. A
60-line linear narrative with three good comments beats six 10-line functions
that must be read in sequence to be understood. The real test is not line count
but hops: **if a reader must chase more than one hop to understand a single
operation, the decomposition is wrong** — in either direction.

The same asymmetry explains why S1 (file length) is stronger than S2: a long
file is usually many responsibilities that could be separated cleanly, while a
long function is often one responsibility that should not be.

## Responsibility and coupling

| #   | Rule                                                                                             | Check                         | Severity |
| --- | ------------------------------------------------------------------------------------------------ | ----------------------------- | -------- |
| R1  | One reason to change per module. Name it in a sentence with no "and".                            | write the sentence            | fix      |
| R2  | Dependencies point inward: UI → route → service → repository → domain. Never back.               | import graph                  | block    |
| R3  | No business logic in a route handler. Routes parse, authorize, delegate, format.                 | read the diff                 | fix      |
| R4  | No framework or transport types (`RequestEvent`, `Response`, HTTP status) below the route layer. | grep the diff                 | fix      |
| R5  | No SQL outside `packages/database`.                                                              | grep for `sql`/query builders | block    |
| R6  | Package by feature, not by layer. A feature's files sit together.                                | folder layout                 | fix      |
| R7  | An interface with exactly one implementation and no test double needs a stated reason. **Block at Gate 2** (design), **fix** in code review.         | read the diff                 | note     |
| R8  | No import cycles between packages.                                                               | `madge`/dependency check      | block    |

## Duplication (DRY, correctly applied)

| #   | Rule                                                                                     | Check              | Severity                |
| --- | ---------------------------------------------------------------------------------------- | ------------------ | ----------------------- |
| D1  | Three occurrences of the same _knowledge_ → extract. Two → wait.                         | reviewer judgement | fix                     |
| D2  | Duplicated _shape_ with different reasons to change is not duplication. Do not merge it. | reviewer judgement | block the merge-attempt |
| D3  | A magic literal used in two places becomes a named constant in one place.                | grep               | fix                     |
| D4  | A validation rule exists once. Client-side copies re-use the same schema object.         | grep for the rule  | fix                     |

The DRY failure mode in this codebase is not repetition — it is **premature
unification**: one `handleThing()` with a `mode` flag serving three callers.
Prefer duplication over the wrong abstraction, and say so explicitly when you
choose it.

## Naming

| #   | Rule                                                                                                 | Check            | Severity |
| --- | ---------------------------------------------------------------------------------------------------- | ---------------- | -------- |
| N1  | Names come from the domain — `CONTEXT.md` if it exists, else the vocabulary already used in surrounding code — never from the implementation.                              | vocabulary match | fix      |
| N2  | Booleans read as assertions: `isPublished`, `hasConsent`, `canEdit`.                                 | grep             | fix      |
| N3  | No `data`, `info`, `manager`, `helper`, `util`, `handler`, `process`, `temp` as a whole name.        | grep             | fix      |
| N4  | Ambiguous ids are qualified: `draftAgentId`, `publishedAgentId`, `versionId` — never bare `agentId`. | grep             | block    |
| N5  | A function name states the effect, not the mechanism.                                                | read the diff    | note     |

## Comments

| #   | Rule                                                                                          | Check         | Severity |
| --- | --------------------------------------------------------------------------------------------- | ------------- | -------- |
| C1  | A comment explains **why**, never **what**. A "what" comment means the name failed.           | read the diff | fix      |
| C2  | Every non-obvious interface gets a doc comment describing the contract a caller must satisfy. | read the diff | fix      |
| C3  | No commented-out code. Git remembers.                                                         | grep          | block    |
| C4  | No narration comments (`// Loop over the items`) — the AI-generated-code tell.                | grep          | fix      |
| C5  | A `TODO` carries an owner and a ticket, or it is deleted.                                     | grep `TODO`   | fix      |

C1 and C2 are not in tension: Ousterhout's point is that comments must add
information the code cannot express — the contract, the invariant, the reason
for a surprising choice. Restating the code is the sin.

## Errors and edges

| #   | Rule                                                                                    | Check         | Severity |
| --- | --------------------------------------------------------------------------------------- | ------------- | -------- |
| E1  | Prefer designing the error out of existence over handling it everywhere.                | design review | note     |
| E2  | Every error path is either handled or propagated deliberately. No empty `catch`.        | grep `catch`  | block    |
| E3  | User-facing messages never contain `err.message`, stack traces, ids, or SQL.            | grep          | block    |
| E4  | Every caught error is logged with structured context (`locals.logger` / `getLogger()`). | read the diff | fix      |
| E5  | Every list endpoint paginates. Every query has a bound.                                 | read the diff | block    |
| E6  | Every external call has a timeout and a bounded retry policy.                           | read the diff | fix      |

## Deletion licence

Adding a fallback beside old code is the default failure mode of an agent, and
it is how files become 900 lines. Inside the paths you own you **may and should
delete** dead code rather than layer around it. A deliberate breaking change is
allowed when justified in one line (`// breaking: <reason>`) — do not route
around it. Outside your owned paths, report; do not edit.

## The escape hatch

Any rule here can be broken. The cost of breaking it is one sentence in the MR
saying which rule and why. A gate rejects an unjustified violation, never a
justified one — the goal is a decision on the record, not compliance theatre.
