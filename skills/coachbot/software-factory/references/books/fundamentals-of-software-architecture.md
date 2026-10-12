# Fundamentals of Software Architecture — Mark Richards & Neal Ford, 2020 (2nd ed. 2025)

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

Martin gives us direction; Ousterhout gives us depth; neither gives us a way to
say _how good is good enough_, or _what did this decision cost_. Richards and
Ford do. Their contribution is that architecture is an engineering discipline
with **measurable characteristics** and **automated governance** — you name the
"-ilities" that matter, you define a fitness function per characteristic, and you
run it in CI. That is the only mechanism in the three books that survives contact
with a codebase where an agent writes most of the diffs, because it does not
depend on anyone remembering a principle.

Three jobs in our loop:

1. **Trade-off vocabulary.** The First Law — _everything in software architecture
   is a trade-off_ — is the antidote to "best practice" answers. It forces every
   proposal to name what it gave up.
2. **The quantum test.** Before anyone extracts a service or a package, the
   architecture quantum tells you whether there is actually a new deployment,
   scaling, or failure boundary — or just a naming preference.
3. **ADRs and fitness functions as artifacts.** Decisions get written down with
   their consequences; characteristics get a CI check. Both are things we ship,
   not things we believe.

## The argument (deep prose)

The book's opening move is definitional and unfashionable: it refuses to define
"software architecture" as a fixed set of concerns and instead defines it as four
dimensions — **structure** (the style: layered, microkernel, event-driven,
microservices), **architecture characteristics** (the -ilities the system must
succeed at), **architecture decisions** (the rules about how the system is
built), and **design principles** (guidelines rather than rules). The point of
the split is that only the first is visible in a diagram, and the other three are
where the value and the failure live. A diagram that shows boxes and arrows and
says nothing about scalability targets or why Kafka was chosen has communicated
the least important dimension.

The **First Law of Software Architecture** — _everything in software architecture
is a trade-off_ — is stated with a sharp corollary: if you think you have found
something that is not a trade-off, you simply have not found the trade-off yet.
This is the book's load-bearing idea and it reframes the architect's job from
choosing the best option to _choosing the least-worst option and knowing what it
cost_. Richards and Ford's derived aphorism is "shoot for the least worst
architecture," which sounds defeatist and is actually liberating: it removes the
obligation to defend a decision as optimal and replaces it with the obligation to
state its consequences. The **Second Law** — _why is more important than how_ —
is why ADRs exist. The structure is recoverable by reading the code; the
reasoning is not, and it is the reasoning a future maintainer needs in order to
know whether the decision still applies.

**Architecture characteristics** are the non-domain requirements that drive
structural choices, grouped into operational (availability, continuity,
performance, recoverability, reliability, robustness, scalability, elasticity),
structural (configurability, extensibility, installability, maintainability,
portability, supportability, upgradeability), and cross-cutting (accessibility,
authentication, authorization, legal compliance, privacy, security, usability).
The critical discipline is _limitation_: you cannot optimize all of them, they
conflict (performance versus security; elasticity versus simplicity), and every
one you commit to adds design cost. Their guidance is to pick roughly three
"driving" characteristics, derive them from domain concerns rather than from a
wish list, and make them explicit and testable. A characteristic that is not
measurable is a slogan.

**Fitness functions** are the mechanism that turns a characteristic into
governance. Borrowed from evolutionary computing and developed further in
_Building Evolutionary Architectures_, a fitness function is _any_ objective
mechanism that assesses one or more architecture characteristics: a unit test, a
metric, a monitor, a static-dependency check, a chaos experiment, a code-quality
threshold. They can be atomic (one characteristic, one scope) or holistic
(several characteristics interacting), triggered or continual, automated or —
rarely, reluctantly — manual. The strategic claim is that principles that are not
verified decay, so architecture governance must be executable and must run on
every build. This is the single most transferable idea in the book, and it is
why our `pnpm run ci` is an architectural artifact rather than a test runner.

