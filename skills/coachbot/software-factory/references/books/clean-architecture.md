# Clean Architecture — Robert C. Martin, 2017

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

Clean Architecture is the only one of our three references that gives a
_directional_ rule strong enough to be mechanically checked: dependencies point
inward, toward policy, away from detail. Everything else in the book — SOLID,
screaming architecture, boundaries, humble objects — is downstream of that one
arrow. In a monorepo where an LLM can generate a plausible-looking file in any
directory in under a second, a directional rule is worth more than a taste rule,
because a directional rule can be a lint error.

We keep it in the loop for three jobs:

1. **Deciding which package a new file belongs in.** `@coachbot/database`,
   `@coachbot/permissions`, `@coachbot/agents`, `apps/studio/src/lib/server` —
   the dependency rule answers "may this import that" without a debate.
2. **Keeping SvelteKit out of the domain.** Our highest-value logic (session
   graph traversal, permission resolution, moderation) must be runnable in a
   Vitest process with no `RequestEvent`, no `locals`, no cookie jar. That is
   Martin's testability claim, and it is the one we cash in weekly.
3. **Naming the boundary where a trade-off got made,** so an ADR gets written.

We explicitly do _not_ keep it in the loop for its function-level advice. That is
where Ousterhout wins (see below).

## The argument (deep prose)

Martin's thesis is that software has two distinct values, and the industry
systematically prices them backwards. The **behavior** of a system is what it
does today — the urgent value, the one stakeholders can see. The **architecture**
of a system is the cost of changing what it does tomorrow — the important value,
the one nobody can see until it is gone. His famous framing is that a system
whose behavior is perfect but which cannot be changed is worthless, whereas a
system whose behavior is wrong but which is soft is merely incorrect and can be
fixed. The whole book is an argument that architects should spend their
political capital defending the invisible value against the visible one. The
mechanism he proposes for defending it is not process, not documentation, but
_the direction of source-code dependencies_.

The core construct is the concentric-circle diagram: **Entities** (enterprise-wide
business rules, the things that would still be true if the company sold the
software and kept only the business), **Use Cases** (application-specific rules
that orchestrate entities), **Interface Adapters** (controllers, presenters,
gateways — the translation layer), and **Frameworks and Drivers** (the web, the
database, the UI toolkit). The **Dependency Rule** states it exactly: _source
code dependencies can only point inwards. Nothing in an inner circle can know
anything at all about something in an outer circle._ Not the name of a class,
not a function, not a variable, and emphatically not a data format. Where the
flow of control needs to cross outward — a use case needs to write to a database
— you invert the dependency: the use case declares an interface, the outer ring
implements it. Control flows out; source dependency still points in. Martin
calls the data that crosses a boundary a set of "simple data structures":
never an ORM row, never a framework request object, never an entity handed
wholesale to a view.

SOLID is the class-and-module-level scaffolding that makes the dependency rule
achievable. Martin's own restatements are more useful than the mnemonic
expansions: SRP is "gather together the things that change for the same reasons,
separate things that change for different reasons" — an axis-of-change rule about
_actors_, not a "do one thing" rule about size. OCP is about arranging modules so
that a new requirement is a new module rather than an edit to a proven one. LSP
he generalizes past inheritance: "a program that uses an interface must not be
confused by an implementation of that interface." ISP says don't force a client
to depend on methods it doesn't use. DIP is the load-bearing one: "depend in the
direction of abstraction; high-level modules should not depend on low-level
details." DIP is the dependency rule expressed at the module scale, and it is the
reason the concentric circles can exist at all.

Screaming Architecture is the corollary at the top-level directory: the folder
tree should announce the _domain_, not the framework. Architectural plans for a
library show the reading room and the check-in desk, not the brand of concrete.
A codebase whose top level is `controllers/ models/ views/ services/` is
screaming "Rails" (or SvelteKit, or Spring). Martin's claim is that the web is a
delivery mechanism and the database is a storage detail; both should be
pluggable, and the proof of pluggability is that the use cases have tests that
run without either. This is where "package by feature, not by layer" actually
comes from, though Martin never phrases it that crisply.

