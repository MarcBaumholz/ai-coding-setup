# Working Effectively with Legacy Code — Michael C. Feathers, 2004

## Contents

- [Why this book is in the loop](#why-this-book-is-in-the-loop)
- [The argument (deep prose)](#the-argument-deep-prose)
- [Enforceable rules](#enforceable-rules)
- [Smells → moves](#smells--moves)
- [Review prompts](#review-prompts)
- [Anti-patterns specific to AI-generated code](#anti-patterns-specific-to-ai-generated-code)
- [Sources](#sources)

## Why this book is in the loop

Feathers governs the _change-untested-code_ decision class: what to do when the code you
must modify has no tests, is too tangled to test, and shipping is not optional. It is the
prerequisite to Fowler — the catalogue's small-steps mechanics are only safe behind a
green suite, and this book is how you get one on code that was not designed for it. In
our pipeline it supplies three things a review can demand by name: a characterization
test before any restructure, a seam instead of a rewrite, and Sprout/Wrap as the default
shape for adding behaviour to code you do not trust.

## The argument (deep prose)

Feathers opens with a definition that is deliberately provocative and turns out to be the
most useful line in the book: **legacy code is code without tests**. Not old code, not
badly written code, not someone else's code. Code without tests is code you cannot change
with confidence, and confidence is the entire currency of software maintenance. Elegant,
recently-written, beautifully-named code with no tests is legacy code; ugly ten-year-old
code with a fast, trustworthy suite is not. This reframing does real work, because it
converts a vague emotional condition ("this codebase is horrible") into a concrete,
addressable deficit ("this call path has no feedback loop"), and it tells you exactly
what to buy first.

From that follows the central tension the book is built around. To change code safely you
need tests. To write tests you usually need to change the code, because the thing you want
to test instantiates a database connection in its constructor, reads a module-level
singleton, calls a network client at import time, or is a 600-line function with no
parameters and eight hidden inputs. Feathers calls this the legacy code dilemma: "When we
change code, we should have tests in place. To put tests in place, we often have to change
code." His resolution is not to break the dilemma with heroics but to route around it with
the smallest possible unsafe step, taken deliberately and with a named technique — and
then to never take that step again on that code path.

The mechanism that makes this possible is the **seam**. A seam is "a place where you can
alter behavior in your program without editing in that place", and every seam has an
**enabling point** — the location where you choose which behaviour is active. This
abstraction is the book's real intellectual contribution, because it makes testability a
structural property you can look for rather than a virtue you either have or lack. Feathers
catalogues seam types by the language mechanism that provides them: preprocessing seams
(the C preprocessor swapping a symbol), link seams (substituting a library or object file at
link time), and object seams (passing a different implementation to a method or constructor).
The taxonomy is dated in its specifics — nobody is doing preprocessor tricks in TypeScript —
but the classification by _when substitution is decided_ survives intact and maps directly
onto our stack. In a Node/TypeScript monorepo the seams are: parameter seams (pass the
dependency in — the best kind, cheapest and most explicit), constructor/factory seams,
module seams (the ESM import graph, substitutable with `vi.mock`), environment seams (config,
env vars, feature flags), and network/process seams (an HTTP or database boundary you can
point at a fake). The important consequence is a ranking: the further out you place the
enabling point, the more of your real code the test exercises, but the harder the test is to
control and the slower it runs. The further in, the more you are testing your own wiring.
Prefer a parameter seam over a module seam almost always, because `vi.mock` couples the test
to the import graph — rename a file and the mock silently stops mocking while the test keeps
passing, which is the worst failure mode a test can have. [extension]

The second mechanism is the **characterization test**, and it is the one most engineers get
wrong. A characterization test does not encode what the code _should_ do; it records what the
code _does_, bugs included. The procedure is mechanical: write a test that calls the code with
some input, assert something you know is wrong (`expect(result).toBe('ZZZ')`), run it, read the
failure message to learn the actual value, paste that value into the assertion, and go green.
You have just extracted a specification from a binary. The emotional resistance to this is
strong — it feels like enshrining bugs — but the point is not correctness, it is _change
detection_. You are building a tripwire, not an oracle. If the behaviour you pinned turns out
to be a bug, you now have exactly the artifact you need to fix it deliberately: a test that
fails when you change it, which is a visible, reviewable decision instead of an accident. This
is also how you learn what code does when nobody remembers, and it is strictly cheaper than
reading it.

Third: the **Legacy Code Change Algorithm** — identify change points, find test points, break
dependencies, write tests, make changes, refactor. The ordering is the advice. Most engineers
start at "make changes" and bolt tests on afterwards, if ever. Feathers' order forces you to
answer "how will I know if I broke this" before you have any sunk cost in a solution.

Fourth: the pragmatic escape hatches, **Sprout** and **Wrap**, which are what you actually
reach for under deadline. Sprout Method (or Sprout Class) means writing the new behaviour as a
new, fully tested unit somewhere clean, and inserting exactly one call to it into the untested
mess. The old code stays untested, but every new line is covered and the risk of the change is
one line. Wrap Method means renaming the existing method and creating a new one with the
original name that calls both the renamed original and your new tested behaviour — used when
the new behaviour must run on every invocation rather than at one internal point. Wrap Class
is the same at class granularity, typically a decorator. The judgement rule is crisp: Sprout
when the new behaviour belongs at a specific point _inside_ the existing logic; Wrap when it
must run before or after the whole thing, every time. Both are honest about their trade-off —
they leave the legacy code untested and slightly uglier (a new method, a new indirection) in
exchange for a bounded blast radius. Feathers is unusual among methodology authors in
explicitly recommending a move that makes the code marginally worse in order to make the change
safe. That intellectual honesty is why the book aged better than most of its contemporaries.

Supporting tools: **effect sketches** (map which methods and fields affect which, to reason
about what your change can possibly break) and **pinch points** (a narrow place where tests on
one or two methods detect changes across many, so you get maximum coverage per test written).
Both are manual techniques that are largely obsolete as manual techniques — a language server
and a call-graph tool do effect analysis better and faster than a whiteboard — but the _concepts_
are what you ask for in review: what is the effect radius of this change, and where is the
cheapest place to observe it. **Scratch refactoring** is the other durable idea: restructure
freely to understand the code, learn what you learn, then `git checkout .` and throw it all
away before doing the real, tested change.

Where the book is wrong or dated. The 23 dependency-breaking techniques in chapter 25 are the
most dated part: Extract Interface, Extract Implementer, Subclass and Override Method, Introduce
Static Setter, Replace Global Reference with Getter, Parameterize Constructor, Supersede Instance
Variable, Link Substitution, Text Redefinition. Most of these are workarounds for Java and C++
constraints — no first-class functions, no module mocking, no structural typing, mandatory
class-based dependency injection. In TypeScript, "Extract Interface then inject a fake" is
usually just "accept a function parameter", and structural typing means you never need to declare
the interface at all. "Subclass and Override Method" is an anti-move in a codebase that should
prefer composition. Take the _categories_ (make the dependency substitutable, move the decision
outward, narrow what the unit touches) and drop most of the recipes.

Second, the book's tooling assumptions are pre-CI, pre-container, pre-testcontainers. A large
fraction of its ceremony exists because standing up the real dependency was impossible, so you
faked it. In 2026 you can run real Postgres, Redis, and SpiceDB in Docker in seconds, which means
the correct answer to "this class talks to the database" is frequently "then test it against a
real database" — an integration test with real infrastructure is more truthful, less brittle, and
often no slower than a mock-heavy unit test. Feathers' fake-object machinery should be a fallback
for genuinely unavailable dependencies (paid third-party APIs, nondeterministic LLM calls, clocks,
randomness), not the default. Over-application of this book is a direct cause of mock-saturated
suites that pass while production burns. [extension]

Third, the book is silent on the modern seams that matter most in our stack: the network boundary
(intercept HTTP with a request-level fake rather than mocking a client class), the clock and
randomness (inject them; do not mock `Date` globally), and the nondeterministic LLM boundary,
where characterization testing in the strict sense is impossible because the same input does not
produce the same output. For that boundary the analogue is a recorded-fixture replay plus a
gated judge over a distribution of runs — the same _idea_ (pin current behaviour, detect drift)
executed statistically rather than exactly. That is our eval-datasets harness, and it is
Feathers' concept ported to a probabilistic system. [extension]

Fourth, the "make it worse to make it safe" licence is dangerous in the hands of a code generator.
Sprout and Wrap were designed for a human who knows they are taking on debt and will come back.
An LLM given the same licence produces a permanent accretion of sprouted helpers and wrapper
layers around code nobody ever deletes. The counter-rule: a Sprout or Wrap must be labelled as
such in the diff, and the untested core it protects must be named as the follow-up. [extension]

## Enforceable rules

| #   | Rule                                                                                                                                                                          | How to check                                                                                                    | Severity |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | -------- |
| 1   | No restructuring of code that has no covering test. Write a characterization test first, in its own commit.                                                                   | `git log` order: test commit precedes refactor commit; coverage report for the touched path before the change   | block    |
| 2   | Characterization tests are labelled as such (`describe('characterization: ...')` or a comment) so nobody mistakes pinned behaviour for intended behaviour.                    | Grep new spec files for the label on tests that assert current-but-unvalidated behaviour                        | fix      |
| 3   | Adding behaviour to an untested function uses Sprout (new tested unit + one call site) or Wrap, not inline edits scattered through the body.                                  | Reviewer: count edited lines inside the untested function; more than a single call insertion is a finding       | fix      |
| 4   | New code is testable by construction: dependencies (db, clock, random, http, LLM client, logger) arrive as parameters or injected options, never constructed inside the unit. | Grep new units for `new Pool(`, `Date.now()`, `Math.random()`, `fetch(`, `createClient(` inside function bodies | block    |
| 5   | Prefer parameter seams over module mocks. A new `vi.mock` of an internal workspace module needs a justification in the diff.                                                  | `grep -n "vi.mock(" ` in added tests; check the target is an external package or a genuine boundary             | fix      |
| 6   | No test asserts only that a mock was called, unless the call itself is the contract (e.g. an emitted event or enqueued job).                                                  | Scan new specs for `toHaveBeenCalled` as the sole assertion                                                     | fix      |
| 7   | Every new test must be shown to be able to fail: state how it was verified red before green.                                                                                  | Author/agent statement in the MR; reviewer may delete an assertion and re-run                                   | block    |
| 8   | Scratch refactoring is never committed. Exploration branches are discarded; the shipped change is the tested one.                                                             | `git log` for commits titled "explore"/"wip refactor" surviving into the MR                                     | note     |
| 9   | Before changing a shared unit, the effect radius is stated: which callers, which observers (db, cache, queue, API spec) can see the change.                                   | `mcp__code-review-graph__get_impact_radius_tool` with `detail_level: minimal, max_depth: 1-2`                   | fix      |
| 10  | Tests at the pinch point, not at every internal method: prefer one test on the narrow boundary that detects changes in many units over ten tests on private helpers.          | Reviewer: are new tests targeting exported boundaries or internals?                                             | note     |
| 11  | Sprouted units live in their own file with their own spec; they do not accrete into the legacy file.                                                                          | Check the new function's location and that a colocated `*.spec.ts` exists                                       | fix      |
| 12  | A Wrap that exists only for testing (no production behaviour) is not allowed — that is a seam without a purpose.                                                              | Reviewer: does the wrapper add behaviour, or only indirection?                                                  | fix      |
| 13  | Real infrastructure over fakes where Docker provides it (Postgres, Redis, SpiceDB). Fakes are reserved for paid, nondeterministic, or slow external services.                 | Check whether a new fake shadows a service already in `docker-compose`                                          | fix      |
| 14  | Nondeterministic boundaries (LLM) are pinned by recorded fixtures or the eval harness with a gate, not by a single exact-match assertion.                                     | Grep new specs for exact-string assertions on model output                                                      | block    |
| 15  | Debt created by Sprout/Wrap is named: the untested unit it protects is referenced in the MR description or a ticket.                                                          | MR description contains the follow-up reference                                                                 | note     |

## Smells → moves

| Smell                                  | How it looks in TS/Svelte                                       | The move                                                                                                   | Risk of the move                                                              |
| -------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Untested code you must change          | 400-line `+server.ts` handler with no spec                      | Characterization Test at the HTTP/handler boundary, then refactor                                          | Pins bugs as expected; label the test so nobody reads it as a spec            |
| Cannot instantiate the unit under test | Service constructs its own DB pool / Redis client               | Introduce Seam via parameter injection (the TS form of Parameterize Constructor)                           | Threading a dependency through many layers; stop at the first honest boundary |
| Hidden global dependency               | Module-level singleton client imported directly                 | Encapsulate Global Reference behind a getter, then pass it in                                              | Getter alone still hides the dependency; finish the job by injecting          |
| Hard-coded clock / randomness          | `Date.now()` and `Math.random()` inside logic                   | Introduce Seam: pass `now: () => Date` and `rng`                                                           | Global `vi.useFakeTimers` leaks between tests; prefer injection               |
| New behaviour needed inside a mess     | Extra scoring step in the middle of an untested worker loop     | Sprout Method / Sprout Class: tested unit + one call                                                       | The mess stays untested; record the follow-up                                 |
| New behaviour needed around a mess     | Logging/metrics/feature gate on every call to a legacy function | Wrap Method / Wrap Class (decorator)                                                                       | Extra indirection permanently; only wrap when it must run every time          |
| Unclear what the code does             | Nobody remembers why the traversal resolver branches            | Scratch Refactoring to understand, then discard; write a Characterization Test for what you learned        | Temptation to keep the scratch work — do not                                  |
| God class / god file                   | 900-line store or repository                                    | Effect sketch → Extract Class along the field-usage clusters; Break Out Method Object for the worst method | Splitting without tests is a rewrite; characterize the boundary first         |
| Untestable network call                | Direct `fetch` inside domain logic                              | Introduce Seam at the transport boundary (inject a fetcher or intercept at request level)                  | Mocking a client class couples tests to its API; intercept lower              |
| Untestable LLM call                    | Agent code calling the model inline                             | Introduce Seam on the model client; recorded fixtures for unit tests, eval harness for behaviour           | Exact-match assertions on generated text are flaky by construction            |
| Test needs the whole world             | Spec that boots the app to check one rule                       | Find the Pinch Point; test the narrow boundary instead                                                     | Pinch-point tests miss wiring bugs; keep one thin end-to-end path             |
| Long method with many locals           | 200-line function, 15 locals, no params                         | Break Out Method Object, then Extract Function on the object's methods                                     | Method object is a halfway house; do not stop there permanently               |
| Legacy branch nobody tests             | Old code path kept "just in case" beside the new one            | Remove Dead Code after a characterization test proves nothing reaches it                                   | Traffic may reach it in prod; check logs/analytics before deleting            |

## Review prompts

1. Which changed units had no covering test before this diff, and what specifically tells us they still behave the same?
2. Where is the characterization test for the code that was restructured here, and does it precede the restructure in commit order?
3. For each new test: what seam does it use to control its dependencies — parameter, module mock, env, or real infrastructure — and why is that the right level?
4. Which new tests would still pass if the implementation were deleted or returned a constant? Name them.
5. Does this diff add behaviour to an untested unit by editing its body rather than by Sprout or Wrap? Cite the lines.
6. Which dependencies does new code construct internally (db, clock, random, http, model client) instead of receiving, and what makes each untestable?
7. What is the effect radius of the changed unit — every caller, and every non-caller observer (schema, cache key, queue payload, API spec) that can see the behaviour?
8. Is any new `vi.mock` pointed at an internal workspace module, and would a renamed file silently disable it?
9. If a real Postgres/Redis/SpiceDB container is available for this path, why is a fake being used instead?
10. What untested code does this change leave behind, and where is that debt recorded?

## Anti-patterns specific to AI-generated code

- **Refactor-without-baseline.** Asked to clean up untested code, the model restructures and
  declares equivalence from reading alone. This is the exact move Feathers forbids.
  _Counter-move:_ require a characterization test commit first, or refuse the restructure.
- **Mock-everything tests.** The model produces specs where every collaborator is mocked and the
  assertions check that mocks were called, so the suite is green and proves nothing.
  _Counter-move:_ rule that a test must be able to fail for a real reason; prefer real containers
  over fakes; ban call-count-only assertions.
- **Aspirational characterization.** Told to "write tests for existing behaviour", the model
  asserts what the code _should_ do, the test goes red, and it then edits the production code to
  match its assumption — silently changing behaviour under the banner of adding tests.
  _Counter-move:_ characterization tests are written by running and pasting the observed value;
  any production edit in a "add tests" commit is a block.
- **Sprout sprawl.** Given the licence to sprout, the model sprouts on every task, leaving a
  ring of tiny helpers around an untouched 600-line core that grows more entangled.
  _Counter-move:_ label each Sprout, cap consecutive sprouts on the same unit, and require the
  core to be characterized on the second visit.
- **Seams that only serve tests.** Interfaces, wrappers, and injection layers introduced purely so
  a test can substitute something, with one production implementation forever.
  _Counter-move:_ prefer parameter seams (free) over structural seams; delete any wrapper with no
  production behaviour.
- **Global time/random mocking.** `vi.useFakeTimers()` or `Date` monkey-patching at module scope,
  producing order-dependent suites. _Counter-move:_ inject the clock.
- **Deleting the safety net.** When a characterization test fails after a change, the model updates
  the expected value to match the new output rather than investigating. This converts the tripwire
  into a rubber stamp. _Counter-move:_ any change to a characterization expectation requires an
  explicit statement of what behaviour changed and why it is intended.
- **Keeping the old path forever.** The model treats "do not break legacy behaviour" as "never
  delete", accumulating parallel implementations. _Counter-move:_ characterize, prove the old path
  is unreached, delete it in the same diff.

## Sources

- https://understandlegacycode.com/blog/key-points-of-working-effectively-with-legacy-code/ — legacy code definition, change algorithm, seams, characterization tests, sprout/wrap, scratch refactoring
- https://gist.github.com/jonnyjava/42883d4e464167f81e2ee60a488a5ded — chapter list and the 23 dependency-breaking techniques; definitions of seam, enabling point, pinch point, effect sketch
- https://codably.dev/code-quality/breaking-dependencies-in-legacy-code-sprout-wrap-seam-patterns — Sprout vs Wrap vs Seam decision guidance
- https://tamerlan.dev/working-effectively-with-legacy-code/ — chapter 6 ("I don't have much time and I have to change it") summary of sprout/wrap mechanics
- https://barryosull.com/blog/notes-from-working-effectively-with-legacy-code/ — practitioner notes on applying the techniques
- https://books.google.com/books/about/Working_Effectively_with_Legacy_Code.html?id=vlo_nWophSYC — publisher description and table of contents
