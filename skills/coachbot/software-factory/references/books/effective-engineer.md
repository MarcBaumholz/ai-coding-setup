# The Effective Engineer — Edmond Lau

Source: Edmond Lau, _The Effective Engineer: How to Leverage Your Efforts in Software Engineering to
Make a Disproportionate and Meaningful Impact_, Effective Bookshelf, 2015.

- Official site: https://www.effectiveengineer.com/book
- Author's notes and excerpts: https://www.effectiveengineer.com/blog

**Naming note.** This is sometimes referred to as "The Effective Software Engineer." That is not the
title. The book is _The Effective Engineer_ by Edmond Lau (Quora, Google, Ooyala). There is a
separate, unrelated 2024 book by Joe Reis titled _Fundamentals of Data Engineering_-adjacent
material, and various "effective software engineer" blog series; none of them are this. When someone
in this factory says "the effective engineer book," they mean Lau.

Why it is here: Brooks tells you why coordination is expensive. Lau tells you how to decide what to
spend your remaining time on. In a factory where an agent can produce any given feature in an hour,
the binding constraint is no longer implementation capacity — it is choosing correctly, and not
drowning in the operational exhaust of everything you already shipped. Lau's book is, almost
uniquely in the genre, a book about _allocation_.

## Contents

- [The central equation](#the-central-equation)
- [The habits, and what each actually means](#the-habits-and-what-each-actually-means)
- [Translation to a human-plus-agents factory](#translation-to-a-human-plus-agents-factory)
- [Leverage triage — deciding whether to build at all](#leverage-triage--deciding-whether-to-build-at-all)
- [Enforceable rules](#enforceable-rules)
- [The one-line version](#the-one-line-version)

## The central equation

**Leverage = impact produced / time invested.**

Every activity has a leverage number. Effective engineers are not the ones who work more hours or
type faster; they are the ones who systematically shift their hours toward high-leverage activities.
Lau's three questions for raising leverage on any task:

1. How can I complete this activity in a shorter amount of time?
2. How can I increase the value produced by this activity?
3. Is there something _else_ I could spend my time on that would produce more value?

Question 3 is the one everyone skips, and it dominates the other two. Doing the wrong thing twice as
fast is negative leverage, because you now have twice as much wrong thing to maintain. Lau's framing
also kills the "but it only took an hour" defense: an hour of build cost is a rounding error next to
the multi-year cost of owning the result.

## The habits, and what each actually means

**Optimize for learning.** Treat your skills as a compounding asset and pick environments,
projects, and rates-of-feedback that grow it fastest. Learning rate compounds like interest: a 1%
daily improvement is 37x in a year. Concretely — work at the steepest part of the curve, invest in
skills that transfer, and treat time spent understanding a system deeply as investment, not
overhead. This is _not_ a self-help aside; it is the justification for reading the code you shipped
and for refusing to ship things you cannot explain.

**Invest in iteration speed.** Lau's most operational habit. Fast tools are not a comfort; they are
a multiplier on every future action. He describes deploy velocity at Etsy/IMVU-style continuous
deployment, faster test suites, better debugging loops, and REPL-style experimentation as the
highest-leverage infrastructure work available. The insight is that iteration speed compounds
across everyone and every future task, so a one-time cost buys a permanent rate increase. Its
corollary is uncomfortable: if your feedback loop is slow, _fixing the loop outranks the feature you
were about to build._

**Validate ideas early and often.** Build the smallest thing that produces a real signal, then let
the signal decide. A/B tests, prototypes, mock data, a one-page spec shown to a user, a shell script
before a service. The failure mode Lau names is the multi-month project whose core assumption was
never tested — where the first honest feedback arrives after the sunk cost is unrecoverable. He
frames the entire practice as _reducing the cost of being wrong_, which is the only durable defense
in a domain where you are wrong often.

**Measure what you want to improve.** Pick a metric that actually captures the goal, instrument it,
and use it to decide. Lau is blunt about the traps: metrics you _can_ measure crowding out metrics
that matter; vanity metrics; and picking a metric that a smart person can game. The
positive claim is that a good metric is a decision-making tool, not a reporting artifact — it tells
you when to stop optimizing, which is at least as valuable as telling you where to start. Related:
measure baseline before you change anything, or you cannot claim an improvement.

**Minimize operational burden.** Do the simple thing first; embrace operational simplicity; build
systems that fail fast and loudly; and treat recurring toil as a bug in the system rather than as
work. Every service you run, every dependency you add, every manual step in a runbook is a
permanent tax on all future work. Lau's point is that complexity is not paid for once at build time
— it is paid every week forever, by the same people who wanted to build the next thing.

**Automate mechanically.** Automate the mechanical, repeated, deterministic steps — but not
prematurely, and not the parts that require judgement. Lau's heuristic is to automate when the
accumulated time cost exceeds the automation cost, and he warns against automating something you
do not yet understand well enough to specify. Related habits from the book: build feedback loops
into the tooling itself, and make the correct action the easy action.

**Other habits worth carrying.** Prioritize ruthlessly and continuously (maintain a single list of
what matters; revisit it, do not just execute it). Estimate badly on purpose is not the lesson —
rather, _treat your estimates as data_: track them and recalibrate. Improve project estimation by
decomposing until the pieces are things you have done before. Balance quality with pragmatism: code
review and tests are leverage, gold-plating is not. Invest in your team's success — in this factory,
"team" includes the tooling, skills, rules, and specs that your agents read.

## Translation to a human-plus-agents factory

Lau wrote for a human at a growth-stage company. Three of his premises change here, and the changes
sharpen rather than weaken the book.

**Implementation time collapses; decision time does not.** When "how can I do this faster" is
answered by a model, questions 1 and 2 lose most of their weight and question 3 — _should this exist
at all_ — becomes nearly the whole of leverage. The leverage equation's denominator is no longer
your typing time; it is your attention, your review capacity, and the permanent maintenance surface
you are about to create. Build cost approaches zero; **ownership cost does not move at all**. This
is the single most important adaptation of Lau to 2026: the cheapness of generation systematically
biases you toward building things whose lifetime cost you have not priced.

**Iteration speed now means agent feedback loops.** `pnpm check`, a targeted vitest run, a seeded
local DB, a browser probe that returns a computed value instead of a screenshot — these are the
loops. An agent with a fast, truthful loop converges; an agent with a slow or absent loop produces
confident, unverified output and stops. So Lau's "invest in iteration speed" becomes: _before adding
scope to a task, make sure the task has an automated way to tell it is wrong_. A missing test
harness is not a nice-to-have; it is the difference between an agent that self-corrects and an agent
that hallucinates completion.

**Operational burden includes agent-facing surface.** Every skill, rule, hook, MCP server, and
config file is context an agent must load and a thing that can drift out of date. Lau's tax applies
to the factory itself. A rule that is wrong is worse than no rule, because agents obey it. Prune the
factory the way you prune services.

**Automate mechanically maps directly onto the rules/skills/hooks/agents ladder.** The choice is not
whether to automate but at what weight: an in-repo comment, a glob-triggered rule, an invokable
skill, a settings.json hook, a subagent, an MCP server — in ascending order of cost. Lau's
"automate when accumulated cost exceeds automation cost" plus YAGNI says: always pick the cheapest
mechanism that fits, and only escalate on evidence of repetition.

## Leverage triage — deciding whether to build at all

Run this before any feature, refactor, or piece of tooling. It is designed to be answerable in ten
minutes and to produce a defensible "no."

**Step 0 — Name the outcome, not the artifact.** Write one sentence: "After this ships, <who> can
<do what> that they could not before, and we will know because <observable>." If you cannot write
the observable, stop; you are building a thing, not an outcome.

**Step 1 — Estimate the three costs.** Build cost (agent hours + your review hours). **Ownership
cost** (per-year: maintenance, on-call surface, migration drag, context every future agent must
load). **Opportunity cost** (the best thing not built). Ownership cost is the one people omit and
it is usually the largest.

**Step 2 — Estimate impact honestly.** Number of users or calls affected × frequency × size of the
improvement. If any factor is unknown, say "unknown" rather than guessing — an unknown factor is a
signal to go to Step 4 (validate) rather than to build.

**Step 3 — Compute the ratio and compare against the shelf.** Leverage = impact / (build +
ownership). Compare against the two cheapest alternatives that are always on the shelf: (a) do
nothing and see if anyone complains; (b) a manual/partial version (a script, a docs page, a
one-off query) that captures most of the value at 10% of the ownership.

**Step 4 — If uncertain, buy information instead of building.** The correct output of triage is
often not "build" or "skip" but "spend two hours reducing uncertainty": a prototype, a query against
production data, three user conversations, a spike in a worktree that will be deleted. Explicitly
time-box it and state what result would flip the decision.

**Step 5 — Write the kill criterion.** Before building, state what would make you delete this in six
months (usage below X, no adoption by date Y). A feature with no kill criterion becomes permanent
ownership cost by default.

**Verdicts.** _Build_ — high impact, bounded ownership, loop exists to verify it. _Thin-slice_ —
impact plausible, ownership high: ship the manual/partial version, revisit on evidence. _Validate_ —
impact unknown: buy information. _Decline_ — write one sentence on why, and put it where the next
person will find it (ticket comment, ADR); an undocumented "no" gets re-litigated every quarter.

## Enforceable rules

| #   | Rule                                                                                                                                                                         | Check (falsifiable)                                                                                    | On violation                                               |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------- |
| L1  | Every feature passes leverage triage before implementation starts; the verdict is written in the ticket                                                                      | The ticket contains outcome sentence + the three costs + verdict                                       | Do not start; run triage                                   |
| L2  | If a manual step has happened 3 times, automate it — with the cheapest mechanism that fits (comment < rule < skill < hook < agent < MCP)                                     | Grep the session/shell history or the ticket for the third repetition; propose within the same session | Propose the automation before doing the step a fourth time |
| L3  | Shorten the feedback loop before adding scope                                                                                                                                | The task has a command that returns pass/fail in under ~2 minutes; if not, that is the first subtask   | Build the loop first                                       |
| L4  | Measure before optimizing; record the baseline number in the ticket                                                                                                          | A pre-change measurement exists with the command that produced it                                      | Reject the optimization claim                              |
| L5  | No performance/quality claim without an after-number produced by the same command as the baseline                                                                            | Before and after values, same method                                                                   | Downgrade the claim to "unverified"                        |
| L6  | Ownership cost is estimated explicitly for anything that adds a service, dependency, table, config file, rule, or skill                                                      | A per-year cost sentence exists                                                                        | Add it or drop the addition                                |
| L7  | Prefer the standard library / native platform feature / existing package over a new dependency; a new dependency needs one sentence of justification naming what it replaces | `package.json` diff reviewed line by line; each addition justified                                     | Remove and inline                                          |
| L8  | Validate before building anything that takes more than a day of combined build+review                                                                                        | A prototype, data query, or user signal is referenced                                                  | Do the validation step                                     |
| L9  | Every new capability ships with the observable named in Step 0 instrumented, or with a stated reason it cannot be                                                            | The metric/event/log exists in the diff                                                                | Add the instrumentation or record the exception            |
| L10 | Every new feature has a kill criterion recorded                                                                                                                              | One line in the ticket or ADR                                                                          | Add it                                                     |
| L11 | Recurring toil is filed as a defect against the system, not absorbed silently                                                                                                | A ticket exists for the third occurrence of any manual fix                                             | File it                                                    |
| L12 | Learning is banked, not lost: any non-obvious thing discovered during a task lands in a rule, skill, doc, or the mistakes log in the same session                            | The artifact was updated in the same session, not "later"                                              | Write it now                                               |
| L13 | Do the simple thing first: a solution with fewer moving parts wins ties, and the tie must be explicitly broken in writing when it is not chosen                              | MR description names the simpler alternative and why it lost                                           | Reconsider                                                 |
| L14 | Factory surface is pruned: any rule/skill/hook not used or not true in 90 days is deleted or corrected                                                                       | Periodic sweep; each artifact has a last-validated marker or an owner                                  | Delete it — a stale rule is worse than none                |
| L15 | Estimates are tracked as data: record predicted vs. actual on anything estimated, at least coarsely                                                                          | Ticket has both numbers                                                                                | Record it; recalibrate next estimate                       |

## The one-line version

Generation is free, decisions are not, and ownership is forever. Spend your scarce attention on
choosing correctly and on making the feedback loop fast, then let the agents do the typing.