**Where the book is right for us.** The direction rule is right and it is cheap
to enforce. Our `@coachbot/database` repositories already encode a version of it
with actor-first signatures — the repository is a gateway, the caller supplies
identity, and the repository does not know that a SvelteKit route exists. The
insistence that framework types must not leak inward is right and we violate it
regularly and pay for it: the moment a service function takes `RequestEvent`, it
is untestable without a fake request, and untestable code stops being tested.
The "simple data structures cross boundaries" rule is right and maps directly
onto our branded IDs in `@coachbot/types`. Screaming architecture is right about
the top level of a _feature_, and it is the reason `apps/studio/src/lib/knowledge`
is a better home than `apps/studio/src/lib/services`.

**Where the book is wrong or dated for a 2026 TypeScript monorepo.** Four things.

First, **the cost model assumes a compiled, deployable-unit-per-layer world.**
Much of Martin's boundary machinery — Humble Objects, elaborate gateway
hierarchies, the four-ring diagram taken literally — exists to manage
compile-time and deploy-time coupling in Java and C#. In a pnpm workspace,
package boundaries are nearly free (a `package.json` and a `tsconfig` reference),
and TypeScript's structural typing means an interface is often a comment with
compiler support rather than a runtime artifact. The consequence is that Clean
Architecture's _ceremony_ is overpriced here while its _direction_ is underpriced.
Take the arrow; leave the four rings.

Second, **it under-weights the cost of indirection.** The book has essentially no
counterweight against too many layers. Every chapter argues for another boundary;
none argues for removing one. Applied literally to a CRUD-ish SvelteKit route you
get route → controller → use-case interactor → gateway interface → repository
implementation → SQL, where four of those six do nothing but rename their
argument. Ousterhout's shallow-module test is the missing counterweight, and we
apply it on top.

Third, **"the database is a detail" is false for us in the way that matters.**
Our system's hardest constraints are relational and authorization-shaped:
Postgres row semantics, transactional outbox, SpiceDB ReBAC checks, project
scoping enforced by a join through `agents`. Pretending Postgres is swappable
would cost us real correctness (we would push joins into application code and
lose consistency) to buy an option we will never exercise. The honest version of
the rule for us is narrower and still valuable: _no SQL strings and no driver
types above the repository layer_. Not "the database is a detail" — "the database
client is a detail".

Fourth, **the book has nothing to say about non-deterministic components.** An
LLM call is not a gateway you can stub and forget: it has cost, latency,
variance, and a quality dimension. Clean Architecture gives you no vocabulary for
"this boundary is a probabilistic function". Richards/Ford's fitness functions
do, which is why we run the two books together rather than either alone.

**The Ousterhout-vs-Martin conflict, staged and resolved.** Martin and Ousterhout
publicly debated three points — method length, comments, and TDD — and the
transcript is worth reading in full. Martin: "the first rule of functions is that
they should be small; the second rule is that they should be smaller than that,"
plus the One Thing Rule — if you can meaningfully extract a method, the original
did more than one thing. Ousterhout: decomposition should stop when methods stop
being _deep_; over-decomposition produces "entanglement," where understanding one
method requires reading five others, and "when decomposed methods are entangled,
they are harder to read than if they were not decomposed." On comments, Martin
calls them "always failures... a necessary evil," to be replaced with better
names; Ousterhout calls them essential, carrying information — the _why_, the
invariants, the units — that code structurally cannot express. Martin later
conceded that Clean Code offered no guidance for recognizing over-decomposition.

**Our house position.** The conflict is real but it is scoped, and it resolves
cleanly by altitude:

- **At the module and package boundary, Martin wins.** Direction of dependency,
  SRP-as-axis-of-change, DIP, no framework types inward. These are structural,
  checkable, and Ousterhout does not dispute them.
- **Inside a module, Ousterhout wins.** Function length is not a target. Extract
  a function when it creates a _deeper_ unit — real complexity hidden behind a
  smaller interface — never merely because the parent exceeded a line count. A
  60-line function with a linear narrative and three comments beats six 10-line
  functions that must be read in order to be understood.
- **On comments, Ousterhout wins outright.** We write interface comments on every
  exported function, and we write _why_ comments in bodies. Martin's position
  presupposes that names can carry invariants and rationale; in TypeScript they
  demonstrably cannot.
- **On TDD, we split.** Ousterhout's warning is that tiny red-green cycles keep
  you tactical and entrench a bad first design. Martin's is that long cycles let
  bugs accumulate. Our rule: design first (write the boundary and the interface
  comments), then TDD _within_ the boundary. Never TDD your way into an
  architecture.

