# A Philosophy of Software Design — John Ousterhout, 2018 (2nd ed. 2021)

## Contents

- [Why this book is in the loop](#why-this-book-is-in-the-loop)
- [The argument (deep prose)](#the-argument-deep-prose)
- [Enforceable rules](#enforceable-rules)
- [Design review prompts](#design-review-prompts)
- [Fitness functions](#fitness-functions)
- [Applied to a package-by-feature TS monorepo](#applied-to-a-package-by-feature-ts-monorepo)
- [Anti-patterns specific to AI-generated code](#anti-patterns-specific-to-ai-generated-code)
- [Sources](#sources)

## Why this book is in the loop

Clean Architecture tells you where the arrows go. This book tells you whether the
boxes are worth having. It is the only reference in the set with a usable _cost
model for abstraction_ — Ousterhout's depth ratio, complexity hidden versus
interface exposed — and that model is exactly the thing LLM-generated code
violates by default. A model asked to "add a service layer" will add one, and it
will be shallow, and no dependency-direction lint will catch it because the arrow
points the right way. Depth is the check that catches it.

Three jobs in our loop:

1. **The stop rule for decomposition.** When to _not_ extract a function, not
   add a package, not introduce an interface. We have no other reference that
   argues in that direction.
2. **The complexity vocabulary for reviews.** "Change amplification", "cognitive
   load", "unknown unknowns", "information leakage", "pass-through" — precise
   words that turn "this feels wrong" into a falsifiable claim.
3. **The comment doctrine.** We write interface comments and _why_ comments as
   policy, against Clean Code's advice, and this is the book we cite for it.

## The argument (deep prose)

Ousterhout starts from a definition rather than a principle: **complexity is
anything related to the structure of a software system that makes it hard to
understand and modify.** It is defined by the reader, not the author — if the
people maintaining the system find it hard, it is complex, and your opinion that
it is elegant is not evidence. Complexity is also incremental: it accumulates
from hundreds of small, individually-defensible decisions, which is why there is
never a single moment where you can point at the mistake, and why it cannot be
fixed by one heroic refactor.

He gives three **symptoms**, and they are the most useful diagnostic in the book
because each has a different cure. **Change amplification**: a seemingly simple
change requires modification in many places (cure: better placement, fewer
duplicated shapes). **Cognitive load**: how much a developer must hold in their
head to complete a task (cure: hide it, or write it down). **Unknown unknowns**:
it is not obvious which code must be modified to make a change correctly — the
worst of the three, because the other two announce themselves and this one
produces a bug in production. He then names the two **causes**: **dependencies**
(a piece of code cannot be understood or changed in isolation) and **obscurity**
(important information is not obvious). Every technique in the book reduces one
of those two.

The central technique is **deep modules**. A module has an interface (everything
a caller must know) and an implementation. Its value is the ratio: functionality
hidden divided by interface exposed. A _deep_ module offers a simple interface
over substantial machinery — Ousterhout's canonical example is the Unix file I/O
API, five calls hiding buffering, permissions, block allocation, and device
drivers. A _shallow_ module has an interface nearly as complicated as its
implementation; it costs the reader the learning of the interface and gives back
almost nothing. Crucially, **a shallow module is a net negative**, not a neutral:
it adds surface without removing anything. This is the direct rebuttal to
"smaller is always better." Small modules are only good if they are also deep,
and most tiny modules are not.

Supporting doctrine follows from this. **Information hiding** is the mechanism
that creates depth; its inverse, **information leakage**, is when the same design
decision is reflected in multiple modules, so changing it means changing all of
them. **Temporal decomposition** is the most common cause of leakage: structuring
modules by the order operations happen (read → parse → validate → write) rather
than by the knowledge they hold, which spreads file-format knowledge across four
modules. **Pass-through methods** (a method that does nothing but call another
with the same signature) and **pass-through variables** (an argument threaded
through five frames to reach the one that needs it) are named as red flags —
interface cost with no depth. **Different layer, different abstraction**: if
adjacent layers have similar interfaces, one of them probably shouldn't exist.
**General-purpose modules are deeper**: somewhat-general interfaces are usually
both simpler and more useful than an interface specialized to today's single
caller; the heuristic is "what is the simplest interface that covers all my
current needs?" and "in how many situations will this be used?"

Then the two ideas that pay off most in day-to-day work. **Define errors out of
existence**: the best exception is the one that cannot happen, achieved by
redefining the semantics so the awkward case is normal. His examples — Unix
`unlink` on an open file, Tcl's `unset`, a text editor where deleting an empty
selection is legal — all replace "caller must check and handle" with "the API
handles it." Every exception a module can throw is interface surface; masking or
aggregating them makes the module deeper. And **strategic versus tactical
programming**: tactical programming optimizes for getting this feature working
now, which is how every system degrades; strategic programming treats working
code as _not sufficient_, budgets roughly 10–20% of time on design investment,
and pays it continuously rather than in a rewrite. The **tactical tornado** is
his name for the prolific developer who ships fast and leaves wreckage, and who
management often rewards.

Two smaller rules with outsized effect. **Design it twice**: for any significant
decision, produce two genuinely different designs and compare, even if the first
seemed obviously right — the act of producing an alternative improves the chosen
one. And **comments**. Ousterhout's argument is structural, not stylistic: there
is information — the _why_, the invariants, the units, the intended abstraction —
that code fundamentally cannot express, because code expresses _what happens_,
not _what was intended_. Interface comments let a caller use a method without
reading its body, which is precisely what makes the module deep; without them,
every abstraction leaks by forcing implementation reading. He also argues for
**writing comments first**, as a design tool: if the interface comment is long
and awkward, the interface is bad, and you have learned that before writing the
code.

**Where the book is right for us.** The depth ratio is the single most useful
review heuristic we have. Our `@coachbot/database` repositories are deep in the
right way — `db.agents.findById(actorId, projectId, agentId)` hides SQL, caching,
project scoping, and masking. Our worst code is invariably shallow: a
`$lib/server/*.ts` file that renames arguments and forwards. "Define errors out
of existence" is directly applicable to our AI surface: an LLM call that can
fail, be moderated, or be rate-limited should return a discriminated result the
caller must handle _once_, not three exception types. And the strategic/tactical
frame is the honest description of what happens when you accept generated code
without design review: it is tactical programming at machine speed.

**Where the book is wrong or dated for a 2026 TS monorepo.** First, it is written
from a **C++/Java single-process mindset**, and its notion of "module" (roughly a
class) maps awkwardly onto our four scales: function, file, slice, workspace
package. Depth is scale-relative — a file that is shallow as a package can be
perfectly good as a file — and the book gives you no guidance for choosing the
scale at which to apply the test. Ours: apply depth at the _package_ and _slice_
boundary strictly, at the file boundary loosely, and at the function boundary
only as a tiebreaker.

Second, it **has almost nothing on the network, on concurrency, or on failure at
a distance**. "Define errors out of existence" is excellent advice for a library
call and dangerous advice for a distributed call: you cannot define a network
partition out of existence, and an API that hides a timeout by silently returning
a default is worse than one that surfaces it. Our qualifier: define _caller-side
awkwardness_ out of existence; never define _observable failure_ out of
existence — surface it as a typed result and log it.

Third, it **under-rates types**. Written for a world where the interface is a
comment, it treats documentation as the primary mechanism for conveying the
contract. In TypeScript, a branded ID, a discriminated union, or a
`Readonly<T>` moves part of the contract into the compiler, where it cannot rot.
Ousterhout's comment doctrine still holds for the _why_ and the invariants, but
"the type says it" is a legitimate answer to "where is the interface comment"
that the book does not anticipate.

Fourth, it is **weak on organizational scale**. It is a book about a codebase one
person can hold in their head. It has no story for team boundaries, deployment
units, or independent release — which is exactly what Richards/Ford supply. Depth
tells you a package is worth having; the architecture quantum tells you whether
it should be a separate deployable. Different questions.

**The Ousterhout-vs-Martin conflict, staged and resolved.** The two authors
debated publicly and the transcript is the primary source. On **function
length**, Martin: functions "should be small... they should be smaller than
that," and the One Thing Rule — if you can meaningfully extract, the original did
more than one thing. Ousterhout: stop decomposing when the pieces stop being
deep; over-decomposition produces _entanglement_, where a reader must jump
between five methods to understand one operation, and "when decomposed methods
are entangled, they are harder to read than if they were not decomposed." Martin
conceded in the debate that Clean Code offered no guidance for recognizing
over-decomposition; Ousterhout declined to give a hard line for when
decomposition becomes harmful. On **comments**, Martin: "comments are always
failures... a necessary evil," to be replaced by expressive names, and he does
not trust them to be maintained or read. Ousterhout: comments are "crucially
important... there is important information that simply cannot be expressed in
code," and interface comments are what let callers avoid reading
implementations. On **abstraction depth** more broadly, Martin optimizes for
separation of concerns and trusts names plus IDE navigation; Ousterhout optimizes
for cognitive load and trusts proximity plus documentation. On **TDD**, Ousterhout
prefers "bundling" — design, write a coherent unit, then test — arguing that tiny
red-green cycles keep you tactical and entrench a bad first design; Martin argues
strategic thought happens in the refactor step and short cycles prevent bug
accumulation.

**Our house position** (identical wording in `clean-architecture.md`, by design):

- **At the module and package boundary, Martin wins.** Dependency direction,
  SRP-as-axis-of-change, DIP, no framework types inward. Structural, checkable,
  undisputed by Ousterhout.
- **Inside a module, Ousterhout wins.** Function length is not a target and never
  a lint rule. Extract only when the extracted unit is _deeper_ than the code it
  replaces. A 60-line linear narrative with three comments beats six 10-line
  functions that must be read in sequence to be understood. If a reader must
  chase more than one hop to understand a single operation, the decomposition is
  wrong.
- **On comments, Ousterhout wins outright.** Interface comment on every exported
  symbol; _why_ comments in bodies; write the interface comment before the
  implementation and treat an awkward comment as a design smell. Do not write
  comments that restate the code — that is the part of Martin's critique that is
  correct.
- **On TDD, we split.** Design the boundary and write its interface comment
  first; then TDD _within_ the boundary. Never TDD your way into an architecture.
- **The tiebreaker when both books are silent:** prefer the option that reduces
  unknown unknowns, because that is the failure mode that reaches production.

One sentence: **Martin governs the arrows between boxes; Ousterhout governs the
inside of a box, and owns the veto on whether a box should exist at all.**

## Enforceable rules

| #     | Rule                                                                                                                                                                                                                  | How to check                                                                                                                              | Severity |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| PO-1  | Depth test at the package boundary: a workspace package's public surface (exported symbols in `index.ts`) must be small relative to its implementation — ratio ≥ 10 source lines per exported symbol                  | script over `tsc --emitDeclarationOnly` output vs `cloc` of `src`; report per package, fail on new packages below the ratio               | fix      |
| PO-2  | No pass-through functions: an exported function whose body is a single call with structurally unchanged arguments must be deleted and the caller rewired                                                              | AST rule (ts-morph): body is one `ReturnStatement` wrapping a `CallExpression` whose args are the params in order                         | block    |
| PO-3  | No pass-through parameters: a parameter threaded through ≥3 call frames without being read                                                                                                                            | manual review; partial automation via unused-in-body + forwarded-unchanged detection                                                      | note     |
| PO-4  | Adjacent layers must not have matching signatures — if `service.foo(a,b)` and `repo.foo(a,b)` have the same shape, one layer is redundant                                                                             | AST diff of exported signatures between `**/server/*.ts` and the repository it calls                                                      | fix      |
| PO-5  | Every exported symbol in a package `index.ts` has an interface comment stating what it does, its units/invariants, and its failure mode                                                                               | ESLint `jsdoc/require-jsdoc` scoped to `packages/*/src/index.ts` and re-exported declarations                                             | fix      |
| PO-6  | No comment that restates the code; comments state _why_, invariants, or units                                                                                                                                         | review only; reject `// increment i` class comments                                                                                       | note     |
| PO-7  | Options objects: every optional field must have a documented default and at least one call site that sets it to a non-default value                                                                                   | `knip`-style scan for never-overridden optionals; delete the option if none                                                               | fix      |
| PO-8  | Errors defined out of existence at the caller boundary: a module exposes at most one failure representation (a typed `Result`/discriminated union or a single error class), not a hierarchy the caller must switch on | review + count of distinct thrown/`Error` subclasses reachable from a public entrypoint (>2 = flag)                                       | fix      |
| PO-9  | Never define observable failure out of existence: timeouts, moderation blocks, rate limits and LLM errors must be represented in the return type and logged, never silently defaulted                                 | grep for `catch {}` / `catch (e) { return null }` in `packages/agents`, `packages/moderation`, `**/server/**`                             | block    |
| PO-10 | No temporal decomposition: modules named for a phase (`parse-*`, `validate-*`, `transform-*`) that each hold part of the same format knowledge must be merged                                                         | review of new module names against an existing sibling set                                                                                | fix      |
| PO-11 | Function length is not a lint rule and must not be added as one; `max-lines-per-function` stays off                                                                                                                   | grep the ESLint config; a PR enabling it needs an ADR                                                                                     | block    |
| PO-12 | Design-it-twice: any change touching a package boundary, a schema, or an agent prompt records two considered options and why one lost (one paragraph in the MR, or an ADR if irreversible)                            | MR template checkbox + CI check for the `## Options considered` heading on diffs touching `packages/*/src/index.ts` or `db/migrations/**` | fix      |
| PO-13 | Package-by-feature: a new file goes in the slice that owns the concept, not in a layer bucket; `services/`, `helpers/`, `utils/`, `managers/` are denied as new directory names                                       | directory-name denylist lint over `apps/*/src/lib/*` and `packages/*/src/*`                                                               | fix      |
| PO-14 | Zero business logic in route handlers: handlers parse, authorize, delegate, shape. No branching on domain values                                                                                                      | review + handler line budget (see fitness functions)                                                                                      | fix      |
| PO-15 | No framework types in domain modules — the domain must be testable with no SvelteKit, no HTTP, no live DB                                                                                                             | Vitest node-environment project for `packages/**` and `**/domain/**`                                                                      | block    |

## Design review prompts

Ask before code exists. Each is falsifiable.

1. For each proposed module: what exactly must a caller know to use it (the full
   interface — names, types, ordering constraints, error cases, invariants), and
   how many lines of implementation does that buy? State the ratio.
2. Which of these modules would still be worth having if it had exactly one
   caller forever?
3. Name the design decision each module hides. If a decision is reflected in two
   modules, which one owns it and why does the other need to know?
4. Where is the same knowledge (a format, an ID shape, an authorization rule, a
   score-weighting rule) written down more than once? What breaks if they drift?
5. Are any of these modules named for a _phase_ rather than for _knowledge_? If
   so, which format or rule is now spread across them?
6. What does a caller have to do if this operation fails? Can we redefine the
   semantics so that the awkward case is simply normal — and if we do, are we
   hiding a caller inconvenience (good) or an observable failure (forbidden)?
7. Write the interface comment for the main entrypoint _now_, before the code. Is
   it short and clear? If it is long, awkward, or full of "unless", what is the
   interface getting wrong?
8. Which piece of this design will produce an unknown unknown — where would a
   future change silently need to touch a file nobody would think to open?
9. What is the second design? Describe a genuinely different structure and say
   why it lost. "I didn't consider one" is a failing answer.
10. Which parts of the contract can move into the type system (branded IDs,
    discriminated unions, `readonly`) instead of into prose?
11. How many new configuration options or env vars does this add, and for each,
    which caller sets it to a non-default value on day one?
12. If this design is the wrong one, at what point do we find out, and what does
    it cost to reverse then?

## Fitness functions

Automatable checks for a pnpm/TS monorepo. Depth is the hard one — these are the
approximations that actually work.

**1. Package depth ratio (the flagship check)**

```ts
// scripts/arch/depth-report.ts
// For each workspace package:
//   surface = count of exported symbols in the emitted index.d.ts
//             (ts-morph: getExportedDeclarations().size)
//   volume  = non-blank, non-comment source lines under src/, excluding *.spec.ts
//   depth   = volume / surface
// Print a sorted table; fail CI if a NEW package lands with depth < 10,
// or if an existing package's depth drops >25% in one MR (surface grew
// faster than the thing it hides).
```

This is a proxy, and it is honest about being one: it catches the real failure
mode (a package that exports 40 things and implements 200 lines) without
pretending to measure understanding.

**2. Pass-through detector (PO-2)**

```ts
// scripts/arch/no-passthrough.ts — ts-morph AST rule
// Flag every exported FunctionDeclaration / ArrowFunction where:
//   - body is a single return (or single expression), AND
//   - the returned expression is a CallExpression, AND
//   - its arguments are exactly the parameters, in order, unmodified
// Allowlist: re-export barrels, and functions with a `// depth: <reason>` comment.
// Exit 1 on any unallowlisted hit.
```

**3. Adjacent-layer signature collision (PO-4)**

```ts
// For each apps/*/src/lib/*/server/*.ts, collect exported signatures.
// For each repository it imports, collect those signatures.
// Report pairs with identical (arity, param type names, return type name).
// >0 identical pairs => "layer adds no depth" warning with both file:line.
```

**4. Interface-comment coverage (PO-5)**

```js
// eslint.config.js
{
  files: ['packages/*/src/index.ts', 'packages/*/src/**/index.ts'],
  plugins: { jsdoc },
  rules: {
    'jsdoc/require-jsdoc': ['error', {
      publicOnly: true,
      require: { FunctionDeclaration: true, ClassDeclaration: true },
      contexts: ['TSInterfaceDeclaration', 'TSTypeAliasDeclaration'],
    }],
    'jsdoc/require-description': 'error',
  },
}
```

**5. Silent-failure ban (PO-9)**

```bash
# scripts/arch/no-silent-catch.sh
rg -n --type ts \
  -e 'catch\s*(\([^)]*\))?\s*\{\s*\}' \
  -e 'catch\s*\([^)]*\)\s*\{\s*return (null|undefined|\[\]|\{\})\s*;?\s*\}' \
  packages/agents packages/moderation packages/database apps/*/src/lib/server \
  && { echo 'PO-9: swallowed failure'; exit 1; } || exit 0
```

**6. Cognitive-load budget on route handlers (PO-14)**

```bash
# Non-import, non-blank lines in any +server.ts / +*.server.ts must be <= 60.
# Rationale: a handler over that budget is holding policy it should delegate.
```

**7. Config-sprawl gauge (PO-7)**

Count `process.env.` reads outside each app's single `env.ts`, and count
never-overridden optional fields across exported options interfaces (`ts-morph`
scan of call sites). Both are reported as a number in CI; a rising number is the
signal, an absolute threshold is not.

**8. Unknown-unknowns proxy: change amplification.** For the last N merged MRs,
record `files_changed` per Linear issue and per changed _concept_. A feature-add
touching >8 files across >3 packages is a change-amplification report, not a
lint error — review the top offenders monthly and fix the placement, not the MR.

**9. Complexity trendline.** `eslint-plugin-complexity` (cyclomatic) and
`ts-prune`/`knip` dead-export counts reported per build, stored, and graphed.
Ousterhout's point is that complexity is _incremental_; only a trendline can see
an incremental problem. No gate — a gate here just teaches people to game it.

## Applied to a package-by-feature TS monorepo

Slice by concept, then make each piece deep. The test for every file you are
about to create: _what does a caller no longer have to know because this file
exists?_ If the answer is "nothing", do not create it.

```
packages/
  types/src/feedback.ts               # branded ids, plain DTOs. Deep by being
                                      # the ONLY definition of the shape.
  database/src/repositories/
    message-feedback.repository.ts    # DEEP: interface is 4 actor-first fns;
                                      # hides SQL, project-scoping join,
                                      # cache invalidation, outbox write.

apps/studio/src/lib/feedback/
  domain/
    score.ts                          # DEEP: exports aggregate(feedback[]):Score
                                      # hides weighting, recency decay,
                                      # min-sample rule. Pure. No DB, no HTTP.
    score.spec.ts
  server/
    record-feedback.ts                # DEEP only if it does >1 thing:
                                      # authorize + aggregate + persist + emit
                                      # Langfuse score, behind one call.
    record-feedback.spec.ts
  ui/
    ScoreBadge.svelte                 # DEEP: takes a Score, hides thresholds,
    FeedbackButtons.svelte            # colour tokens, a11y labels.
  index.ts                            # the slice's public surface: 3-5 exports

apps/studio/src/routes/(app)/projects/[projectId]/feedback/
  +page.server.ts                     # deliberately SHALLOW adapter, <=60 lines
```

Concrete depth moves, in the order they pay off:

- **Push complexity down, not up.** The repository owns the project-scoping join;
  it does not export `withProjectScope()` for callers to remember to call. Every
  "the caller must remember to..." is interface surface.
- **Make the interface general, the implementation specific.** `aggregate(items)`
  beats `aggregateForCoachDashboard(coachId, since, weights)`. The general
  signature is smaller _and_ survives the second caller.
- **Collapse the layer that renames.** If `record-feedback.ts` is
  `(a,b,c) => repo.record(a,b,c)`, delete it; the route calls the repository. One
  layer of nothing is worse than no layer (PO-2, PO-4).
- **Define the awkward case away.** Recording feedback on a message that already
  has feedback should _upsert_, not throw `AlreadyExistsError`. Deleting feedback
  that does not exist should succeed. Both remove a branch from every caller.
- **But surface real failure.** The Langfuse emission can fail; it returns a
  typed result and is logged, never swallowed (PO-9). Persist-then-emit through
  the outbox rather than pretending the emission cannot fail.
- **One shape, derived views.** `Feedback` lives in `@coachbot/types`; the API
  DTO is `Omit<Feedback, 'internalNote'>`, not a hand-written twin.
- **Interface comment first.** Write the JSDoc for `aggregate` before its body.
  If it needs three "unless" clauses, the aggregation rule is wrong, and you
  learned that for free.

Cross-slice: a slice imports another slice only through its `index.ts`. If two
slices import each other, they are one slice — merging them removes interface
surface, which is the whole point.

## Anti-patterns specific to AI-generated code

Generated code is _structurally fluent and semantically shallow_: it reproduces
the shape of well-organized code without the depth that made the shape worth
having. Ousterhout's vocabulary names each failure precisely.

**1. Shallow pass-through modules.** The dominant failure. A model asked for a
"service layer" produces `export const getX = (id) => repo.findX(id)` for eight
entities. Interface surface: eight functions. Complexity hidden: zero. Worse than
nothing, because now there are two places to look and a reader cannot tell which
holds the rules. _Counter-moves:_ PO-2 as a hard AST gate; the review question
"what does a caller no longer need to know?"; and a standing instruction in the
generation prompt — "do not add a layer that only renames arguments."

**2. Layer duplication / change amplification.** The same field defined as a DB
column type, a repository row type, a service DTO, an API schema, and a Svelte
prop, with four mappers. Adding one field becomes a nine-file diff, and every
mapper is a place to silently drop it. This is textbook change amplification
caused by information leakage — the shape is a design decision reflected in five
modules. _Counter-moves:_ one owned shape in `@coachbot/types`, derived via
`Pick`/`Omit`; mappers allowed only where the shapes genuinely differ
(redaction, masking) and required to carry a comment saying which; the
change-amplification report (fitness function 8) to catch it in aggregate.

**3. Interface-for-one-implementation.** `IFeedbackRepository` plus one concrete
class plus a DI token, in a language with structural typing where a test double
is an object literal. Pure interface surface, zero hidden complexity, and it
makes navigation worse (go-to-definition lands on the interface). _Counter-moves:_
abstractions are earned on the second implementation or the first genuine
double; `knip` for single-implementer interfaces; and note that
`Pick<typeof repo, 'record'>` is a better narrowing tool than a declared
interface.

**4. Config sprawl.** Each generated feature invents env vars, an options object
with eight optionals, its own defaults, its own validation. Every optional is
interface surface the caller must evaluate, and Ousterhout's point is that most
are never set. It also multiplies unknown unknowns: nobody knows which
combination is tested. _Counter-moves:_ PO-7 (an optional needs a real non-default
call site or it dies); all env access through one `env.ts`; new config needs an
ADR; prefer "define the error out of existence" — pick the right behavior rather
than exposing a flag for both.

**5. Premature microservice / premature package.** Extraction for code with one
consumer and no independent deploy story. Depth says: a package must hide
something from someone who is not you. One consumer, same deploy, same team =
not a package. _Counter-move:_ ADR gate on new workspace packages; default answer
"keep it in the slice until a second consumer appears"; use the architecture
quantum test (independent deploy cadence / scaling profile / failure domain)
before any new deployable.

**6. Comment inversion.** Models write copious `// increment the counter` noise
and omit the interface comment that would actually make the module deep — exactly
backwards from our doctrine. _Counter-move:_ PO-5 gates the comment that matters
(exported symbols); PO-6 rejects restatement in review; prompt instruction:
"JSDoc every export with purpose, units, invariants, and failure mode; do not
narrate the body."

**7. Entanglement by over-extraction.** Given Clean Code in its training set, a
model will happily split a 40-line coherent operation into six 7-line functions
that must be read in order. This is the exact failure Ousterhout named and Martin
conceded he gave no guidance against. _Counter-move:_ PO-11 (never enable
`max-lines-per-function`), and the review rule — if understanding one operation
requires more than one navigation hop, inline it back.

**8. Tactical velocity.** The deepest one. Generation makes tactical programming
nearly free, so the accumulated-complexity curve steepens without anyone making a
visible bad decision. _Counter-move:_ the strategic budget is structural, not
optional — design-it-twice (PO-12) on every boundary-touching change, and the
complexity trendline (fitness function 9) reviewed monthly so the incremental
problem has somewhere to show up.

## Sources

- https://web.stanford.edu/~ouster/cgi-bin/aposd.php — the book's official page (Ousterhout, Stanford)
- https://github.com/johnousterhout/aposd-vs-clean-code — the Ousterhout/Martin debate transcript: method length, comments, TDD, with both authors' positions in their own words
- https://www.mattduck.com/2021-04-a-philosophy-of-software-design.html — chapter-level notes: deep modules, pull complexity down, pass-through elements, define errors away, design twice, strategic vs tactical
- https://softengbook.org/articles/deep-modules — Ousterhout's own "Modules Should Be Deep" article
- https://dev.to/gosukiwi/software-design-deep-modules-2on9 — worked deep-vs-shallow examples
- https://www.sandordargo.com/blog/2023/01/25/deep-vs-shallow-modules — depth ratio applied in practice
- https://tryingthings.wordpress.com/2025/02/25/aposd-vs-clean-code-a-debate/ — third-party analysis of the debate's substance
- https://blog.cleancoder.com/uncle-bob/2020/10/18/Solid-Relevance.html — Martin's side, for the boundary-level half of our house position
