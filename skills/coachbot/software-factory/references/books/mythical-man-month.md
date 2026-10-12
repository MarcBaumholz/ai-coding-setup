# The Mythical Man-Month — Fred Brooks

Source: Frederick P. Brooks Jr., _The Mythical Man-Month: Essays on Software Engineering_,
Addison-Wesley, 1975; Anniversary Edition (with "No Silver Bullet — Essence and Accident in
Software Engineering", 1986) 1995.

- Publisher page: https://www.oreilly.com/library/view/mythical-man-month-the/0201835959/
- "No Silver Bullet" full text (UNC): https://cs.nyu.edu/~mwalfish/classes/22sp/classnotes/no-silver-bullet.pdf
- Brooks's law overview: https://en.wikipedia.org/wiki/Brooks%27s_law

Why this book is in a software-factory skill written in 2026: Brooks is the only classic that is
fundamentally about _coordination cost_, not about code. Everything else in the canon assumes the
bottleneck is producing correct instructions. Brooks assumes producing instructions is easy and that
the expensive thing is keeping many minds aligned on one design. That is exactly the regime a single
senior engineer running N parallel Claude agents lives in. Code generation is now nearly free; the
scarce resources are attention, shared understanding, and merge-ability. Brooks wrote the manual for
that scarcity fifty years early.

## Contents

- [The original argument](#the-original-argument)
- [Reinterpretation: one human + N AI agents](#reinterpretation-one-human--n-ai-agents)
- [Enforceable rules](#enforceable-rules)
- [Where the analogy breaks (state it honestly)](#where-the-analogy-breaks-state-it-honestly)

## The original argument

**Brooks's law.** "Adding manpower to a late software project makes it later." The mechanism is not
laziness; it is arithmetic. Work that can be perfectly partitioned scales linearly with people.
Work that requires communication scales with the number of _pairs_ — n(n−1)/2 — so intercommunication
cost grows quadratically while output grows at best linearly. Add the ramp-up cost of teaching a new
person the design (paid by the people who are already the bottleneck) and the marginal contributor
can be net negative. Brooks's corollary is the more useful half: the man-month is a myth _as a unit
of interchangeability_. Men and months are only interchangeable when workers do not need to
communicate — "bearing a child takes nine months, no matter how many women are assigned."

**The second-system effect.** The most dangerous system an architect ever designs is the second one.
The first is built under uncertainty and restraint, so it is lean. Having succeeded, the architect
now has a list of every frill they suppressed the first time, and no discipline left to suppress
them. The second system is over-general, over-featured, and tuned for a use case that has already
passed. The defense is self-awareness plus an explicit, defended budget for scope.

**Conceptual integrity.** Brooks's central design claim: "conceptual integrity is _the_ most
important consideration in system design." A system that reflects one set of coherent ideas is
better — easier to learn, easier to use, easier to extend — than one that contains many good but
uncoordinated ideas. Ratio of function to conceptual complexity is the real measure of design
quality, not raw function count. This is an argument for aristocracy in design: separate
architecture from implementation, and let a small number of minds (ideally one) own the external
specification while many hands implement it.

**The surgical team.** Harlan Mills's proposal, which Brooks adopts as the answer to "how do you get
the productivity of a small sharp team with the throughput of a large one." You do not build a team
of ten peers. You build a team around one _surgeon_ (the chief programmer) who writes the critical
code and owns the design, supported by specialized roles that exist purely to multiply the surgeon's
output: the copilot (a second mind who can take over but does not decide), the administrator, the
editor, the toolsmith, the tester, the language lawyer. Only one or two people are making design
decisions, so conceptual integrity survives; the rest of the team removes friction. Scale comes from
composing surgical teams, not from growing one.

**No Silver Bullet: essence vs. accident.** Brooks divides software difficulty in two. _Accidental_
difficulty is the friction of our tools and representations — assembly language, batch turnaround,
slow compiles, poor debuggers. _Essential_ difficulty is the irreducible complexity of specifying,
designing, and testing the conceptual construct itself: complexity, conformity to arbitrary external
worlds, changeability, invisibility. Historic order-of-magnitude gains all came from removing
accident. Since accident is now a minority of total effort, no single technology will produce
another 10x, because you cannot remove more than 100% of the accident. The essence remains.

## Reinterpretation: one human + N AI agents

The mapping is not metaphorical. It is nearly literal, because the failure modes are the same
failure modes with different actors.

**Communication overhead becomes context-sharing overhead.** Brooks's n(n−1)/2 was humans needing to
tell each other things. Agents cannot tell each other anything. Each subagent starts from a fresh
context window, reads the global files (`CLAUDE.md`, the spec, generated schemas) _once at start_,
and is thereafter blind to what its siblings do. So the pairwise-communication term does not merely
persist — it is worse, because the channel does not exist at all. Two humans in a room accidentally
overhear each other; two agents never do. Everything a sibling needs to know must be pushed into the
prompt before launch, or discovered at merge time as a conflict. The practical consequence: the
orchestrator pays the entire coordination cost, serially, and that cost is the real ceiling on
fan-out width. Not tokens. Not model capability. The orchestrator's ability to write N
non-overlapping briefs and reconcile N diffs.

**"Adding agents to a late feature makes it later."** The law survives translation with one
amendment: ramp-up cost is near zero (an agent reads the spec in seconds), but _reconciliation_ cost
is much higher than for humans, because agents will not negotiate. Two humans editing the same file
notice and talk. Two agents editing the same file each produce a confident, complete, plausible
version, and the orchestrator must read both fully to decide. So:

- Fan-out helps when the work is _genuinely partitionable_ — disjoint path sets, no shared artifact,
  each part verifiable on its own (separate app, separate package, docs + tests + implementation of
  independent modules, N independent investigations that only return findings).
- Fan-out hurts when subtasks converge on the same file, the same migration, the same generated
  artifact, or the same design decision that has not yet been made. Parallelizing an _undecided_
  design is the worst case: you get N confidently different answers and pay N review costs to
  extract one.
- The tell for "this is not partitionable": you cannot write the two prompts without one of them
  saying "coordinate with the other agent." If coordination is in the brief, the work is sequential.

**The surgical team becomes orchestrator + subagents.** This is the cleanest mapping in the book.
The senior engineer is the surgeon: owns the design, makes every decision that has more than one
defensible answer, and writes or personally reviews the load-bearing code. Subagents are the
supporting cast — toolsmith (build scripts, migrations, codegen), tester (write and run specs),
editor (docs, changelog, MR description), language lawyer (research an API, read the SDK, return
facts). The role that must never be delegated is the surgeon's: _deciding_. An agent asked to decide
will decide, plausibly, and you will not notice until three files depend on it. Note also Mills's
copilot: a second agent that reviews the same problem and can argue, but does not own the answer.
That is exactly the `/second-opinion` and review-panel pattern — a copilot, not a co-surgeon.

**Conceptual integrity becomes the single spec.** With humans, conceptual integrity erodes slowly
through good-faith disagreement. With agents it erodes instantly and invisibly, because each agent
constructs a _complete internal model of the system_ from whatever context it was given, and that
model is different for every agent. Two agents given the same feature description will invent two
different naming schemes, two error-handling conventions, two ideas of where the boundary sits — and
both will be internally coherent. Brooks's architect/implementer split is therefore mandatory, not
advisory: one written spec/ADR, authored before fan-out, read verbatim by every agent, is the only
thing that makes N outputs composable. If the spec does not answer a question, N agents will answer
it N ways. The corollary: the spec's job is not to be complete, it is to be _decisive on everything
that is contested_. Detail where agents would diverge; silence where they would converge.

**The second-system effect becomes the agent's default failure mode.** Ask an agent to improve
something and it will generalize it. It will add a plugin registry, a config object, an abstraction
layer, a fallback path beside the code it should have deleted. This is the second-system effect
running on every task, because the model has been trained on finished, mature, generalized systems
and regresses to that mean. The defense is the same as Brooks's — an explicit, defended scope budget
— plus one thing Brooks did not need: an explicit license to _delete_. Agents add defensively; you
must tell them, per task, that removing the old path inside their owned paths is expected.

**Essence vs. accident, 2026 edition.** LLMs are the largest attack on accidental difficulty since
high-level languages: boilerplate, API lookup, syntax, glue, test scaffolding, first-draft docs. All
accident, all substantially removed. Brooks's argument then predicts exactly what practitioners
observe — throughput of _code_ rises sharply, quality of _systems_ does not follow, because the
remaining work is essence: deciding what to build, conforming to an arbitrary external world
(ZITADEL, SpiceDB, GDPR, a customer's mental model), absorbing change, and reasoning about an
invisible structure. This is the reason the human's job shifts from writing to specifying and
verifying, and the reason a "10x from the next model" claim should be read skeptically: it can only
come from the shrinking accidental fraction unless the tool starts making _decisions_ correctly,
which is an essence claim, not a speed claim.

## Enforceable rules

Each row is checkable against a fan-out plan or a diff before work starts.

| #   | Rule                                                                                                                                                                      | Check (falsifiable)                                                                                                                                              | On violation                                                                       |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| B1  | Every fan-out agent prompt names the paths it **owns (may write)** and the paths it may only **read**                                                                     | Grep each launched prompt for an "owns" and a "read-only" clause                                                                                                 | Do not launch; rewrite the brief                                                   |
| B2  | Exactly one writer per file across the whole fan-out                                                                                                                      | Intersect the owned path sets pairwise; intersection must be empty                                                                                               | Merge the two tasks into one agent, or sequence them                               |
| B3  | Partition by directory/package, never by feature                                                                                                                          | Each owned set is expressible as a glob under one app/package                                                                                                    | Repartition; a feature that spans packages is one agent or several sequential ones |
| B4  | Shared/generated artifacts have a single owner: the orchestrator, edited only after rejoin                                                                                | Both `openapi.json` copies, `schema.zed`, migrations, `pnpm-workspace.yaml`, `turbo.json`, `CLAUDE.md`, `.claude/rules/**` appear in **no** subagent's owned set | Strip from the subagent brief; queue for post-rejoin                               |
| B5  | No fan-out before the contested decisions are written down                                                                                                                | A spec/ADR/plan file exists and is referenced by path in every brief                                                                                             | Serialize: one agent (or the human) decides first                                  |
| B6  | If a brief needs the phrase "coordinate with", the work is sequential                                                                                                     | Search the briefs for coordinate / sync with / align with the other agent                                                                                        | Serialize                                                                          |
| B7  | Agents never decide; agents propose or execute a decision already made                                                                                                    | Every brief states the decision or points at where it is written                                                                                                 | Rewrite the brief with the decision inlined                                        |
| B8  | Fan-out width is bounded by review capacity, not model capacity                                                                                                           | You can state, before launching, how you will verify each agent's output independently                                                                           | Reduce N                                                                           |
| B9  | Adding an agent to a late, entangled feature is forbidden                                                                                                                 | If the feature already has in-flight uncommitted work in the same paths, no new agent gets those paths                                                           | Finish or land the in-flight work first                                            |
| B10 | Overlapping writers that cannot be partitioned run in separate git worktrees                                                                                              | `isolation: "worktree"` set, or a real worktree per agent, and a named reconciliation step                                                                       | Do not run them concurrently in one tree                                           |
| B11 | Ports and local services are owned too                                                                                                                                    | Parallel local runs use isolated ports (see `.claude/rules/parallel-dev-setup.md`)                                                                               | Assign ports before launch                                                         |
| B12 | Each brief grants license to delete inside owned paths, and forbids fallback-beside-old-code                                                                              | Brief contains an explicit delete clause; diff shows removals, not only additions                                                                                | Reject the diff; ask for the removal                                               |
| B13 | Second-system guard: any diff that introduces a registry, plugin layer, config abstraction, or generic framework must justify it against a named second concrete use case | The use case is named in the MR description or the code comment                                                                                                  | Delete the abstraction; inline the one case                                        |
| B14 | The spec is decisive where agents diverge (naming, error shape, boundary, file layout), silent where they converge                                                        | Spot check: two agents given the spec would produce compatible interfaces                                                                                        | Add the missing decision to the spec, not to the code review                       |
| B15 | Conceptual integrity is reviewed as a first-class property at rejoin                                                                                                      | After merge, one pass asks only: does this read as one design, or as N designs stapled together?                                                                 | Refactor to one convention before the MR                                           |

## Where the analogy breaks (state it honestly)

- **Ramp-up is cheap for agents.** Brooks's "training the newcomer costs the experts' time" is much
  weaker; a good spec is read instantly. This is why fan-out _can_ pay off where adding a human
  would not. The cost has moved entirely to brief-writing and reconciliation.
- **Agents have no institutional memory and no pride.** They will not quietly preserve a convention
  they were not told about, and they will not push back on a bad instruction. Conceptual integrity
  must be _written_, because it cannot be _cultural_.
- **Agents are cheap to discard.** Brooks's "plan to throw one away" is nearly free now. Prefer
  running a risky approach in a worktree and deleting it over defending it.
- **The quadratic term is bounded by the orchestrator, not by N.** Agents never talk to each other,
  so the true topology is a star, not a mesh: cost is O(N) briefs plus O(N) reviews plus the
  pairwise _conflict_ term only where path sets overlap. Keeping the intersection empty (B2) is what
  collapses the quadratic back to linear. That single rule is the whole of Brooks's law, applied.
