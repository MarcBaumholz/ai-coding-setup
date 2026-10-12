# Beyond Vibe Coding — Addy Osmani

Source: Addy Osmani, _Beyond Vibe Coding: From Coder to AI-Era Developer_, O'Reilly Media, 2025
(ISBN 979-8341634756, ~250 pages).

Verified sources used for this summary (fetched, not recalled):

- Publisher listing: https://www.oreilly.com/library/view/beyond-vibe-coding/9798341634749/
- Companion site with the full argument structure: https://beyond.addy.ie/
- Chapter 1, "Introduction: What Is Vibe Coding?": https://www.oreilly.com/library/view/beyond-vibe-coding/9798341634749/ch01.html
- Chapter 4, "Beyond the 70%: Maximizing Human Contribution": https://www.oreilly.com/library/view/beyond-vibe-coding/9798341634749/ch04.html
- Chapter 9, "The Ethical Implications of Vibe Coding": https://www.oreilly.com/library/view/beyond-vibe-coding/9798341634749/ch09.html
- Author interview, The Pragmatic Engineer: https://newsletter.pragmaticengineer.com/p/beyond-vibe-coding-with-addy-osmani
- The originating essay, "The 70% Problem: Hard Truths About AI-Assisted Coding": https://addyo.substack.com/p/the-70-problem-hard-truths-about

Note on fidelity: the O'Reilly chapter bodies are paywalled (HTTP 403 to unauthenticated fetches).
What follows is grounded in the companion site, the publisher's chapter titles and descriptions, the
author's own long-form essay that the book expands, and the author's interview. Where a claim is the
author's, it is attributed; where it is this factory's extrapolation, it says so.

This is the bridge file. Brooks explains why coordination is expensive; Lau explains how to allocate
attention; Osmani is the only one of the three writing about the actual mechanics of the tool we
use every day. Treat this as the operating manual and the other two as the physics.

## Contents