The **architecture quantum** is their unit of architectural analysis: _an
independently deployable artifact with high functional cohesion and synchronous
connascence_. Three parts each doing work. _Independently deployable_ means it
has its own deployment pipeline and can ship without coordinating. _High
functional cohesion_ means it does one business thing. _Synchronous connascence_
means everything inside it that must change together at runtime is inside it — a
service coupled to another by a synchronous call is not a separate quantum, it is
half of a bigger one. The consequence they draw is that in modern systems,
architecture characteristics should be defined **per quantum**, not per system:
the payment path and the reporting path do not need the same availability, and
pretending they do overbuilds one and underbuilds the other. **Connascence**
(Page-Jones, resurfaced here) is the coupling taxonomy underneath: two components
are connascent when a change in one requires a change in the other; static
connascence (name, type, meaning, position, algorithm) is discoverable by reading
code, dynamic connascence (execution order, timing, value, identity) is not — and
dynamic connascence across a network is where distributed systems go to die.

The style catalogue is the applied half. **Layered** is simple and cheap and has
poor testability and low scalability; it is the default and the default is often
right for small teams. **Modular monolith** (a single deployable partitioned by
domain with enforced module boundaries) is the style they most often recommend as
a starting point, because it buys the domain partitioning of microservices
without the distributed cost. **Microkernel** is extensible via plugins, bounded
by its monolithic core. **Service-based** — a handful of coarse services over a
shared database — is the pragmatic middle: keeps ACID transactions, gives
independent deployability, avoids the distributed-data problem. **Event-driven**
gives high performance and scalability at the cost of testing difficulty,
eventual consistency, and error-handling complexity. **Microservices** give
evolutionary independence and independent deployability at the cost of
performance overhead, distributed transactions, and operational complexity that
scales with service count. Each style gets a star-rating table across
characteristics, and the tables exist to make the trade-off visible rather than
to crown a winner.

**Where the book is right for us.** The First Law and ADRs are unambiguously
right and cheap. Fitness functions are right and we already have the substrate: a
Turborepo pipeline, Vitest, ESLint, and an eval-datasets package that is
_literally_ a fitness function for coaching quality — it drives the real
`StatefulGraphAgent` and gates CI on a quality threshold. The quantum test is
right and it is the correct rebuttal to "extract a service": our system today has
roughly four quanta (studio+chat web tier, conversation-worker, queue-worker,
SpiceDB), and every proposal to add a fifth should have to justify the
deployment, scaling, or failure boundary. Their choice of the modular monolith as
the default starting style matches ours and is worth citing when someone proposes
otherwise.

**Where the book is wrong or dated for a 2026 TypeScript monorepo.** Four things.

First, it is **enterprise-shaped and role-shaped**. Its implicit reader is a
dedicated architect in an organization with an architecture review board, and a
meaningful fraction of the content (the eight expectations of an architect,
negotiating with stakeholders, navigating politics, the four architect
personality anti-patterns) is organizational advice for a structure we do not
have. In a small team the architect role is distributed and the artifacts —
ADRs, fitness functions, characteristic lists — are what actually transfer. Take
the artifacts, skip the org chart.