The one-sentence version: **Martin governs the arrows between boxes; Ousterhout
governs the inside of a box. When they collide, altitude decides.**

## Enforceable rules

| #     | Rule                                                                                                                                                                                                                               | How to check                                                                                                                                        | Severity |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| CA-1  | Source dependencies point inward: `apps/**` may import `packages/**`; `packages/**` must never import `apps/**`                                                                                                                    | ESLint `no-restricted-imports` / dependency-cruiser rule `no-app-imports-from-package`; also detectable as a missing workspace dep                  | block    |
| CA-2  | Domain and repository code must not import framework types (`@sveltejs/kit`, `$app/*`, `$env/*`, `svelte`)                                                                                                                         | grep/dependency-cruiser: forbid those specifiers under `packages/**` except `packages/sveltekit-auth` and `packages/*-ui`                           | block    |
| CA-3  | No SQL strings and no `pg`/driver types above `packages/database/src/repositories/**`                                                                                                                                              | grep for `SELECT `/`INSERT INTO`/`from 'pg'` outside the repository dir                                                                             | block    |
| CA-4  | Route handlers (`+page.server.ts`, `+server.ts`) contain no business logic: only parse → authorize → delegate → shape response                                                                                                     | line budget (>60 lines of non-import code in a handler = review) + no `db.` calls with branching logic; must call a named `$lib/server/**` function | fix      |
| CA-5  | Nothing crosses a package boundary except plain data and branded IDs from `@coachbot/types` — no ORM row objects, no `RequestEvent`, no `Response`                                                                                 | review + type-level: exported signatures in `packages/*/src/index.ts` must not reference framework types                                            | block    |
| CA-6  | Every cross-package import goes through the package's public entrypoint, never a deep path (`@coachbot/database/src/...`)                                                                                                          | ESLint `no-restricted-imports` with pattern `@coachbot/*/src/**`                                                                                    | block    |
| CA-7  | Package graph is acyclic — no import cycle between workspace packages                                                                                                                                                              | dependency-cruiser `no-circular` at package granularity; also `pnpm ls --depth Infinity` sanity                                                     | block    |
| CA-8  | Package-by-feature above package-by-layer inside an app: `src/lib/<feature>/{ui,server,domain}`, not `src/lib/{services,models,controllers}`                                                                                       | directory-name denylist lint on `apps/*/src/lib/*`                                                                                                  | fix      |
| CA-9  | Interface Segregation at the repository level: a consumer importing a repository must use ≥2 of its exported functions, or take a narrower type                                                                                    | manual review; `ts-prune`/`knip` for unused exports                                                                                                 | note     |
| CA-10 | ADR required for: adding a workspace package, adding a runtime dependency to `packages/database` or `packages/agents`, introducing a new deployable (quantum), changing a published API shape, or inverting an existing dependency | reviewer check: the change is accompanied by `~/project-workspace/Tasks/<slug>/02-adr-<n>.md` (planning artefacts live outside the repo per CLAUDE.md; `docs/adr/` does not exist)                                                                          | block    |
| CA-11 | Business rules must have at least one test that runs with no HTTP server and no SvelteKit adapter                                                                                                                                  | test file location: `packages/**/*.spec.ts` runs under plain Vitest node environment                                                                | fix      |
| CA-12 | No `any` or `as unknown as` at a package boundary (exported signatures)                                                                                                                                                            | `@typescript-eslint/no-explicit-any` scoped to `src/index.ts` and `src/**/index.ts`                                                                 | fix      |

## Design review prompts

Ask these of a written design, before any code exists. Each must be answerable
with a fact, not an opinion.

1. Draw the arrows: which module depends on which? Is there any arrow pointing
   from a business rule toward SvelteKit, Postgres, SpiceDB, or the AI SDK?
2. If we deleted the HTTP layer entirely, which files would still compile and
   which tests would still pass? Name them.
3. What is the _axis of change_ for each new module — which actor or requirement
   causes it to be edited? If two actors edit the same module, why is that not
   two modules?
4. What exact data types cross each boundary? Are any of them a database row, a
   `RequestEvent`, or a Zod-inferred type owned by the wrong side?
