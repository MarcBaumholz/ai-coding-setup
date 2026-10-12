# Phase 0 · Understand — AFK

**Goal**: be able to state, in your own words, what CoachBot is doing here, who
the user is, what already exists, and what the request actually changes. Nothing
downstream is trustworthy if this is guessed.

**You are not allowed to design in this phase.** Only to find out what is true.

## 0.1 Product understanding

Answer these before touching code. Look them up; do not ask what you can find.

1. Which surface is this — Studio (creator/admin), Chat (coachee), Admin
   (platform), or a worker? Who is the actual human?
2. What job is that human trying to get done, in their words?
3. How does the job get done **today** without this feature? (There is always a
   today. "Nothing" is almost never the true answer.)
4. What breaks for them if we build nothing?
5. Which existing concept does this extend — coach, session graph, traversal,
   thread, knowledge base, persona? Use the repo's vocabulary, not a synonym.

Sources, in order of cheapness: `CONTEXT.md` and the domain model (it does not
exist yet — `mattpocock-skills:domain-modeling` creates it lazily; if absent, use the vocabulary
already in the code and say so) · the
`company-brain` MCP (`recall`) for product/strategy context · Linear for
adjacent tickets · `docs/codebase-guide/` and `.claude/rules/session-graphs.md`.

## 0.2 Code understanding

1. **`code-review-graph` MCP first.** `semantic_search_nodes_tool` /
   `query_graph_tool` to locate the symbols; `get_impact_radius_tool`
   (`detail_level: minimal`, `max_depth: 1-2`) for the blast radius. Search
   symbol names, not prose. Measured savings on this repo are 89–97% versus
   reading files.
2. Fan out 2–3 `Explore` subagents for what the graph does not cover. Each
   prompt names the paths it may read. They return findings, not file dumps.
3. Library and API shapes come from the `context7` MCP. This repo is on Vercel
   **AI SDK 6 beta**; v5 recall is wrong and will look plausible.
4. List which glob-triggered `.claude/rules/` files apply to the paths you will
   touch, and read `references/doctrine/coachbot-invariants.md`.
5. Check `references/doctrine/coachbot-invariants.md` § "Known friction (do not rediscover)".

## 0.3 Output — the IST-Stand

Write to `~/project-workspace/Tasks/<slug>/00-understanding.md`:

- **The job**: one paragraph, in the user's language, answering 0.1.
- **How it works today**: with `file:line` citations. A reader must not need to
  open the codebase to follow you.
- **Blast radius**: the modules, tables, queues, and surfaces the change touches.
- **Applicable rules and invariants**: the list from 0.2.4.
- **Prior art**: existing code that already does something similar — the single
  highest-value section, because reuse beats invention.
- **Unknowns**: what you could not determine. These become Gate 1 questions or plan
  assumptions.
- **Reference**: if the request is "copy this from that", the reference by path or URL.

## Quality bar for this phase

You have understood it when you can answer, without re-reading: _why is it built
this way today, and what did that choice cost?_ If the only answer you have is
_what_ the code does, you have summarized, not understood. Go one level deeper on
the part that surprised you — the surprise is where the real constraint is.

## Exit

→ **Gate 1** (`gates/gate-1-scope.md`): premise check, then the one-screen scope yes.

## Stop rules

- The request turns out to span many sessions with real unknowns → route to
  the `code-review-graph` MCP tools (`get_architecture_overview_tool`, `semantic_search_nodes_tool`). This pipeline lands one change.
- The request is a known one-line fix → say so and drop out of the pipeline.
  Running a factory over a typo produces slop, not rigour.