Second, the **star-rating tables invite cargo-culting**. A five-star scalability
rating for microservices is an average over an imagined population of systems,
not a prediction about ours. Used as a lookup table they produce exactly the
premature-distribution failure the book elsewhere warns against. Use them to
generate the _questions_ ("what would our elasticity requirement have to be to
justify this?"), never as the answer.

Third, it **predates the current cost structure**. Written before the collapse in
the cost of _writing_ code and the corresponding rise in the cost of _reviewing_
it, the book assumes implementation is the expensive step. In 2026 the expensive
steps are comprehension, review, and operating what you built — which shifts the
correct default further toward fewer quanta, fewer packages, and more
automatically-checked constraints. The book's own tools support this conclusion;
its worked examples do not always reach it.

Fourth, it has **no vocabulary for probabilistic components**. An LLM call is an
architecture characteristic problem the book never anticipated: its quality is a
distribution, its cost per call is variable and real, its latency has a fat tail,
and it can fail in ways that are semantically wrong rather than technically
failed. The right move is not to abandon the framework but to extend the
characteristic list: for us, _answer quality_, _cost per conversation_, _p95
first-token latency_, and _moderation-block rate_ are first-class architecture
characteristics with fitness functions, sitting alongside availability and
scalability. Richards and Ford give the mechanism; we supply the characteristics.

**The Ousterhout-vs-Martin conflict, staged and resolved.** This book is the
reason the conflict is resolvable rather than a matter of taste, because the
First Law says the question "should functions be short?" is malformed —
short-versus-long is a trade-off between separation of concerns (Martin's
priority) and cognitive load (Ousterhout's priority), and the right answer
depends on which characteristic you are optimizing at that altitude. Stating the
positions plainly: Martin holds that functions "should be small... smaller than
that," that extractability proves the original did more than one thing, and that
comments are "always failures... a necessary evil" to be replaced by better
names. Ousterhout holds that decomposition should stop when the pieces stop being
_deep_, that over-decomposition produces _entanglement_ where understanding one
operation requires reading five methods, and that comments are "crucially
important" because there is information — the why, the invariants, the units —
that code structurally cannot express. Martin conceded in their debate that
_Clean Code_ gave no guidance for recognizing over-decomposition. On TDD,
Ousterhout prefers designing and writing a coherent unit before testing it,
fearing tiny cycles entrench a bad first design; Martin argues the strategic
thinking happens in the refactor step.

**Our house position** (identical in all three files, deliberately):

- **At the module and package boundary, Martin wins.** Dependency direction,
  SRP-as-axis-of-change, DIP, no framework types inward. Structural and checkable.
- **Inside a module, Ousterhout wins.** Function length is not a target and never
  a lint rule; extract only when the result is _deeper_. If understanding one
  operation needs more than one navigation hop, the decomposition is wrong.
- **On comments, Ousterhout wins outright.** Interface comment on every export;
  _why_ comments in bodies; no restatement of the code.
- **On TDD, we split.** Design the boundary and write its interface comment
  first, then TDD within it. Never TDD your way into an architecture.
- **Richards/Ford adjudicate.** When the two still conflict, name the
  architecture characteristic at stake (maintainability? testability? cognitive
  load?), pick the one that matters for _this_ quantum, and write the trade-off
  down. A conflict that survives that treatment is an ADR, not an argument.

One sentence: **Martin governs the arrows, Ousterhout governs the insides, and
Richards/Ford govern the decision about which one you are optimizing for and what
it cost.**

## Enforceable rules

| #     | Rule                                                                                                                                                                                                                                         | How to check                                                                                                                                                      | Severity |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| FA-1  | Every significant decision names the trade-off: what we gave up, and the option we rejected                                                                                                                                                  | MR template requires `## Trade-off` and `## Options considered`; CI greps for both on diffs touching `packages/*/src/index.ts`, `db/migrations/**`, `infra_tf/**` | fix      |
| FA-2  | ADR required for: a new deployable (quantum), a new workspace package, a new runtime dependency in `packages/database` or `packages/agents`, a change to a published API shape, a new persistence store, or a synchronous cross-service call | reviewer check: the change is accompanied by `~/project-workspace/Tasks/<slug>/02-adr-<n>.md` (planning artefacts live outside the repo per CLAUDE.md; `docs/adr/` does not exist)                                                                                             | block    |
| FA-3  | ADRs use the fixed template — Title, Status, Context, Decision, Consequences, Compliance — and Consequences must include at least one negative                                                                                               | read the ADR: headings present, Consequences non-trivial. Template: `templates/adr.md`                                                                 | fix      |
| FA-4  | The system's driving architecture characteristics are declared in one file with a target and a fitness function per characteristic; adding a characteristic without a fitness function is not allowed                                        | `docs/architecture/characteristics.md` schema check: each row has target + link to check                                                                          | block    |
| FA-5  | Quantum test before extraction: a new deployable must show an independent deployment cadence, scaling profile, or failure domain — documented in the ADR                                                                                     | ADR review gate (FA-2) with an explicit quantum section                                                                                                           | block    |
| FA-6  | No new synchronous cross-quantum call without an ADR; async-via-outbox/BullMQ is the default                                                                                                                                                 | dependency-cruiser + grep for `fetch(`/HTTP clients targeting our own services outside allowlisted adapters                                                       | block    |
| FA-7  | Dependency direction: `packages/**` never imports `apps/**`; no deep imports past a package entrypoint                                                                                                                                       | ESLint `no-restricted-imports` + dependency-cruiser                                                                                                               | block    |
| FA-8  | Package graph is acyclic and layer-monotonic (an edge always points to a lower declared layer)                                                                                                                                               | `scripts/arch/assert-package-graph.ts`                                                                                                                            | block    |
| FA-9  | No business logic in route handlers: parse, authorize, delegate, shape response — no branching on domain values                                                                                                                              | handler line budget (≤60 non-import lines) + review                                                                                                               | fix      |
| FA-10 | No framework types in domain/repository packages; domain tests run with no HTTP server and no SvelteKit adapter                                                                                                                              | Vitest node-environment project for `packages/**`; forbid `@sveltejs/kit`/`$app/*`/`$env/*` imports there                                                         | block    |
| FA-11 | Package-by-feature above package-by-layer in apps: `src/lib/<feature>/{ui,server,domain}`; `services/`, `helpers/`, `managers/` denied as new dirs                                                                                           | directory-name denylist lint                                                                                                                                      | fix      |
| FA-12 | Module depth: a new package's public surface must be small relative to its implementation (≥10 source lines per exported symbol)                                                                                                             | `scripts/arch/depth-report.ts`                                                                                                                                    | fix      |
| FA-13 | Every declared performance/cost characteristic has a budget checked in CI or in production monitoring, with an owner                                                                                                                         | characteristics file must link a CI job or a Grafana/PostHog alert per row                                                                                        | fix      |
| FA-14 | Connascence: no dynamic connascence of execution order or timing across a quantum boundary without an ADR (i.e. "worker must run before route" is a design flaw, not a note)                                                                 | review; detectable as ordering comments/sleeps in tests                                                                                                           | fix      |
| FA-15 | AI-quality characteristics (answer quality, cost/conversation, p95 first-token latency, moderation-block rate) are gated by the eval-datasets suite; a green gate must be impossible when a check did not run                                | `@coachbot/eval-datasets` gate must fail closed on judge dropout (already a package rule)                                                                         | block    |

## Design review prompts

Ask before code exists.

1. Which three architecture characteristics is this design optimizing for, in
   priority order? What is the numeric target for each?
2. Which characteristics are we explicitly _not_ optimizing, and who agreed?
3. State the trade-off in one sentence: "we chose X, which costs us Y." If you
   cannot name Y, you have not found it yet.
4. What is the second design? Describe a genuinely different structure and say
   why it lost.
5. How many architecture quanta does this add or change? For each new one: what
   is its independent deployment cadence, its scaling profile, and its failure
   domain? If all three match an existing quantum, why is it separate?
6. What is the connascence across each new boundary — name, type, meaning,
   position, execution order, timing, value, identity? Which of those are dynamic
   and cross a process boundary?
7. For every characteristic in answer 1: what is the fitness function, does it
   run in CI or in production monitoring, and does it fail closed?
8. Is this decision reversible? If not, where is the ADR, and does its
   Consequences section contain a real negative?
9. What is the failure mode when the LLM provider is slow, returns garbage, or
   costs 5x expected? Which characteristic degrades, and is that degradation
   observable?
10. If this is distributed: what is the consistency story, who owns the data,
    and what happens on partial failure? If the answer involves a distributed
    transaction, why is this not one quantum?
11. What would have to become true for this decision to be wrong, and what
    signal would tell us — before a customer does?
12. What is the smallest version of this that meets the targets in answer 1, and
    why are we not shipping that one?

## Fitness functions

The book's central idea, made concrete for pnpm/TS/Turborepo. Each of these is
a real check we can run in `pnpm run ci`.

**1. Structural: package graph acyclicity + layer monotonicity (atomic, triggered)**

```ts
// scripts/arch/assert-package-graph.ts
const LAYER: Record<string, number> = {
  "@coachbot/types": 0,
  "@coachbot/observability": 0,
  "@coachbot/permissions": 1,
  "@coachbot/database": 2,
  "@coachbot/agents": 3,
  "@coachbot/queues": 3,
  "@coachbot/sveltekit-auth": 4,
  "@coachbot/ui": 4,
};
// Build the DAG from @coachbot/* entries in each package.json `dependencies`.
// FAIL if: any cycle (DFS back edge), or any edge a->b with LAYER[a] <= LAYER[b],
// or any packages/* depending on an apps/*.
// Print the offending edge. Exit 1.
```

**2. Structural: import boundaries (atomic, continual — runs in lint)**

```js
// dependency-cruiser
forbidden: [
  { name: "no-circular", severity: "error", from: {}, to: { circular: true } },
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
    to: { path: "node_modules/(@sveltejs|svelte|vite)" },
  },
  {
    name: "routes-never-touch-repositories",
    severity: "error",
    from: { path: "\\+(page\\.)?server\\.ts$" },
    to: { path: "^packages/database/src/repositories" },
  },
  {
    name: "no-deep-package-imports",
    severity: "error",
    from: {},
    to: { path: "^packages/[^/]+/src/(?!index\\.ts$)" },
  },
];
```

**3. Structural: module depth (atomic, triggered)** — `depth-report.ts`: exported
symbols from each package's emitted `.d.ts` versus non-comment source lines; fail
a new package under 10:1, warn on a >25% single-MR drop.

**4. Operational: bundle-size budget (atomic, continual)**

```jsonc
// size-limit config, checked per app on every build
[
  {
    "path": "apps/chat/.svelte-kit/output/client/_app/immutable/entry/*.js",
    "limit": "180 kB",
    "gzip": true,
  },
  {
    "path": "apps/studio/.svelte-kit/output/client/_app/immutable/entry/*.js",
    "limit": "260 kB",
    "gzip": true,
  },
]
// CI fails on regression; the number is the characteristic, the diff is the alarm.
```

**5. Operational: latency budget (atomic, continual — production)** — p95
first-token latency for the chat path and p95 route response for studio, as
alerting thresholds in the observability stack, with the threshold value written
in `docs/architecture/characteristics.md` so the doc and the alert cannot drift.

**6. Operational: DB query budget (holistic, triggered)** — integration tests
assert a maximum query count per request for the hot chat path (count queries via
a `pg` hook in the test harness). This catches N+1 as an _architecture_
regression rather than a performance surprise.

**7. Domain-quality: the eval-datasets gate (holistic, triggered)** — we already
have this and it is the best fitness function in the repo: `@coachbot/eval-datasets`
drives the real `StatefulGraphAgent`, scores with deterministic checks plus
judges, and gates CI on `gatedCorrectness`. Two properties make it a legitimate
fitness function rather than a test suite: it measures a _characteristic_ (answer
quality) rather than a behavior, and it **fails closed** — a check that did not
run is a blocking reason, never an n/a.

**8. Cost: per-conversation token/cost ceiling (atomic, triggered)** — the same
suite records tokens and cost per case; a `MetricTarget` row caps mean cost per
conversation. Cost is an architecture characteristic when the component is an
LLM, and an uncapped one is how a margin disappears.

**9. Security/authorization (cross-cutting, triggered)** — an integration test
per resource type asserting that a non-member actor receives a 404/403 for read,
write, and list, plus a static check that every repository function takes
`actorId` as its first parameter (AST rule). ReBAC correctness is a
characteristic; leaving it to review is how it regresses.

**10. Governance: ADR presence (manual→automated, triggered)**

> **Not runnable as written here.** ADRs live outside the repo in
> `~/project-workspace/Tasks/<slug>/` per CLAUDE.md, so CI cannot see them.
> Keep this sketch only as the shape to use *if* ADRs ever move in-repo; today
> CA-10/FA-2 are enforced by reviewer check at Gate 2.

```bash
CHANGED=$(git diff --name-only origin/main...)
NEEDS_ADR=$(echo "$CHANGED" | grep -cE '^(packages/[^/]+/package\.json|db/migrations/|infra_tf/)')
HAS_ADR=$(echo "$CHANGED" | grep -c '^docs/adr/')
[ "$NEEDS_ADR" -gt 0 ] && [ "$HAS_ADR" -eq 0 ] && { echo 'FA-2: missing ADR'; exit 1; }
```

**11. Holistic: change-amplification report (continual, non-gating)** — files
changed per Linear issue, bucketed by package. A rising median means placement is
wrong. Report it; do not gate it, because gating a proxy metric teaches gaming.

**12. Chaos-lite (holistic, scheduled)** — a staging job that kills Redis or
makes SpiceDB slow for 60 seconds and asserts the chat path degrades to a
documented behavior rather than a 500. Availability is a claim until something
tests it.

## Applied to a package-by-feature TS monorepo

Richards/Ford's contribution to slicing is the **quantum boundary** and the
**characteristic per slice**. Feature slicing gives you the _logical_ partition;
the quantum tells you whether that partition ever becomes a _physical_ one, and
the characteristics tell you how much engineering each slice deserves.

Our current quanta, stated plainly, because you cannot reason about them
otherwise:

| Quantum             | Contents                                                       | Driving characteristics                              |
| ------------------- | -------------------------------------------------------------- | ---------------------------------------------------- |
| Web tier            | `apps/studio`, `apps/chat`, `apps/admin` (same deploy cadence) | p95 latency, availability, authorization correctness |
| Conversation worker | `apps/conversation-worker`                                     | answer quality, cost/conversation, throughput        |
| Queue worker        | `apps/queue-worker`                                            | at-least-once delivery, idempotency, recoverability  |
| SpiceDB             | authorization store                                            | correctness, availability                            |

Everything in `packages/**` is _shared library_, not a quantum: it has no
independent deployment. That is the correct default and a new package does not
change it.

A feature slice inside the web-tier quantum, laid out so it is deep and its
boundaries are checkable:

```
docs/
  adr/0042-feedback-scores-in-langfuse.md   # decision + consequences + trade-off
  architecture/characteristics.md            # targets + fitness-function links

packages/
  types/src/feedback.ts                      # one owned shape, branded ids
  database/src/repositories/
    message-feedback.repository.ts           # actor-first; hides SQL, scoping,
                                             # cache invalidation, outbox write

apps/studio/src/lib/feedback/
  domain/score.ts                            # pure; no DB, no HTTP, no SvelteKit
  domain/score.spec.ts                       # fitness function for the rules
  server/record-feedback.ts                  # authorize -> aggregate -> persist
                                             # -> enqueue Langfuse emission
  server/record-feedback.spec.ts
  ui/ScoreBadge.svelte
  index.ts                                   # public surface: 3-5 exports

apps/studio/src/routes/(app)/projects/[projectId]/feedback/
  +page.server.ts                            # <=60 lines: parse/authz/delegate
```

The architecture decisions embedded in that sketch, each with its trade-off:

- **Langfuse emission goes through the outbox / BullMQ, not a synchronous call.**
  Trade-off: eventual consistency in the dashboard (seconds) bought in exchange
  for not coupling the web tier's availability to a third party. Without this,
  the web-tier quantum inherits Langfuse's uptime — that is dynamic connascence
  of timing across a quantum boundary (FA-14).
- **The slice stays in the web-tier quantum.** No new deployable: same cadence,
  same scaling profile, same failure domain. FA-5 says that is not a quantum.
- **The repository is the only place with SQL.** Trade-off: less flexibility for
  bespoke queries at call sites, bought in exchange for a single enforcement
  point for project scoping — an authorization characteristic, not a style
  preference.
- **`domain/score.ts` is pure.** Trade-off: an extra mapping step at the call
  site, bought in exchange for a fitness function (`score.spec.ts`) that runs in
  milliseconds with no infrastructure.
- **One shape in `@coachbot/types`, derived views via `Pick`/`Omit`.** Trade-off:
  slightly awkward types at the API edge, bought in exchange for eliminating
  change amplification across five near-identical DTOs.

If a slice ever _does_ need to become a quantum — say feedback aggregation grows
a heavy scheduled recomputation — the extraction is cheap precisely because the
slice already has one entrypoint, one owned shape, and pure domain rules. That is
the modular-monolith bet the book recommends: keep the domain partition, defer
the distribution, and make the ADR when the deployment boundary actually appears.

## Anti-patterns specific to AI-generated code

Generated code fails in the direction of _structural plausibility without
governance_. Richards/Ford's framing makes each failure a missing fitness
function rather than a missing virtue.

**1. Shallow pass-through modules.** A generated "service layer" whose functions
rename arguments and forward. No characteristic improves; maintainability
worsens (two places to look, neither authoritative). _Counter-move:_ an AST
fitness function that fails on an exported function whose body is a single call
with unchanged arguments, allowlisted only by an explicit `// depth: <reason>`
comment. And in review: "which characteristic does this layer improve, and by how
much?"

**2. Layer duplication.** The same concept as a DB row type, a repository type, a
service DTO, an API schema, and a component prop, with hand-written mappers. This
is measurable: it is change amplification, and the change-amplification report
(fitness function 11) surfaces it as a rising files-per-issue median.
_Counter-move:_ one owned shape in `@coachbot/types` with derived views; mappers
permitted only where the shapes genuinely differ, with a comment saying which
transformation they perform.

**3. Interface-for-one-implementation.** A declared interface plus one concrete
class plus a DI token, in a structurally-typed language. It buys an
extensibility characteristic nobody asked for and taxes maintainability and
navigability. This is the First Law inverted: a cost with no named benefit.
_Counter-move:_ abstractions earned on the second implementation or the first
genuine double; `knip` reports single-implementer interfaces; `Pick<typeof x, 'y'>`
as the default narrowing tool.

**4. Config sprawl.** Every generated feature adds env vars, an options object
with eight optionals, its own defaults, its own validation. This degrades two
characteristics simultaneously: _testability_ (the tested combination space
explodes) and _supportability_ (nobody knows the live configuration).
_Counter-move:_ every env read through the app's single `env.ts` (grep-enforced);
an optional field must have a call site that sets it to a non-default value or it
is deleted; new configuration needs an ADR naming the characteristic it serves.

**5. Premature microservice / premature package.** The most expensive one,
because it is hard to reverse and the book's own star tables encourage it if read
as a lookup. Extracting a service for code with one consumer, one deploy cadence,
and one failure domain buys nothing and imports the entire distributed-systems
tax: network latency, partial failure, distributed transactions, deployment
coordination, observability across a hop. _Counter-move:_ FA-5, the quantum test,
as a hard gate in the ADR — name the independent deployment cadence, the
independent scaling profile, or the independent failure domain, or it stays in
the monolith. Default answer: modular monolith, one more slice.

**6. Fitness-function theatre.** Generated CI configs that add a check which
cannot fail — a threshold set above the current worst value, a test that skips
when a dependency is missing, a judge that scores `n/a` when it drops out. A
green gate that could not have been red is worse than no gate, because it buys
false confidence. _Counter-move:_ every gate must **fail closed**; prove a new
check can fail by breaking the code once and showing red before merging; this is
already a written rule for `@coachbot/eval-datasets` and it generalizes.

**7. Undocumented trade-offs.** Generated MR descriptions summarize _what_
changed and never _why this and not that_. Over months the system accumulates
decisions with no rationale, and the Second Law — why matters more than how —
becomes unrecoverable. _Counter-move:_ FA-1's `## Trade-off` and
`## Options considered` sections, CI-checked on boundary-touching diffs, plus
FA-3's requirement that every ADR's Consequences section contain a real negative.
An ADR with only upsides is a marketing document.

**8. Unbounded AI cost and latency.** Generated agent code adds a model call
inside a loop, a retry with no cap, or a second model for "better quality," and
nothing measures the result. Cost and p95 latency are architecture
characteristics for us. _Counter-move:_ FA-13 and FA-15 — a cost-per-conversation
ceiling and a latency budget in the eval suite, gating CI, with the target
written in `characteristics.md` next to the check that enforces it.

## Sources

- https://www.oreilly.com/library/view/fundamentals-of-software/9781492043447/ — the book (1st ed.)
- https://www.oreilly.com/library/view/fundamentals-of-software/9781098175504/ — 2nd edition
- https://bagerbach.com/books/fundamentals-of-software-architecture/ — detailed chapter notes: the two laws, characteristic taxonomy, fitness functions, architecture quantum, connascence, style trade-off tables, ADR template, the eight expectations of an architect
- https://danlebrero.com/2021/11/17/fundamentals-of-software-architecture-summary/ — independent summary used to cross-check the quantum and connascence definitions
- https://www.thoughtworks.com/insights/books/fundamentals-of-software-architecture — publisher/author framing of the engineering-approach thesis
- https://medium.com/@sherwin.water3/reading-notes-the-fundamentals-of-software-architecture-an-engineering-approach-c38474183ce6 — 2nd-edition reading notes
- https://github.com/johnousterhout/aposd-vs-clean-code — the Ousterhout/Martin debate transcript, for the house position
- https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html — the Dependency Rule, cited in the boundary half of the house position