5. Which of these interfaces has exactly one implementation and no test double?
   Justify its existence or delete it.
6. Where does the control flow go outward while the source dependency points
   inward — i.e. where is the inversion, and who owns the interface?
7. If a reader opens the top-level folder of this feature, what do they learn:
   what the feature _does_, or which framework we use?
8. Which decision here is expensive to reverse? Is there an ADR for it, and does
   it state the option we rejected?
9. What happens to this design if the storage is Postgres forever? Does anything
   we are building only pay off under a swap that will never happen?
10. Which layer will an LLM most likely add a pass-through file to next month,
    and what lint rule stops it?
11. Is any new package justified by a _deployment_ or _ownership_ boundary, or
    only by a naming preference?
12. What is the smallest version of this design that still satisfies the
    dependency rule? Why are we not shipping that one?

## Fitness functions

Concrete, automatable, for a pnpm + TS + Turborepo workspace. These are sketches
you can paste and adapt.

**1. Import-boundary lint (ESLint flat config, in `packages/eslint-config`)**

```js
// applies to packages/** — the inner rings
{
  files: ['packages/*/src/**/*.ts'],
  rules: {
    'no-restricted-imports': ['error', {
      patterns: [
        { group: ['@sveltejs/kit', '$app/*', '$env/*'],
          message: 'CA-2: framework types must not leak into packages/**' },
        { group: ['../../../apps/**', '@coachbot/*/src/**'],
          message: 'CA-1/CA-6: no inward-pointing app imports, no deep imports' },
      ],
    }],
  },
}
```

**2. dependency-cruiser rules (`.dependency-cruiser.cjs`)**

```js
module.exports = {
  forbidden: [
    {
      name: "no-circular",
      severity: "error",
      from: {},
      to: { circular: true },
    },
    {
      name: "no-orphans",
      severity: "warn",
      from: { orphan: true, pathNot: "\\.d\\.ts$|\\.spec\\.ts$" },
      to: {},
    },
    {
      name: "packages-never-import-apps",
      severity: "error",
      from: { path: "^packages/" },
      to: { path: "^apps/" },
    },
    {
      name: "domain-free-of-framework",
      severity: "error",
      from: { path: "^packages/(database|agents|permissions|moderation)/src" },
      to: {
        dependencyTypes: ["npm"],
        path: "node_modules/(@sveltejs|svelte|vite)",
      },
    },
    {
      name: "routes-do-not-touch-db-directly",
      severity: "error",
      from: { path: "\\+(page|layout)?\\.server\\.ts$|\\+server\\.ts$" },
      to: { path: "^packages/database/src/repositories" },
    },
    {
      name: "no-deep-package-imports",
      severity: "error",
      from: {},
      to: {
        path: "^packages/[^/]+/src/(?!index\\.ts)",
        pathNot: "^packages/\\1/",
      },
    },
  ],
};
```

Run as `pnpm depcruise --config .dependency-cruiser.cjs apps packages` in the
`ci` pipeline; it exits non-zero on any `error` rule.

**3. Package-graph acyclicity + layer assertion (a script, not a lint)**

```ts
// scripts/arch/assert-package-graph.ts
// Reads every packages/*/package.json + apps/*/package.json, builds the
// workspace dependency DAG from `dependencies` on @coachbot/* only.
const LAYER: Record<string, number> = {
  "@coachbot/types": 0,
  "@coachbot/observability": 0,
  "@coachbot/permissions": 1,
  "@coachbot/database": 2,
  "@coachbot/agents": 3,
  "@coachbot/sveltekit-auth": 4,
};
// assert: for every edge a -> b, LAYER[a] > LAYER[b]  (strictly inward)
// assert: DFS finds no back edge (acyclic)
// exit(1) with the offending edge printed.
```

This is the highest-value single check we can add: it makes the dependency rule a
number, and a number can regress a build.

**4. Framework-free test fitness function**

```jsonc
// vitest.workspace.ts — packages/** run in a node environment with no
// SvelteKit plugin at all. If a package needs the plugin to compile, it has
// leaked a framework dependency and the suite fails to load. That failure IS
// the fitness function.
```

**5. Handler-thinness budget**