- [Vibe coding vs. AI-assisted engineering](#vibe-coding-vs-ai-assisted-engineering)
- [The 70% problem](#the-70-problem)
- [Specs and context engineering](#specs-and-context-engineering)
- [The verification burden shifts to the human](#the-verification-burden-shifts-to-the-human)
- [Agentic workflows](#agentic-workflows)
- [Code review in the age of generated code](#code-review-in-the-age-of-generated-code)
- [Maintainability debt from AI output](#maintainability-debt-from-ai-output)
- [Enforceable rules](#enforceable-rules)
- [The one-line version](#the-one-line-version)

## Vibe coding vs. AI-assisted engineering

Osmani's opening move is a definitional one, and it is the most useful thing in the book, because
almost every argument about AI coding is two people using one word for two activities.

**Vibe coding** (the term originates with Andrej Karpathy, February 2025) is generating software by
conversation without a plan and without reading the output — you describe, the model produces, you
run it, you describe the next thing. Its defining property is not the tool but the _abdication of
review_: you accept code you have not understood. Osmani does not condemn it. He scopes it: it is
legitimate and excellent for prototypes, throwaway scripts, personal tools, spikes, design
exploration, and anything whose failure costs nothing.

**AI-assisted engineering** is the same tooling operated with intent: a specification first,
deliberately assembled context, generated code treated as a draft from a fast but unaccountable
junior, and verification as a first-class activity. Same models, same IDE, entirely different risk
profile.

The book's thesis is that the industry conflated the two, adopted vibe coding's _ergonomics_ for
production work, and is now paying for it. The subtitle — _From Coder to AI-Era Developer_ — names
the shift: the valuable skill moves from producing code to specifying, contextualizing, and
verifying it.

The practical rule that falls out: **decide which mode you are in, explicitly, before you start**,
and make the mode visible. Vibe mode in a worktree that will be deleted, on a prototype nobody
depends on, is fine and fast. Vibe mode on a migration, an auth path, or a published API is how you
end up owning code that nobody in the building understands.

## The 70% problem

The book's central and best-known argument, expanded from Osmani's essay of the same name.

The observation: AI gets you roughly 70% of the way to a working application with startling speed —
scaffolding, boilerplate, CRUD, glue, plausible UI, first-draft tests. The last 30% is where it
stalls, and that 30% is _exactly_ the part that determines whether software survives contact with
production: correctness at the edges, error handling, performance under real load, security,
integration with the arbitrary constraints of your actual system, and maintainability.

Osmani's key sharpening is that the 30% is not "harder work of the same kind." It is a _different
kind_ of work, requiring a model of how the system actually behaves — which the AI does not have and
the vibe-coding workflow never builds in the human either. Hence the observed pattern he calls out
in the essay: people report large productivity gains while shipped software quality does not
visibly improve. Speed at the first 70% does not move the completion date, because the last 30%
was always the schedule.

He names the failure modes of pushing through the last 30% by prompting: **cascading bugs** (each
fix generating two more, because neither party holds the invariants), **hidden maintenance cost**
(code that works and cannot be changed), **diminishing returns** (the twentieth prompt is worse than
the fifth), and **security gaps** (the model optimizes for the happy path it was shown).

**The knowledge paradox** is the corollary and the part most relevant to a senior engineer running
agents: _AI helps experts more than beginners._ Seniors use it to accelerate work they already
understand — they refactor generated code into focused modules, add edge cases, tighten types,
question the architecture, and recognize wrong answers on sight. Juniors and non-engineers use it as
a substitute for understanding, accept output readily, miss the security and performance
dimensions, and then cannot debug code they did not write. The gap widens rather than narrows. The
factory implication: the human in the loop is not overhead to be optimized away — the human's model
of the system _is_ the last 30%.

Osmani names three workflows that work in practice:

- **AI first draft** — let the model produce the initial implementation, then personally refactor
  for modularity, add error handling, write the real tests, document the decisions.
- **Constant conversation** — start a fresh session per task, keep context tight and focused, review
  frequently, keep the feedback loop short. (Long, drifting sessions are where quality decays.)
- **Trust but verify** — generate freely, but manually review the critical paths, test edge cases,
  and security-audit anything touching auth, data, or money.

## Specs and context engineering

Osmani's prescription for the front half of the problem is **spec-driven development**. In the
Pragmatic Engineer interview he describes it as his current focus: "having a very clear plan" before
generation. Concretely — ask for architectural options and an outline before asking for code; write
a mini-PRD or spec that states requirements, constraints, non-goals, and the interfaces; then
generate against it. The spec is not bureaucracy; it is the artifact that makes the model's output
checkable, because without a written intent there is nothing to check the output _against_ except
your vibes at the time.

**Context engineering** is his term for the discipline that replaces prompt engineering. A prompt is
a sentence; context is a constructed information environment — the relevant source files, the
schema, the error logs, the conventions, the API docs, the failing test — assembled deliberately for
this request. His argument is that most disappointing AI output is a context failure, not a model
failure: the model answered the question it was actually asked, which was underspecified. The
practical skills are curation (what goes in), exclusion (what must not, because irrelevant context
degrades output), and freshness (stale context produces confidently outdated code).

This maps one-to-one onto how this repo is set up: `CLAUDE.md`, the glob-triggered
`.claude/rules/`, the knowledge graphs, and the skills _are_ the context-engineering layer. Their
purpose is to make the right context load without anyone remembering to paste it. Their risk is
Lau's operational burden: context that is wrong is obeyed.

## The verification burden shifts to the human

This is the argument that should change your daily behavior most.

When a human writes code, understanding is a _byproduct_ of writing it — by the time it compiles,
the author has a model of it. When a model writes code, that byproduct disappears. Understanding
must now be produced by a separate, deliberate act: review, testing, running it, reading it. Osmani
is explicit that code review, testing, and security validation are non-negotiable, and that
generated code should be treated like a junior developer's output requiring scrutiny before
production.

The asymmetry that makes this hard: generation got ~10x faster, verification did not get faster at
all. Reading code for correctness is the same speed it always was — arguably slower, because
AI-generated code is _fluent_, and fluency suppresses suspicion. Human-written bad code usually
looks bad. AI-written bad code looks like the code in the tutorial, right up to the missing tenant
filter.

Three consequences worth internalizing:

1. **Verification, not generation, is the throughput limit.** If you cannot review it, do not
   generate it. Batch size must be bounded by review capacity (this is the same constraint as
   Brooks's B8).
2. **Prefer verification you do not have to perform.** A test, a type, a lint rule, a schema
   constraint, a database constraint, a failing CI job — each converts a human reading task into a
   machine checking task, permanently. This is Lau's iteration-speed habit pointed at the specific
   bottleneck the AI era created.
3. **Never claim done from the model's assertion.** "I've implemented and tested this" is generated
   text with the same epistemic status as the code. Evidence is a command and its output.

## Agentic workflows

The book's later sections cover multi-agent orchestration: specialized roles (planning, coding,
testing, review) coordinated in a pipeline, with human oversight retained throughout. Osmani's
position, consistent with the rest of the book, is that autonomy raises the stakes on verification
rather than removing the need for it — as agents take more of the implementation, the human's job
concentrates further into specifying and checking.

Two cautions that follow directly from his framing and are worth stating as factory policy. First,
an agent pipeline that reviews its own work is not verification; a reviewer built from the same
model with the same premises inherits the same blind spots (this is precisely why an independent,
unprimed second opinion exists as a separate layer here). Second, agentic autonomy multiplies the
cost of a bad spec — a wrong premise that used to produce one wrong function now produces a wrong
subsystem across ten files, all internally consistent.

## Code review in the age of generated code

Review changes character when the author is a model. Osmani's guidance — treat it as junior output —
is right but incomplete in one respect worth naming: reviewing generated code requires _different
questions_ than reviewing human code, because the error distribution is different.

Human authors make errors of _effort and knowledge_: forgotten cases, typos, misunderstood APIs.
Models make errors of _plausibility_: code that follows the shape of a correct solution while
missing the constraint that makes it correct here. So the high-yield review questions become:

- Does this fabricate an API, option, or column that does not exist? (Check it, do not assume.)
- Does it silently drop a constraint the codebase enforces everywhere else (tenant scoping, actor-
  first signature, permission check, error-handling convention)?
- Is there a fallback, try/catch, or default sitting beside the old path instead of replacing it?
  (Models add rather than delete.)
- Is the abstraction earned, or is it the trained-in generic shape? (Registries, config objects,
  strategy patterns appearing unbidden.)
- Do the tests actually assert behavior, or do they assert the implementation back to itself?
  (Generated tests frequently mirror the code, so they pass by construction and catch nothing.)
- Is this consistent with the _rest of the system_, or only with itself?

## Maintainability debt from AI output

The book's most durable warning. AI-generated code can be locally correct and globally corrosive:
duplicated logic instead of reuse (the model does not know your helper exists unless you put it in
context), inconsistent conventions across files written in different sessions, over-general
abstractions nobody needed, dead fallbacks, and — the expensive one — **code nobody in the
organization has ever understood.**

Osmani's framing is that rushing the first 70% without regard for maintainability accumulates debt
that the last 30% then has to be paid through. This is a compounding cost, and it compounds faster
than human-written debt for two reasons: volume (you generate more) and uniform plausibility (it all
looks fine, so it is not triaged).

The defenses are unglamorous and all of them are cheap if done at authoring time and expensive
later: keep sessions scoped, require deletion rather than layering, enforce one convention through
rules the agent reads, review for system-fit rather than local correctness, and refuse to merge code
you cannot explain. The last one is the whole book in a sentence — Osmani's "from coder to AI-era
developer" is a transition into being the person who can still explain the system.

## Enforceable rules

| #   | Rule                                                                                                                                        | Check (falsifiable)                                                                                                | On violation                                 |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | -------------------------------------------- |
| V1  | Declare the mode before starting: **vibe** (throwaway, worktree, prototype) or **engineering** (anything that will be merged)               | Ticket/session states the mode; vibe-mode work lives in a branch or worktree marked disposable                     | Stop; re-run the task in engineering mode    |
| V2  | Vibe mode is forbidden on: auth, permissions, migrations, money, PII handling, published API shapes, deploy config                          | Diff touches those paths → engineering mode evidence required (spec + tests + review)                              | Redo with a spec and tests                   |
| V3  | No generation without a written spec for anything larger than a single function: requirements, non-goals, interfaces, constraints           | The spec file/ticket section exists and is referenced by the prompt                                                | Write the spec first                         |
| V4  | Context is assembled deliberately and stated: which files, schema, docs, and errors were given to the agent                                 | The prompt or plan lists its context sources                                                                       | Rebuild the prompt                           |
| V5  | Stale context is treated as a defect: any rule, doc, or spec found to be wrong is fixed in the same session it is discovered                | Fix commit exists in the same session                                                                              | Fix it now, not later                        |
| V6  | Batch size is bounded by review capacity — never generate more than you will actually read                                                  | Before merge, you can state you read every changed line, or name the mechanical check that covers what you did not | Split the change                             |
| V7  | Every completion claim is backed by a command and its output, never by the model's assertion                                                | The MR/summary contains the command and result                                                                     | Downgrade the claim to unverified and run it |
| V8  | Prefer mechanical verification over human reading: add the type, test, lint rule, or DB constraint that makes the class of error impossible | For each bug found in review, ask whether a check could have caught it; add it when cheap                          | Add the check with the fix                   |
| V9  | Generated tests must fail when the behavior is broken — prove it once by breaking the code                                                  | You ran the test against a deliberately broken version at least once for new critical tests                        | The test is decorative; rewrite it           |
| V10 | Every API, option, column, and function the model used is verified to exist                                                                 | Type-check passes plus a grep/docs check for anything unfamiliar                                                   | Fix before review                            |
| V11 | System-fit review is mandatory and separate from correctness review: does this follow the conventions the rest of the repo follows          | One review pass answers this explicitly                                                                            | Refactor to the convention                   |
| V12 | No fallback beside the old path — replace and delete inside owned paths                                                                     | Diff shows deletions where a behavior was replaced                                                                 | Remove the dead path                         |
| V13 | Unearned abstractions are removed: a registry/plugin/config layer needs a second real caller today                                          | Name the second caller                                                                                             | Inline the single case                       |
| V14 | Fresh session per task; long drifting sessions are ended and restarted with a compact handoff                                               | Session covers one task, or a handoff doc exists                                                                   | Restart with `/handoff`                      |
| V15 | Self-review by the same model family and premises does not count as independent verification for anything risky                             | Risky changes get either a human read or an independently briefed, unprimed reviewer                               | Add the independent pass                     |
| V16 | Refuse to merge code you cannot explain under challenge — why this approach, why not the alternative, what breaks if it is wrong            | You can answer those three out loud                                                                                | Do not merge; understand it or delete it     |
| V17 | The last 30% is planned as work, not discovered as overrun: edge cases, errors, performance, security, and docs are explicit subtasks       | The plan lists them                                                                                                | Add them before estimating                   |

## The one-line version

The model produces the first 70%; the last 30% is your model of the system, and it is the only part
that decides whether the software survives. Specify before generating, engineer the context, verify
mechanically wherever you can, and never merge what you cannot explain.
