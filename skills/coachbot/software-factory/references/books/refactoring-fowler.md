# Refactoring: Improving the Design of Existing Code — Martin Fowler, 1999 / 2nd ed. 2018

## Contents

- [Why this book is in the loop](#why-this-book-is-in-the-loop)
- [The argument (deep prose)](#the-argument-deep-prose)
- [Enforceable rules](#enforceable-rules)
- [Smells → moves](#smells--moves)
- [Review prompts](#review-prompts)
- [Anti-patterns specific to AI-generated code](#anti-patterns-specific-to-ai-generated-code)
- [Sources](#sources)

## Why this book is in the loop

Fowler governs the _change-safely_ decision class: given code that already works, what
sequence of behaviour-preserving steps gets it into a shape where the next feature is
cheap. It supplies the shared vocabulary the whole pipeline uses — Extract Function,
Split Phase, Replace Conditional with Polymorphism — so a review finding can name a
concrete move instead of saying "this is messy". The second edition is in JavaScript,
which makes it the closest thing we have to a canonical text for a TypeScript codebase.
It is the book that tells us _when not to redesign_: refactor in small steps behind
green tests, never as a rewrite.

## The argument (deep prose)

Fowler's definition is deliberately narrow and that narrowness is the whole point.
Refactoring (noun) is "a change made to the internal structure of software to make it
easier to understand and cheaper to modify without changing its observable behavior".
Refactoring (verb) is restructuring by applying a series of such changes. If observable
behaviour changed, you were not refactoring — you were doing something else and calling
it refactoring, which is how teams end up with three-week "refactors" that ship bugs
and cannot be reviewed. The discipline is enforced by the two-hats metaphor: at any
moment you are either adding functionality (tests may change, behaviour may change,
structure stays put) or refactoring (structure changes, tests do not change, behaviour
does not change). Switching hats is fine and frequent; wearing both at once is the
error. A diff that both moves code and alters logic is unreviewable, because the
reviewer cannot separate the intentional change from the accidental one.

The second load-bearing claim is economic, and it is subtler than "clean code is good".
Fowler argues refactoring is not a virtue activity but an _investment with a payback
period_, and the payback comes from a specific mechanism: most code is hard to change
because the change you want to make is spread across places that do not know about each
other, or because a single place mixes concerns so you cannot touch one without risking
the other. Refactoring buys down that specific friction. Hence the two moments he
recommends: refactor _before_ adding a feature, to make the feature easy to add
(preparatory refactoring — "make the change easy, then make the easy change"), and
_after_, to clarify what you just learned. He is explicit that you should not schedule
refactoring as a separate project or ticket. A cleanup epic is a symptom: it means the
team stopped doing it continuously, and it will be the first thing cut when the quarter
gets tight.

The third piece is the _catalogue_. This is the part that makes the book durable. Each
refactoring has a name, a motivation, a mechanics section that lists steps small enough
that you compile and test between them, and an example. The mechanics are the actual
technology. "Extract Function" as an idea is trivial; "Extract Function" as a sequence —
create the new empty function with an intention-revealing name, copy the fragment, pass
in every out-of-scope variable it reads, handle variables it assigns, compile, replace
the original fragment with a call, test, then look for other fragments that can now call
it — is a procedure that a tired engineer can execute correctly at 6pm. The catalogue's
value is that it converts judgement into steps. When you know the name of the move, you
know the failure modes of the move.

The fourth piece is the smells taxonomy, which is the diagnostic front end to the
catalogue. The second edition lists 24: Mysterious Name, Duplicated Code, Long Function,
Long Parameter List, Global Data, Mutable Data, Divergent Change, Shotgun Surgery,
Feature Envy, Data Clumps, Primitive Obsession, Repeated Switches, Loops, Lazy Element,
Speculative Generality, Temporary Field, Message Chains, Middle Man, Insider Trading,
Large Class, Alternative Classes with Different Interfaces, Data Class, Refused Bequest,
Comments. The second edition added Mysterious Name, Global Data, Mutable Data and Loops,
dropped Parallel Inheritance Hierarchies and Incomplete Library Class, and renamed
several — which is itself informative: the additions are all functional-programming
concerns, and their arrival marks the moment the book stopped being an OO book. Two of
the smells are the sharpest diagnostic pair in the literature. Divergent Change is one
module changing for many different reasons; Shotgun Surgery is one reason forcing
changes across many modules. They are duals, they point at opposite fixes (split the
module vs. gather the scattered logic), and between them they explain most of why a
codebase feels slow to work in. If a review can only ask two structural questions, those
are the two.

The fifth piece, and the one people skip, is that **refactoring depends on tests**.
Fowler is unambiguous: without a suite you trust and can run in seconds, refactoring is
gambling. The small-steps mechanics only work if the feedback after each step is cheap.
This is also the honest limit of the book — it assumes you already have the tests, which
is precisely the assumption Feathers spends a whole book removing. Read the two together:
Feathers gets you to the point where Fowler's mechanics are safe.

Now the criticisms and the 2026 adjustments.

First, the book's centre of gravity is still object-oriented even in the JavaScript
edition, and several catalogue entries are answers to questions TypeScript does not ask.
Replace Type Code with Subclasses, Replace Conditional with Polymorphism, Extract
Superclass, Pull Up/Push Down Method, Replace Subclass with Delegate — these exist
because Java's only mechanism for open extension was inheritance. In TypeScript the
discriminated union plus an exhaustive `switch` is usually the better answer: it is
compiler-checked for exhaustiveness, it keeps all variants of a behaviour visible on one
screen, and it does not scatter one concern across five files. Fowler's underlying goal —
"do not repeat the same conditional dispatch in many places" — is right; his named
solution is one of two, and in our stack it is usually the worse one. Use polymorphism
when variants carry genuinely different _state and lifecycle_; use a union when they
carry different _shape_ and the behaviours are a handful of pure functions.

Second, the catalogue's cost model is out of date in one direction and understated in
another. Out of date: many entries (Rename Variable, Inline Variable, Change Function
Declaration, Move Function) are now a keystroke in a language server with project-wide
accuracy. The mechanics sections for those are historical curiosities; just do it. But
also understated: automated rename is exactly what makes reviewers stop reading. A
1,400-line diff that is "just a rename" hides the three lines that were not a rename.
The 2026 discipline is therefore stricter than the book's: mechanical refactorings go in
**their own commit, ideally their own MR**, with a title that says so, and never share a
commit with behaviour change. [extension]

Third, Fowler undersells the risk of refactoring across a network or module boundary.
The catalogue's behaviour-preservation guarantee is a _local_ guarantee. Move Function
across a package boundary in a pnpm monorepo changes the build graph, the public API of a
package, and possibly the deploy unit. Encapsulate Record on a row type that is also
serialised into a queue payload or an OpenAPI schema is a wire-format change wearing a
refactoring costume. The check the book does not give you: before any move, ask what
_else_ observes this shape — the database, the queue, the API spec, another app in the
monorepo, a cached Redis value written by the previous deploy. Behaviour preservation
must be evaluated at every observer, not just the callers you can see. [extension]

Fourth, the book has little to say about performance and none about operational risk.
Replace Loop with Pipeline is presented as almost always an improvement; on a hot path
over large arrays it allocates intermediate arrays and can be materially slower. Replace
Derived Variable with Query trades memory for recomputation, which on a per-request path
in a chat worker is a real decision, not a stylistic one. The rule we apply: refactorings
that change the number of passes over data, the number of allocations, or the number of
round trips are not pure refactorings — they are performance changes and need a
measurement, not just a green test.

Fifth, and most important for us: refactoring assumes the code is _worth_ keeping. The
catalogue has no entry for "delete this". Remove Dead Code is the closest, and it is
framed narrowly. In an AI-assisted codebase the single highest-yield move is deletion,
and the second is _not_ generalising. Speculative Generality is in the smells list, which
is good, but it is presented as an occasional human sin. It is now the default output of
code generation. The most valuable refactoring in 2026 is Inline Function / Inline Class
applied to abstractions that never earned their keep, and the review question is not
"how should this be structured" but "should this exist". [extension]

Used correctly, Fowler is not a style guide; it is a _risk discipline_. Its real
contribution to our pipeline is: name the move, take it in steps small enough to revert,
keep the tests green between steps, and never mix the hats in one diff.

## Enforceable rules

| #   | Rule                                                                                                                                                            | How to check                                                                                                        | Severity                    |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | --------------------------- | ----- |
| 1   | Two hats: no commit mixes a pure structural move (rename/move/extract with no logic change) with a behaviour change.                                            | Reviewer: for each commit, classify as structure-only or behaviour; a commit that is both is split                  | block                       |
| 2   | Every refactoring in a diff must be nameable from the catalogue. If the author cannot name it, it is a redesign and needs a plan, not a review.                 | Ask the author/agent to label each structural hunk with its refactoring name                                        | fix                         |
| 3   | Tests are green before and after, and the test files are unchanged by a structure-only commit.                                                                  | `git diff --name-only <commit>` contains no `*.spec.ts` for structure-only commits; `pnpm test` passes at both ends | block                       |
| 4   | Preparatory refactoring precedes the feature, in a separate commit, when the feature diff would otherwise exceed ~400 changed lines.                            | `git diff --stat` on the feature commit                                                                             | note                        |
| 5   | Cyclomatic complexity over 10 per function is a review prompt, not a gate — matches `house-rules.md` S7. Do **not** enable `complexity: [error, 10]`: like `max-lines-per-function` (PO-11) it fights the house position that decomposition must be judged, not counted. | reviewer judgement; lint may report at `warn` | note |
| 6   | No Shotgun Surgery: a single logical change must not touch the same concept in more than 3 files without a stated reason.                                       | Reviewer counts files implementing one concept; `mcp__code-review-graph__get_impact_radius_tool`                    | fix                         |
| 7   | No Divergent Change: a file changed in this diff for two unrelated reasons must be split.                                                                       | Reviewer: list the reasons a file changed; >1 unrelated reason is a finding                                         | fix                         |
| 8   | No Speculative Generality: no type parameter, options field, interface, or hook with zero current consumers.                                                    | Grep for new exported symbols with one or zero references (`knip`, or `rg` count)                                   | block                       |
| 9   | No Primitive Obsession on identifiers: ids crossing a function boundary use branded types from `@coachbot/types`, not `string`.                                 | Grep new signatures for `Id: string` / `id: string`                                                                 | fix                         |
| 10  | No Mutable Data escaping a module: no exported `let`, no module-level mutable singleton state added outside an explicit cache/client module.                    | `grep -nE '^export let                                                                                              | ^let ' ` in changed modules | block |
| 11  | No Message Chains deeper than 2 (`a.b.c.d()`), and no reaching through a repository result into another repository.                                             | `grep -nE '\)\.[a-z]\w*\.[a-z]\w*\.[a-z]\w*'`                                                                       | note                        |
| 12  | Mysterious Name: every renamed or added symbol must be understandable without reading its body.                                                                 | Reviewer: read only the name and signature; state what it does; compare with the body                               | fix                         |
| 13  | A structural move that crosses a package boundary, a DB column, a queue payload, or the OpenAPI schema is not a refactoring — it needs a migration/compat note. | Check whether changed types appear in `packages/types/src/api/`, migrations, or queue job payload types             | block                       |
| 14  | Refactorings that change pass count, allocation count, or round-trip count on a request path ship with a measurement.                                           | Reviewer: identify loop→pipeline, memo→query, N+1 changes on hot paths                                              | fix                         |
| 15  | Duplicated Code: the same 3+ line logic in 3 places is extracted; in exactly 2 places, extraction is optional and must not be over-parameterised.               | `jscpd`, plus the rule of three                                                                                     | fix                         |
| 16  | Repeated Switches: the same discriminant switched on in more than 2 modules is consolidated into one module.                                                    | Grep for `switch (x.type)` / `x.kind ===` across the diff and package                                               | fix                         |

## Smells → moves

| Smell                             | How it looks in TS/Svelte                                               | The move                                                                                                                        | Risk of the move                                                                    |
| --------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Mysterious Name                   | `handleData`, `processItem`, `doWork`, `utils.ts`                       | Rename Variable / Change Function Declaration; rename the file too                                                              | Rename-only diffs hide real changes; isolate in one commit                          |
| Long Function                     | 150-line `POST` handler in `+server.ts`                                 | Extract Function, then Split Phase (validate → authorize → execute → present)                                                   | Extracting into shared mutable state is a regression; keep params explicit          |
| Long Parameter List               | 7 positional args on a repository method                                | Introduce Parameter Object; Preserve Whole Object                                                                               | Options bag can hide required fields; keep the type strict                          |
| Global Data / Mutable Data        | Exported `let currentConfig` mutated by two modules                     | Encapsulate Variable behind a getter, then narrow writers to one                                                                | Encapsulation alone does not fix ordering bugs; also remove the write path          |
| Divergent Change                  | `agents.ts` repo changed for both versioning and analytics reasons      | Extract Class / split the module by reason for change                                                                           | Splitting a repo file can break barrel exports; update the index in the same commit |
| Shotgun Surgery                   | Adding a feedback score touches chat route + worker + repo + types + UI | Move Function / Combine Functions into Class to gather the concept in one module                                                | Gathering can create a new god module; only gather what actually co-varies          |
| Feature Envy                      | A Svelte component computing domain rules from a raw row                | Move Function to the module owning the data (server/derive helper)                                                              | Moving logic server-side changes reactivity; verify the value still updates         |
| Data Clumps                       | `startedAt`/`endedAt`/`durationMs` threaded everywhere                  | Introduce Parameter Object; Replace Primitive with Object                                                                       | New shared type must live in `@coachbot/types`, not be duplicated                   |
| Primitive Obsession               | `projectId: string` instead of the branded type                         | Replace Primitive with Object (branded IDs)                                                                                     | Branding at a boundary requires explicit casts at the edge; do it in one place      |
| Repeated Switches                 | `node.type` switched on in engine, UI, and worker                       | Consolidate into one exhaustive `switch` in a shared module; Replace Conditional with Polymorphism only if variants carry state | Class-per-variant scatters logic across files and loses exhaustiveness checking     |
| Loops                             | Hand-rolled `for` with accumulators and flags                           | Replace Loop with Pipeline; Split Loop                                                                                          | Pipelines allocate; on hot paths measure before/after                               |
| Lazy Element                      | A one-line wrapper module or a component that renders one child         | Inline Function / Inline Class                                                                                                  | The wrapper may be a public export; check external references                       |
| Speculative Generality            | `interface Strategy` with one impl, unused generic `<T>`                | Collapse Hierarchy / Inline Class / Remove Middle Man; delete the type parameter                                                | Deleting an exported abstraction is breaking; grep the monorepo first               |
| Temporary Field                   | Svelte `let pending` only meaningful during one handler                 | Replace Temp with Query / `$derived`                                                                                            | Derived recomputation can churn; check reactivity graph size                        |
| Middle Man                        | Repository method that only forwards to another repository              | Remove Middle Man; call the real thing                                                                                          | Removing a layer removes a future seam; acceptable — reintroduce when needed        |
| Insider Trading                   | Route reading another package's internal helper via a deep import       | Hide Delegate; export a proper API from the owning package                                                                      | Widening a package's public API is a commitment; keep it minimal                    |
| Large Class / god file            | 900-line `+page.server.ts` or store                                     | Extract Class / Extract Function then Move Function                                                                             | Splitting creates import churn; do it as a structure-only commit                    |
| Refused Bequest                   | Base agent class whose subclass ignores half its methods                | Replace Superclass with Delegate; prefer composition                                                                            | Delegation adds a hop; only worth it when the bequest is genuinely refused          |
| Comments as deodorant             | A comment explaining a confusing block                                  | Extract Function and name it after the comment; then delete the comment                                                         | None if the extraction is honest                                                    |
| Nested conditionals               | `if/else` pyramid in a permission check                                 | Replace Nested Conditional with Guard Clauses; Decompose Conditional                                                            | Guard clauses can skip shared teardown; check `finally` semantics                   |
| Duplicated conditional expression | Same compound boolean in three branches                                 | Consolidate Conditional Expression; Extract Function for the predicate                                                          | Named predicate must stay honest as conditions evolve                               |

## Review prompts

1. For each structural hunk in this diff, what is its catalogue name, and does any commit contain both a structural move and a behaviour change?
2. Did any test file change in a commit the author describes as a refactoring? If yes, what behaviour actually changed?
3. Which single logical concept in this change is implemented in more than three files (Shotgun Surgery), and what would gathering it look like?
4. Which changed file was modified for two unrelated reasons (Divergent Change), and where is the seam between them?
5. Does this diff introduce any exported symbol, generic parameter, interface, or config field with zero current consumers? List them.
6. Does any moved or reshaped type also cross a persistence, queue, cache, or OpenAPI boundary — i.e. is behaviour preserved for _all_ observers, not just callers?
7. Does any refactoring in this diff change the number of passes over data, allocations, or database round trips on a request path? Where is the measurement?
8. Which conditionals in this diff dispatch on the same discriminant as conditionals that already exist elsewhere in the package?
9. If this change had to be reverted at 2am, is it one revert, and does reverting it leave the system consistent (schema, cache, queue payloads included)?
10. What is the smallest sequence of named refactorings that would have made this feature diff trivial, and why was it not done first?

## Anti-patterns specific to AI-generated code

- **Mixed hats by default.** Asked to "clean up and add X", the model reformats, renames,
  moves, and changes logic in one pass, producing an unreviewable diff. _Counter-move:_
  instruct two commits — structure-only first with tests untouched, then behaviour — and
  reject diffs that mix them.
- **Speculative generality as a reflex.** Generic parameters, `Strategy`/`Factory`/`Registry`
  scaffolding, and config options for cases nobody asked for, because those shapes are
  overrepresented in training data. _Counter-move:_ rule of three; every new abstraction
  must cite its third existing caller or be inlined.
- **Refactoring without a green baseline.** The model restructures code that has no test,
  then asserts it is equivalent. That is not refactoring, it is a rewrite with a
  confident tone. _Counter-move:_ require a characterization test first (see the Feathers
  reference) or forbid the restructure.
- **Shotgun surgery from partial context.** Given one file, the model patches locally and
  duplicates the concept rather than moving it, so the same rule ends up in the route, the
  worker, and the component. _Counter-move:_ impact-radius query before editing; state the
  single owner module for the concept in the prompt.
- **Behaviour drift disguised as cleanup.** Silent changes to defaults, error messages,
  ordering, null handling, or timezone behaviour inside a "refactor". _Counter-move:_
  structure-only commits must be provable — diff the compiled output or run the full suite
  with no test changes allowed.
- **Cargo-cult catalogue application.** Replace Conditional with Polymorphism applied to a
  two-case discriminated union, producing two classes and a factory to replace six lines.
  _Counter-move:_ prefer the TS-native union + exhaustive switch; require the extraction to
  produce an interface simpler than the implementation it hides.
- **Pipeline conversion on hot paths.** `for` loops mechanically rewritten as
  `.map().filter().reduce()` chains in the conversation worker. _Counter-move:_ treat as a
  performance change; require a benchmark or leave the loop.
- **Never deleting.** The model refactors around dead code instead of removing it, because
  deletion feels destructive. _Counter-move:_ explicit licence to delete within owned
  paths, and a net-line-count check on cleanup commits.

## Sources

- https://refactoring.com/ — Fowler's definitions of refactoring (noun/verb), why and when to refactor
- https://refactoring.com/catalog/ — the full refactoring catalogue used for the move names in this file
- https://medium.com/@rsolismelo/refactoring-chapter-3-bad-smells-in-code-98aa611332c7 — chapter 3 smells walkthrough
- https://note.com/engineers_hub/n/nc520c00d9bbd?hl=en — 2nd-edition smell list, additions/removals/renames vs 1st edition
- https://forsethingvild.medium.com/book-review-is-martin-fowlers-refactoring-still-relevant-d724c146f774 — relevance critique of the 2nd edition
- https://github.com/ittus/Refactoring-summary-2nd-javascript — JavaScript-edition summary of the catalogue entries