```bash
# scripts/arch/handler-budget.sh — CA-4
# Fails if any +server.ts / +page.server.ts exceeds 60 non-import, non-blank lines.
find apps/*/src/routes -name '+*.server.ts' -o -name '+server.ts' \
| while read f; do
    n=$(grep -vcE '^\s*($|//|import |export type )' "$f")
    [ "$n" -gt 60 ] && echo "CA-4 over budget ($n): $f"
  done | tee /dev/stderr | grep -q . && exit 1 || exit 0
```

**6. ADR-presence gate**

> **Not runnable as written here.** ADRs live outside the repo in
> `~/project-workspace/Tasks/<slug>/` per CLAUDE.md, so CI cannot see them.
> Keep this sketch only as the shape to use *if* ADRs ever move in-repo; today
> CA-10/FA-2 are enforced by reviewer check at Gate 2.

```bash
# CI: if the diff adds a workspace package or touches packages/database/package.json
# dependencies, require a new docs/adr/*.md in the same diff.
git diff --name-only origin/main... | grep -qE '^packages/[^/]+/package\.json$' \
  && ! git diff --name-only origin/main... | grep -q '^docs/adr/' \
  && { echo 'CA-10: architecture change without an ADR'; exit 1; }
```

**7. Public-surface diff alarm.** Snapshot each package's `index.ts` exported
symbol list (via `tsc --emitDeclarationOnly` + a hash) and fail the build when it
changes without a changeset. A boundary that moves silently is not a boundary.

## Applied to a package-by-feature TS monorepo

The unit of slicing is a **feature**, and a feature is _vertical_: it owns its
route, its server service, its domain rules, its persistence access, and its UI.
It is _not_ a layer spread across four folders. The dependency rule then applies
_within_ the slice (UI → server → domain, never back) and _between_ slices
(slices talk through published package entrypoints, never through each other's
internals).

Concretely, for a "coach feedback scores" feature in this repo:

```
packages/
  types/src/feedback.ts              # branded ids + plain DTOs (ring 0)
  database/src/repositories/
    message-feedback.repository.ts   # gateway: actor-first, SQL lives here only
    message-feedback.repository.spec.ts
apps/studio/src/lib/feedback/        # the vertical slice — screams "feedback"
  domain/
    score.ts                         # pure rules: aggregation, thresholds
    score.spec.ts                    # runs with no DB, no HTTP
  server/
    record-feedback.ts               # use case: authorize -> domain -> repo -> outbox
    record-feedback.spec.ts
    langfuse-feedback.ts             # adapter to an outer-ring service
  ui/
    FeedbackButtons.svelte           # imports only @coachbot/ui primitives
    ScoreBadge.svelte
  index.ts                           # the slice's public surface
apps/studio/src/routes/(app)/projects/[projectId]/feedback/
  +page.server.ts                    # <=60 lines: parse, authorize, delegate
  +server.ts
```

**How to make each piece deep rather than shallow:**

- **The repository is deep by construction** if its interface is
  `recordFeedback(actorId, projectId, messageId, score)` and its implementation
  holds the SQL, the project-scoping join, the cache invalidation, and the
  outbox insert. It becomes shallow the moment you add
  `beginTransaction()/commit()` to its surface — that is pulling complexity up.
- **The use case is deep** if it takes plain arguments and returns a plain
  result, and internally handles the permission check, the domain computation,
  the persistence call, and the Langfuse score emission. It is shallow if it is
  `return repo.recordFeedback(...)` with the arguments renamed — in that case
  delete it and let the route call the repository directly. One layer of nothing
  is worse than no layer.
- **The domain module is deep** if `score.ts` exports
  `aggregate(feedback[]): CoachScore` and hides the weighting, the recency decay,
  and the minimum-sample rule. It is shallow if it exports `weight()`, `decay()`,
  and `minSamples()` and makes the caller assemble them.
- **The route is deliberately shallow, and that is correct.** A route is an
  adapter; adapters are allowed to be thin because they add no policy. The rule
  is that they must be thin _and_ contain no policy — a fat route is a policy
  leak, a thin route with an `if (score > 3)` in it is worse.
- **The UI imports only `@coachbot/ui` primitives and the slice's own
  components**, never another slice's internals, never a repository.

