---
name: second-opinion
description: "Independent review from a genuinely fresh agent session with zero conversation context \u2014 reconstructs intent from the spec alone, then judges the output against it. Use after a meaningful implementation or after a review, when you want a verdict that is not primed by the implementer's reasoning. Triggers on: second opinion, fresh eyes, independent review, sanity check this, am I fooling myself, review without context, cold review. Do not use for the in-context review panel \u2014 use full-review; nor as a substitute for the mechanical gates \u2014 use verification-loop."
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Second Opinion

An independent verdict on finished work from a reviewer that has **never seen the
conversation that produced it**.

## Why this is not the same as `/full-review`

`/full-review` already spawns subagents, and subagents already start with fresh context.
So what does this add? The difference is **who frames the question**.

When the implementing session spawns a reviewer, it writes the prompt. That prompt
inevitably encodes its own assumptions: "check that the caching layer invalidates
correctly" presupposes there should be a caching layer. "Verify the new `TokenBudget`
class handles the edge cases" presupposes the class should exist. The reviewer dutifully
audits the solution it was handed and never asks whether it is the right solution. Sharing
a premise is the failure mode; fresh context alone does not fix it.

Second Opinion removes the implementer from the framing, and runs the check on two independent engines so that agreement means something. The reviewer gets the
**requirement** and the **diff**, reconstructs what a correct solution looks like on its
own, and only then looks at what was built. It is allowed — expected — to conclude that
the whole approach is wrong, or that a prior review missed the point.

|                         | `/full-review`                     | `/second-opinion`                         |
| ----------------------- | ---------------------------------- | ----------------------------------------- |
| Framing                 | Implementer writes the prompts     | Reviewer derives it from the spec         |
| Question                | "Is this code correct?"            | "Is this the right thing, built simply?"  |
| Can reject the approach | Rarely — it audits what it's given | Yes, that's the point                     |
| When                    | During/after implementation        | After implementation **and** after review |
| Cost                    | High (8+ reviewers)                | Low (2 agents, one per engine)            |

Run `/full-review` for breadth. Run `/second-opinion` for independence. They are not
substitutes; the panel and the outsider catch different things.

**Blind-first is a floor, not a replacement for this skill.** Every panel reviewer is now
told to commit to its own expectation before reading the diff — the same reasoning order
this skill is built on. That buys a little independence inside a prompt the implementer
still wrote. It does not buy the thing that only happens here: a reviewer who never saw the
conversation, derives the requirement from its durable source, and is therefore free to
answer "rethink the approach". Do not let a panel that ran blind-first talk you out of
running this one.

## The discipline: what you must NOT pass

This is the whole skill. Leak any of these and you have re-created a primed reviewer with
extra steps:

**Never pass:**

- Your summary of what you built, or why you chose this approach.
- What you think the tricky or risky parts are.
- What you already verified, or your confidence level.
- Findings from a previous review, or the fact that one ran.
- Any reassurance ("the tests pass", "this follows the existing pattern").
- Your own naming for the solution's concepts, beyond what's in the diff.

**Always pass:**

- The requirement **verbatim** from its durable source — the Linear ticket body, the spec
  in `~/project-workspace/Tasks/`, the PRD, or the user's original message. Quote it;
  do not paraphrase, because paraphrase is where your interpretation enters.
- How to get the diff (the commands, not the diff pre-digested by you).
- Pointers to the repo's own documented standards — `CLAUDE.md`, `.claude/rules/`,
  `/coachbot-design` references, `MISTAKES.md` prevention index. These are shared ground
  truth, not your framing.
- The graph tools, so it can establish blast radius itself.

If no written requirement exists, **say so in the prompt** and let the reviewer judge
against the user's literal request. Do not substitute your reconstruction of intent — an
absent spec is itself a finding.

## Procedure

### 1. Locate the requirement

```bash
# Whichever applies — find the durable statement of intent, don't invent one.
ls ~/project-workspace/Tasks/
git log --oneline -1        # ticket id often in the branch or commit
git branch --show-current
```

Pull the Linear ticket body via `mcp__claude_ai_Linear__get_issue` if there is an ID.

### 2. Establish the diff scope (commands only)

```bash
cd ~/project-workspace/coachbot-monorepo
BASE=$(git merge-base main HEAD)
git --no-pager diff --stat "$BASE"; git --no-pager diff --stat
```

### 3. Spawn the reviewers

One `general-purpose` subagent, and the identical prompt on a second engine (step 4).
Send both in one message so they run in parallel and neither can see the other.
Use this prompt shape verbatim — the constraints are the product:

> You are reviewing work you did not write, with no knowledge of how or why it was
> written. Do not assume the implementation is close to correct.
>
> **The requirement, verbatim:**
>
> ```
> <paste the ticket/spec/user request — quoted, not summarised>
> ```
>
> **Step 1 — before looking at any code:** from the requirement alone, write down what a
> correct, minimal solution would need to change and what it must not break. Commit to
> that list first.
>
> **Step 2 — then read the actual change:**
>
> ```bash
> cd ~/project-workspace/coachbot-monorepo
> BASE=$(git merge-base main HEAD)
> git --no-pager diff "$BASE"; git --no-pager diff; git --no-pager diff --cached
> ```
>
> Use `mcp__code-review-graph__get_impact_radius_tool` (`detail_level: minimal`,
> `max_depth: 1-2`) and `get_review_context_tool` on the changed symbols to establish
> blast radius yourself before judging.
>
> **Step 3 — answer these, in order, and do not skip one because another went well:**
>
> 1. **Does it solve the stated requirement?** Name anything required but missing, and
>    anything present but not required.
> 2. **Is the approach right at all?** If a materially simpler or more conventional
>    approach exists for this codebase, say so plainly — even if that means discarding the
>    work. Judge against `CLAUDE.md`, `.claude/rules/`, and existing patterns in the repo.
> 3. **What breaks?** Concrete failure scenario with inputs → wrong behaviour. Include
>    callers outside the diff.
> 4. **What is unnecessary?** Code, abstraction, config, or dependency that could be
>    deleted with no loss. Give a line count.
> 5. **What did the author most likely not test?** Name the specific gap.
> 6. **Standards:** violations of `CLAUDE.md` / `.claude/rules/` / the
>    `/coachbot-design` references / the `MISTAKES.md` prevention index.
>
> **Rules:** do not edit files. Do not spawn agents. Do not soften findings to be
> agreeable. If the requirement itself is ambiguous or unstated, report that as a finding
> rather than guessing at it. Name the concrete failure in every finding, never a slogan —
> "best practice", "scalable", "future-proof", "cleaner" are claims, not reasons; if you
> cannot state inputs → wrong behaviour, you do not have a finding. Prefer a false negative
> to a false positive: an ambiguous case goes in **Not checked**, not into a guessed
> finding.
>
> Return: a verdict line (**ship** / **fix** / **rethink the approach**), then findings
> ranked by severity, each with `file:line`, the defect in one sentence, a concrete
> failure scenario, and the minimal fix. Close with a coverage block — **Checked** (what
> you verified and how) and **Not checked** (what is in scope but you could not verify, and
> why). This is required when you found nothing, not optional: an empty **Not checked**
> list claims total coverage. Your verdict is advisory; a human decides.

### 4. Second engine — default, not optional

**Run the same prompt on a second engine, every time.** Spawn the `codex:codex-rescue`
agent with the prompt from step 3, unchanged. Two reviewers on one engine share a training
prior; they agree for reasons that have nothing to do with your code. Cross-engine
agreement is the only agreement that carries information.

```
requirement ──┬──► general-purpose (Claude)  ──► verdict A
              └──► codex:codex-rescue (GPT)  ──► verdict B
                        │
        agree ──────────┴────────── disagree
          │                              │
     high confidence            the disagreement IS the finding
```

- **Both say ship** → strongest signal available. Ship.
- **Both say fix/rethink, same finding** → it is real. Fix it.
- **They disagree** → do not average them and do not pick the one you like. Take both
  verdicts to me with the specific point of disagreement named. That point is where the
  design is genuinely undecided.

**Never let one reviewer see the other's output, and never name the engine.** If you do
feed verdict A into a follow-up (only to resolve a factual disagreement, never to get an
opinion on the opinion), strip every engine name and call them "reviewer A"/"reviewer B".
Models behave differently toward text they can identify as another model's, and toward
text they think is their own — an identifiable label turns an independent check into a
negotiation.

If the Codex runtime is unavailable, **say so in the report**: "ran single-model, second
engine unavailable". Never let a skipped engine pass as a completed cross-check.

### 5. Receive it properly

The failure mode at this step is performative agreement:
accepting a finding because a reviewer stated it confidently, or dismissing one because
you already decided. For each finding, verify it against the code before acting.

**A "rethink the approach" verdict goes to the user, not into a silent rewrite.** Present
it, with your disagreement if you have one, and let them decide.

Anything the reviewer catches that a prior review missed is a gap in the review chain —
append to `MISTAKES.md` if it reveals a repeatable blind spot.

## Plan mode — before any code exists

The software factory runs this skill on its plan (`software-factory/phases/1-plan.md` § 1.7).
Same discipline, two substitutions: the requirement is `Tasks/<slug>/requirement.md`
(the owner's words, verbatim), and Step 2 reads `Tasks/<slug>/plan.md` instead of the diff.
Question 1 becomes "does the plan meet every point of the requirement", question 3 "which real
run of this plan produces a wrong outcome". From round 2 on, `plan.md` carries earlier findings, so pass
`plan-review-copy.md`: the plan with its "Critics and second opinion" section cut. A reviewer
who sees earlier findings audits them instead of the plan.

## When to run it

- After a meaningful implementation, before opening an MR.
- After `/full-review`, when the findings all came back minor and that feels too easy.
- When you have iterated three or more times on the same code — by then you are invested
  in the approach and are the worst available judge of it.
- Before anything hard to reverse: a migration, a published API shape, a deploy.
- On every software-factory plan, before the owner sees it (plan mode, above).

Skip it for typo fixes, formatting, and mechanical renames. The cost is one agent, but the
signal is diluted if you run it on work that has no design content.
