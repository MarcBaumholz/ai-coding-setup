# Clean Code — Robert C. Martin, 2008

## Contents

- [Why this book is in the loop](#why-this-book-is-in-the-loop)
- [The argument (deep prose)](#the-argument-deep-prose)
- [Enforceable rules](#enforceable-rules)
- [Smells → moves](#smells--moves)
- [Review prompts](#review-prompts)
- [Anti-patterns specific to AI-generated code](#anti-patterns-specific-to-ai-generated-code)
- [Sources](#sources)

## Why this book is in the loop

Clean Code governs the _local legibility_ decision class: what a single function,
name, file, or comment is allowed to look like before a reviewer must push back. It
is the cheapest layer of the review chain because almost every rule it produces is
mechanically checkable — line counts, parameter counts, nesting depth, dead code,
commented-out code, narration comments. In our pipeline it is the first filter an
AI-generated diff hits, and it catches the failure mode LLMs produce most reliably:
plausible, verbose, over-narrated code that nobody can hold in their head. It does
**not** govern architecture, module boundaries, or performance — reach for Fowler or
Ousterhout there.

## The argument (deep prose)

Martin's thesis is that the dominant cost in software is not writing code but reading
it, and that the ratio is brutally lopsided — he claims something like ten to one.
Every hour you spend making a function ten seconds faster to comprehend is repaid by
every subsequent reader, including yourself in three weeks. From that single economic
claim the whole book is derived. If reading dominates, then the code must be optimised
for the reader, not the writer, not the compiler, and not the person who wants to
finish the ticket before standup. "Clean" in Martin's sense is not aesthetic; it is a
claim about the total cost of ownership of a line of code over its lifetime.

The mechanism he proposes is _relentless decomposition guided by naming_. A function
should do one thing. "One thing" is defined operationally, not philosophically: a
function does one thing if you cannot meaningfully extract another function from it
with a name that is not merely a restatement of its implementation. This is a real
test, and it is better than it sounds. If you can pull three lines out of a
twenty-line function and honestly call the result `validateTraversalCursor`, then the
original function was doing at least two things and the name of the extracted piece is
the proof. If the only honest name you can give the extracted block is
`doSecondPartOfThing`, you have found the boundary of the abstraction and should stop.
Naming is therefore not decoration in Martin's system; it is the measuring instrument.
The corollary — and this is the strongest single idea in the book — is the _stepdown
rule_: every function should be at a single level of abstraction, and a file should
read top-down as a sequence of descending abstraction levels, like a narrative that
gets more specific as you scroll. When a function mixes "charge the customer" with
"append a zero-padded string to a buffer", the reader has to context-switch mid-line,
and that switch is where bugs hide.

Around this core he stacks a set of secondary rules that are essentially corollaries.
Arguments should be few, because each argument is a thing the reader must hold in
working memory while decoding the call site; zero is ideal, three is suspicious, and a
boolean flag argument is always a bug because it announces that the function does two
things and the caller is choosing which. Side effects are lies: a function named
`checkPassword` that also initialises the session has told the reader something false,
and every future caller will be surprised. Comments are, in his framing, _failures_ —
"a comment is an apology for not expressing the idea in the code". The comment you
should write is the one explaining intent, consequence, or a non-obvious external
constraint; the comment you should never write is the one restating what the next line
already says. Commented-out code should be deleted, because version control exists and
a commented block is a permanent question mark nobody will ever resolve. Error handling
gets the same treatment: prefer exceptions to returned error codes so the happy path
stays readable, and never return null, because null propagates the burden of checking
to every caller forever. And underneath all of it sits the Boy Scout Rule — leave the
code cleaner than you found it — which is the only mechanism the book offers for
actually improving a large existing codebase, since nobody is going to fund a cleanup
sprint.

Now: where the book is wrong, and where it is simply from another world.

The most-cited failure is that the example code does not survive contact with its own
rules. The `PrimeGenerator` and `SetupTeardownIncluder` examples in the book are
widely and correctly criticised — functions get shredded into three-line fragments
that communicate through mutable instance fields, which converts explicit parameter
passing (visible, type-checked, local) into hidden temporal coupling (invisible,
order-dependent, and exactly the kind of thing TypeScript's type system cannot help
you with). This is the central practical danger of applying Clean Code literally in
2026: **aggressive extraction can make code worse by turning data flow into shared
state**. If extracting a function requires you to promote three locals into class
fields or module-level variables, do not extract it. The rule "functions should be
small" was never meant to outrank "you should be able to see where a value comes
from", and Martin's own examples get that trade wrong. A 40-line pure function with
visible top-to-bottom data flow is better than six 6-line methods coordinating through
`this._buffer`.

Second, the book is a Java book from 2008 pretending to be a general book. Large parts
of it are ceremony around a language that had no first-class functions, no
destructuring, no union types, no `Result` types, and no ergonomic immutability.
"Prefer polymorphism to switch statements" is sound advice in a language where the
alternative is a switch on a type-code integer with no compiler support. In TypeScript,
a `switch` over a discriminated union is _checked_ — add a variant, and every
non-exhaustive switch becomes a type error. That is strictly better than a class
hierarchy for most cases: the logic stays in one readable place, the compiler enforces
completeness, and you have not scattered one behaviour across five files. Martin's
"objects hide data and expose behaviour, data structures expose data and have no
behaviour; hybrids are the worst of both" is genuinely useful, but the conclusion he
draws — prefer objects — is inverted for a modern TS codebase where plain typed data
plus pure functions is the dominant, and better, idiom. Our repositories return rows,
not row objects with behaviour, and that is correct.

Third, the numeric limits are folklore presented as engineering. "Functions should be
twenty lines, and then smaller than that" has no empirical support, and the honest
version is a _distribution_ claim, not a hard cap: most functions should be short, and
a long one should be able to justify itself. We keep numeric thresholds anyway — see
the rules table — but we keep them as **review triggers**, not as failures. A 90-line
exhaustive `switch` mapping graph node kinds to handlers is fine. A 90-line
`handleRequest` with four nested `if`s is not. The number tells you where to look; it
does not tell you the verdict.

Fourth, the book has almost nothing to say about the things that actually kill systems:
module boundaries, coupling, data model design, concurrency, failure modes, and
operational behaviour. It optimises the inside of the box and is silent about which
boxes should exist. Ousterhout's counter-position — that deep modules with simple
interfaces beat many shallow ones, and that "classitis" (a proliferation of tiny
classes and methods each too small to justify its interface) is itself a disease — is
the necessary corrective. Every extraction has a cost: a name to learn, a jump to
follow, an interface to keep stable. Extraction is only a win when the extracted piece
has a _simpler interface than its implementation_. That is the test we actually apply,
and it is Ousterhout's, not Martin's.

Finally, the 2026-specific point. Clean Code was written against a human failure mode:
tired engineers taking shortcuts, writing terse cryptic code, skipping names. The
dominant failure mode now is the opposite. An LLM does not write terse cryptic code; it
writes verbose, defensively-guarded, heavily-narrated, symmetrically-structured code
that _pattern-matches_ to clean code while violating its spirit. It writes the comment
`// Fetch the user from the database` above `const user = await db.users.findById(...)`.
It adds a null check for a value the type system already proves non-null. It leaves the
old implementation next to the new one behind a flag "for safety". It invents an
interface with one implementation because interfaces look professional. Clean Code's
rules still apply, but the enforcement direction flips: you are not fighting
under-expression, you are fighting _over-production_. The version of the Boy Scout Rule
that matters in 2026 is "delete more than you add", and the version of "comments are
apologies" that matters is "a comment that restates the code is an artifact of
generation, not of thought — remove it". [extension]

Read this way, Clean Code stays in the loop as a checklist of local hygiene with hard,
scriptable thresholds — and explicitly _not_ as a design philosophy. Where it conflicts
with data-flow clarity, data-flow clarity wins. Where it conflicts with the type
system, the type system wins. Where it conflicts with deleting code, deleting code wins.

## Enforceable rules

| #   | Rule                                                                                                                                                                                                     | How to check                                                                                             | Severity        |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | --------------- | -------- | --- | ----- | ------ | ---------------------------------------------- | ----- |
| 1   | A function over ~40 lines of body prompts the question "would decomposition make this easier to understand?" — it is never an automatic finding. Defers to `doctrine/house-rules.md` S2 and PO-11: length is not a lint rule. | `mcp__code-review-graph__find_large_functions_tool` to locate; then judge by hops, not lines | note |
| 2   | File and component size limits are owned by `doctrine/house-rules.md` S1 (300 lines, block > 500) and S6 (Svelte 250). Do not apply a second threshold here.                                             | see S1/S6                                                                                                | fix             |
| 3   | Max nesting depth of 3 inside a function (loops + conditionals + try).                                                                                                                                   | ESLint `max-depth: [error, 3]`                                                                           | fix             |
| 4   | Max 4 positional parameters; beyond that use a single typed options object. Actor-first repo signatures (`actorId, projectId, id`) are exempt up to 4.                                                   | ESLint `max-params`; grep function signatures in diff                                                    | fix             |
| 5   | No boolean flag parameter that selects between two behaviours.                                                                                                                                           | Grep diff for `: boolean` in params; check whether callee branches on it at top level                    | fix             |
| 6   | No commented-out code, and no `// TODO` without a ticket id.                                                                                                                                             | `grep -nE '^\s*//\s*(const                                                                               | let             | function | if  | await | return | import)'`and`grep -n 'TODO' \| grep -v 'EPD-'` | block |
| 7   | No comment that restates the following statement. Comments must state _why_, a consequence, a constraint, or an invariant.                                                                               | Reviewer reads each added comment; if deleting it loses no information, delete it                        | fix             |
| 8   | No magic literal in business logic (numbers other than 0/1/-1, string keys, durations). Name it or put it in config.                                                                                     | Grep diff for numeric/string literals inside `if`/comparison/arithmetic                                  | fix             |
| 9   | Names are pronounceable, searchable, and unabbreviated; no Hungarian/type prefixes (`strName`, `IFoo`), no single letters outside a 3-line closure.                                                      | Reviewer scan of added identifiers; grep `\bI[A-Z][a-zA-Z]+\b` for interface prefixes                    | fix             |
| 10  | A function name states the whole effect. A query (`get*`, `find*`, `is*`, `compute*`) must not mutate or write. Command/query separation.                                                                | Grep query-named functions in diff for `await db.*.(insert\|update\|delete)`, assignments to outer scope | block           |
| 11  | Duplication ladder, per `house-rules.md` D1: the same knowledge appearing **twice** is flagged for review, **three times** must be extracted. Never unify duplicated *shape* that has different reasons to change. | `jscpd` on changed paths, or reviewer diff scan                                                          | note (fix at 3) |
| 12  | No dead code introduced: no unused export, unused param, unreachable branch, or new abstraction with exactly one caller and no second caller planned in the same diff.                                   | `pnpm lint` (`no-unused-vars`), `knip`/grep for single-caller exports                                    | block           |
| 13  | Single level of abstraction per function: a function must not mix domain calls with string/byte/DOM plumbing.                                                                                            | Reviewer: list the verbs in the function; if they span two vocabularies, split                           | note            |
| 14  | No returned `null` for "not found" in new code — use `undefined` with an explicit optional type, or a typed result. Never `any`, never a non-null assertion `!` without a comment proving the invariant. | `grep -n ': any\|as any\|!\.'` in diff; ESLint `no-non-null-assertion`                                   | fix             |
| 15  | Error paths do not swallow: no empty `catch`, no `catch` that logs and continues without a comment justifying it, no `err.message` returned to a user.                                                   | `grep -nA3 'catch'` in diff; cross-check `.claude/rules/error-handling.md`                               | block           |
| 16  | One logical assertion per test; test names read as behaviour sentences, not `test1`/`works`.                                                                                                             | Scan `*.spec.ts` in diff for multi-concern tests and vague names                                         | note            |
| 17  | Boy Scout / net-negative bias: a diff that adds a code path replacing an old one must delete the old one in the same diff.                                                                               | `git diff --stat`; look for added-but-not-removed parallel implementations                               | block           |

## Smells → moves

| Smell                             | How it looks in TS/Svelte                                                           | The move                                                                                                                  | Risk of the move                                                                                          |
| --------------------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Long Function                     | A 120-line `+page.server.ts` `load` doing auth, fetch, shape, and error mapping     | Extract Function per phase; then Split Phase (parse → authorize → fetch → present)                                        | Extracting into shared mutable state is worse than the original; keep params explicit                     |
| Deep nesting                      | `if (user) { if (project) { if (perm) { ... } } }`                                  | Replace Nested Conditional with Guard Clauses                                                                             | Early returns can skip cleanup; verify no `finally`-style teardown is bypassed                            |
| Flag argument                     | `save(entity, true /* publish */)`                                                  | Remove Flag Argument → `save()` + `saveAndPublish()`                                                                      | Duplicated bodies if you split without extracting the shared core first                                   |
| Magic literal                     | `if (score > 0.7)` in a gate                                                        | Replace Magic Literal with a named exported constant or config field                                                      | Constant defined far from use becomes a second indirection; keep it in the same module                    |
| Long parameter list               | `createThread(actorId, projectId, agentId, personaId, locale, source, meta)`        | Introduce Parameter Object (`CreateThreadInput`)                                                                          | Options bags hide required-vs-optional; make the type non-optional-by-default                             |
| Comment narration                 | `// loop over items` above a `for`                                                  | Delete the comment; if the loop is unclear, Extract Function and let the name carry it                                    | None. Deleting a redundant comment is free                                                                |
| Temporary field / hidden coupling | Svelte component with `let cache` mutated by three handlers in order                | Replace Temp with Query, or `$derived`                                                                                    | Turning a cached value into a derived query can change perf characteristics; measure on hot paths         |
| Repeated conditional on a kind    | `if (node.type === 'question') ... else if (node.type === 'summary')` in five files | Discriminated union + one exhaustive `switch` in one module (the TS-native form of Replace Conditional with Polymorphism) | Full class-per-variant polymorphism scatters logic; prefer the union unless variants carry distinct state |
| Duplicated block                  | Same permission-check preamble in six route handlers                                | Extract Function into a shared guard helper                                                                               | Over-generalised helper with five booleans is worse than six copies; extract only the identical part      |
| Speculative abstraction           | `interface AgentProvider` with a single implementing class                          | Inline Class / Remove Middle Man; delete the interface                                                                    | Deleting an interface an external package depends on is breaking; check callers first                     |
| Data clump                        | `startedAt`, `endedAt`, `durationMs` passed together everywhere                     | Introduce Parameter Object / Replace Primitive with Object                                                                | A new type crossing a package boundary needs to live in `@coachbot/types`, not be duplicated              |
| Hybrid object                     | Row type with methods hanging off it                                                | Separate the data type from the pure functions that operate on it                                                         | Callers may rely on method chaining; grep before splitting                                                |

## Review prompts

1. Which functions in this diff exceed 40 body lines or nesting depth 3, and for each, what is the single-sentence justification for keeping it that way?
2. For every comment added, does deleting it lose information that is not already in the code? Name the comments that fail this test.
3. Does any function whose name begins with `get`/`find`/`is`/`compute` perform a write, a mutation, or an enqueue? Cite line numbers.
4. Does this diff add a new abstraction (interface, base class, generic helper, config layer) with exactly one call site? If yes, what is the second call site, and does it exist in this diff?
5. Does the diff leave two implementations of the same behaviour coexisting (old path + new path, fallback beside replacement)? Which lines should have been deleted?
6. Are there three-or-more-line blocks duplicated within the diff or against existing code in the same package? Give the pairs.
7. Did any extraction in this diff convert an explicit parameter into shared mutable state (module-level `let`, class field, closure variable written by more than one function)? If so, it is a regression — where?
8. Are all new literals in conditionals and arithmetic named, and are all new user-facing error strings free of internal detail (`err.message`, ids, SQL)?
9. For each new `any`, `as`, or `!`, what invariant makes it safe, and is that invariant written down at the site?
10. If a new engineer read only the changed files top-to-bottom, at what exact line would they first have to jump elsewhere to understand what is happening?

## Anti-patterns specific to AI-generated code

- **Comment narration.** The model emits a comment per statement restating it. Violates
  "comments are an apology". _Counter-move:_ delete every comment whose removal loses
  nothing; keep only why/consequence/invariant comments. Make this a mechanical pass
  before review, not a review discussion.
- **Fallback beside old code.** The model adds the new path and keeps the old one behind
  a condition, an env check, or a `try/catch`. Violates the Boy Scout Rule and doubles
  the surface. _Counter-move:_ the diff must be net-negative or explicitly justified;
  deletion is mandatory inside owned paths, and a deliberate breaking change gets one
  line of justification rather than a compatibility shim.
- **Defensive re-checks.** Null checks, `typeof` guards, and try/catch around code whose
  types already prove safety, because the model optimises for "never throw". This is
  noise that hides the real error paths. _Counter-move:_ every guard must name the
  caller that can actually violate it; if none can, delete it and let the type stand.
- **Symmetric over-extraction.** Six three-line helpers with parallel names
  (`handleA`, `handleB`, `handleC`) that only exist to look decomposed, communicating
  through a shared object. _Counter-move:_ apply the interface-simpler-than-implementation
  test; collapse helpers whose name is a restatement of their body.
- **Premature abstraction.** `interface`, `strategy`, `registry`, `factory`, `BaseX` for a
  single case, because those tokens are statistically associated with quality code.
  _Counter-move:_ the rule of three — no abstraction until the third real caller exists
  in the repository today.
- **God file growth.** The model appends to the file it was shown rather than creating or
  finding the right home, so one file drifts to 900 lines and becomes a merge hotspot.
  _Counter-move:_ file-length gate on changed files, and an explicit "where does this
  belong" question before writing.
- **Plausible naming.** Names that read well but are wrong: `agentId` for a value that is
  actually a draft identity, `validate` for something that also persists. Clean Code's
  naming rules are the defence, but the check must be semantic — verify the name against
  what the body does, not against whether it sounds professional.
- **Test theatre.** Tests that assert the mock was called, or re-implement the function
  under test. _Counter-move:_ every new test must be able to fail; delete the assertion
  and confirm it goes red.

## Sources

- https://gist.github.com/wojteklu/73c6914cc446146b8b533c0988cf8d29 — canonical condensed rule list (general, names, functions, comments, structure, objects, tests, smells)
- https://refactoring.com/catalog/ — refactoring names used in the smells table
- https://bugzmanov.github.io/cleancode-critique/ — critique of the book's examples and its single-dimension focus on readability
- https://qntm.org/clean — "It's probably time to stop recommending Clean Code" (fetch returned 403; content accessed via search summary of the same article)
- https://medium.com/thedevproject/summary-of-clean-code-by-robert-c-martin-7117b3947cb8 — function size, argument-count, and side-effect rules as stated in the book
- https://gerlacdt.github.io/blog/posts/clean_code/ — "The Good, the Bad and the Ugly": where the book's advice is dated for non-Java codebases