Cross-slice rule: if `feedback` needs something from `knowledge`, it imports
`$lib/knowledge` (the slice's `index.ts`), and if that import is bidirectional,
the shared thing belongs in a third place — usually `packages/types` or
`$lib/shared`. A cycle between two slices is the signal that they are one slice.

## Anti-patterns specific to AI-generated code

Generated code fails in a characteristic direction: it produces _structure that
looks like the training corpus_ rather than structure that reduces complexity.
The five that hurt most here, with counter-moves.

**1. Shallow pass-through modules.** The model writes
`export const getFeedback = (id) => repo.findFeedback(id)` in a "service" file
because services exist in the corpus. Interface surface added: one function.
Complexity hidden: zero. _Counter-move:_ the depth test as an explicit review
gate — a new module must hide at least one decision the caller would otherwise
have to make. Automate the cheap half: flag any exported function whose body is a
single call expression with unchanged arguments (an AST rule over
`packages/*/src/**` and `apps/*/src/lib/*/server/**`).

**2. Layer duplication.** Asked to add a field, the model adds it to the DB type,
the repository type, a service DTO, a route DTO, and a Svelte prop — five
near-identical shapes with hand-written mappers between them. Change
amplification by a factor of five, and each mapper is a place to drop a field
silently. _Counter-move:_ one owned shape per concept in `@coachbot/types`,
derived types via `Pick`/`Omit`, and a rule that a mapper function is only
allowed where the two shapes genuinely differ (redaction, masking, denormalizing)
— and then it gets a comment saying which. Detect with a duplicate-interface
scan (`jscpd` over `*.d.ts`-shaped declarations).

**3. Interface-for-one-implementation.** `IFeedbackRepository` +
`PostgresFeedbackRepository` + a DI token, for a repository that will have one
implementation forever and is already trivially fakeable in TypeScript via a
structural object literal. This is Martin's DIP cargo-culted from Java.
_Counter-move:_ interfaces are earned, not granted. Introduce the abstraction on
the _second_ implementation or the first genuine test-double need. Enforce with
`knip`/`ts-prune` for single-implementer interfaces plus review rule CA-9.

**4. Config sprawl.** Every generated feature invents its own env var, its own
`options` object with eight optional fields, its own defaults, and its own
validation. Ousterhout's point applies exactly: each option is interface surface
the caller must now understand, and most options are never set to a non-default
value. _Counter-move:_ new config requires an ADR (CA-10) and a named consumer;
options objects must be non-optional where a sane default exists (define the
error out of existence); all env access goes through the app's single
`src/lib/server/env.ts` — grep-enforceable that `process.env` appears nowhere
else.

**5. Premature microservice / premature package.** "This should be its own
service" or "let's extract a package" for code with one consumer and no separate
deploy, scale, or ownership story. Richards/Ford's architecture quantum is the
test: a new deployable is justified only when it has an independent deployment
cadence, an independent scaling profile, or an independent failure domain. A new
_package_ is justified when it has ≥2 consumers or a genuinely different release
cycle. _Counter-move:_ CA-10's ADR gate on adding a workspace package, and the
default answer "put it in the slice until a second consumer appears."

**6. Fallback-beside-the-old-thing.** Generated diffs prefer adding a new
code path next to the old one over deleting the old one, because deletion is
risky-looking. Over ten diffs you get a file with four ways to do the same thing
and no way to tell which is live. _Counter-move:_ explicit license to delete
inside owned paths, plus a dead-export sweep (`knip`) in CI, plus the rule that a
"v2" function must land in the same commit that removes v1's last caller.

## Sources

- https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html — the Dependency Rule and the concentric circles, in Martin's words
- https://blog.cleancoder.com/uncle-bob/2011/09/30/Screaming-Architecture.html — top-level structure should announce the domain; framework and web as details
- https://blog.cleancoder.com/uncle-bob/2020/10/18/Solid-Relevance.html — Martin's own restatement of the five SOLID principles, scoped to modules rather than classes
- https://github.com/johnousterhout/aposd-vs-clean-code — the Ousterhout/Martin debate transcript: method length, comments, TDD
- https://web.stanford.edu/~ouster/cgi-bin/aposd.php — A Philosophy of Software Design, official page
- https://bagerbach.com/books/fundamentals-of-software-architecture/ — Richards/Ford notes used for the architecture-quantum counter-test
- https://tryingthings.wordpress.com/2025/02/25/aposd-vs-clean-code-a-debate/ — third-party analysis of where the two positions actually conflict
