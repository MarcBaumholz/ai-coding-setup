---
name: verify-loop
description: "Drive the running app through a change's Definition of Done in a real browser until every item is green or the loop hits a stop rule — screenshots, console and network checks included. Use when a change needs to be proven working rather than argued about, when the user says run it and test it until it works, or asks whether a feature actually does what the ticket promised. Triggers on: verify, verify-loop, teste das durch, fahr das durch, bis es funktioniert, prove it works, test it in the browser, is it really working, DoD durchgehen. Do not use to hunt for unknown defects adversarially — use stress-test; nor for a one-off page lookup, where a direct browser tool is enough. If the ask is vague (\"teste meine App\", \"mach mal QA\", \"test my app somehow\") there is no DoD to drive, so do not stop on the DoD gate - hand it to stress-test, which sizes itself."
version: 0.1.0
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Verify loop

Empirical verification: bring the app up, drive it, look at it, fix the obvious,
repeat. Replaces the hand-built version of this loop — the one that costs ~1300
browser calls and a stack of pasted screenshots per feature.

This skill proves **observable behaviour**. It does not review code — that is
`/full-review` — and it does not run the mechanical gates — that is `/ci`.

## The hard gate: no checkable DoD, no loop

Before anything starts, you must be able to write down each item as a
**concrete, observable outcome** — an action, and what should be true after it.

```
✅ "Upload ethics.pdf in Studio → knowledge list shows it as Ready within 60s,
    no console error, POST /api/knowledge returns 200"
❌ "Knowledge upload works"
❌ "RAG is better"
```

If the items are not in that shape, **stop and convert them first** — pull them
from the Linear ticket's `## Definition of Done`, or from
`~/project-workspace/Tasks/<slug>/plan.md`. If they still cannot be phrased
that way, say so and ask. A vague target turns this loop into an expensive
random walk, which is exactly the slop FACTORY.md warns about.

## Step 0 — Collect the target

1. Find the DoD, in this order: the Linear issue (`get_issue`, read
   `## Definition of Done`) → `Tasks/<slug>/plan.md` → the MR description's
   `## Test plan` → ask the user.
2. Restate every item as `action → expected observable` and show the list.
3. Note which items are **not** browser-checkable (a migration rollback, a cron
   job, a queue retry). Those do not belong in this loop — list them separately
   as "needs another method" and do not silently skip them.

## Model routing — the driver may be cheap, the judge may not

When this loop runs as a delegated subagent, give it **`model: sonnet`**. Driving
a browser through a list of `action → expected observable` items is execution, not
judgement: the comparison is mechanical because Step 0 already fixed what counts
as PASS. Sonnet 5 carries the same 1M context and the same high-res vision tier as
Opus at roughly 2.5× less cost, and this loop is the most call-heavy phase in the
pipeline. Same rationale as `agents/qa-explorer.md`, which is Sonnet precisely
because it never emits a verdict.

What does **not** move to the cheap model:

- **Converting a vague DoD into observable items** (Step 0's hard gate) — that is
  a judgement about intent, and getting it wrong makes every later PASS worthless.
- **Deciding that a FAIL is acceptable, or that a BLOCKED item can be waived.**
  The loop reports; the orchestrator and the user decide.
- **Anything that reaches Step 3's "not an in-loop fix" class** — an
  architectural mismatch or a permission question goes back up, it does not get
  resolved cheaply.

Haiku is not an option here: 200K context and no high-res vision tier make it
unfit for exploratory browser work.

## Step 1 — Get an instance up

Never test against a stale server. Confirm what you are pointed at.

- Which checkout: the main one, or a worktree? A worktree runs on its own port
  slot and its own Docker stack — the setup and its eight hard-won gotchas live
  in `/second-instance`. **Read that skill instead of improvising**; in
  particular, kill by port (verified by PID), never by `pkill -f <worktree path>`.
- Health check before driving anything:
  `docker compose ps` healthy · `pnpm migrate:status` current ·
  a row count on a seeded table · `redis-cli ping`.
- Record the base URL and port in the report. Half the "it doesn't work"
  rounds are a browser pointed at the wrong instance.

## Step 2 — Drive it

Use the `chrome-devtools` MCP tools. One page, reused across rounds:

| Purpose | Tool |
| --- | --- |
| Open / reuse a tab | `new_page`, `list_pages`, `select_page` |
| Go somewhere | `navigate_page` |
| See the DOM as the agent sees it | `take_snapshot` |
| Act | `click`, `fill`, `fill_form`, `drag` |
| Wait for async work | `wait_for` |
| Evidence | `take_screenshot` |
| **The two checks that are usually skipped** | `list_console_messages`, `list_network_requests` |
| Mobile / responsive items | `emulate`, `resize_page` |

Per DoD item:

1. Navigate, act, `wait_for` the expected state — never a fixed sleep.
2. `take_screenshot` — this is the evidence, not decoration.
3. `list_console_messages` → **any error or warning is a finding**, even when
   the UI looks correct. This is where silent breakage hides.
4. `list_network_requests` → check the request that matters actually fired and
   its status. A green-looking UI over a failed POST is the classic false pass.
5. Mark the item `PASS` / `FAIL` / `BLOCKED`, with the screenshot and the
   observed-vs-expected delta in one line.

Prefer `take_snapshot` over screenshots for *deciding what to click*; use
screenshots for *proving what happened*.

## Step 3 — Fix, but only the obvious

**`--report-only` skips this step entirely.** Record every failing item with its evidence and
go to Step 4. The software factory's verifier runs this way: it checks holdout scenarios the
implementer never saw, and a verifier that fixes code has become a second implementer who
read them. Report-only applies to the whole run, not item by item.

In-loop fixing is allowed for the narrow class of defects where the cause is
unambiguous from the evidence: a wrong selector, a missing `await`, an off-by-one
label, a missing i18n key in `de.json`, a null guard. Apply it, re-run **that
item only**, continue.

Anything else — an architectural mismatch, a permission model question, a
product decision, a failure you cannot explain — is **not** an in-loop fix.
Record it and carry on with the remaining items. A verify loop that starts
redesigning is a verify loop that never terminates.

If a fix touches server code, permissions, or a migration, note that
`/full-review` must run afterwards; this loop does not substitute for it.

## Step 4 — Stop rules (all of them are hard)

Stop and report at the first of these:

1. **Green** — every browser-checkable item PASS.
2. **Same failure twice** — an item fails, you fix, it fails the same way again.
   Two identical failures mean the mental model is wrong, not the code. Hand it
   to `mattpocock-skills:diagnosing-bugs` with what you observed.
3. **Round cap** — 5 rounds over the full item list. Not negotiable by
   "almost there".
4. **A decision only the user can make** — anything about intended behaviour,
   scope, or a trade-off. Ask, do not guess. The agent never stands in for the
   human's side.
5. **Budget** — this loop is browser-call heavy and burns the 5h/7d quota
   visibly (that is what the statusline gauge is for). If the context is past
   compaction pressure, stop, write the report, and let the user resume fresh.

Never loop silently. Report progress after each round: `Runde 2/5 — 6/9 grün,
2 offen, 1 blockiert`.

## Step 5 — Report

```
## Verify-Loop — <slug>
Instanz: <base URL>, <worktree|main>, Runden: <n>/5

| # | DoD-Item | Status | Beweis |
|---|----------|--------|--------|
| 1 | Upload PDF → Ready <60s | ✅ PASS | shot-01.png, POST 200 |
| 2 | Retrieval zitiert Quelle | ❌ FAIL | shot-02.png — 0 Zitate, erwartet ≥1 |
| 3 | Mobile-Chat scrollt | ⛔ BLOCKED | braucht Entscheidung: Zielbreite? |

### In der Schleife gefixt
- <datei:zeile> — <was, in einer Zeile>

### Nicht browser-prüfbar (andere Methode nötig)
- Migration-Rollback → `/ci` bzw. manuell up→down→up
- Queue-Retry-Idempotenz → Job mitten im Lauf killen

### Console / Network
- <jede Error- oder Warn-Zeile, mit dem Item, bei dem sie auftrat>

### Nächster Schritt
<konkret: /full-review · mattpocock-skills:diagnosing-bugs · Entscheidung von dir · fertig>
```

Save the report to `~/project-workspace/Tasks/<slug>/verify.md` when a
`<slug>` folder exists, so the next session can start from it.

## Step 6 — Put the evidence on the MR, not in the chat

**A report that lives only in the scrollback is not evidence at the moment of
merge.** The decision to merge happens in GitLab, so the screenshots and the
observed-vs-expected table have to be there. This is what makes it defensible to
merge without reading every line: the reviewer sees *what the running app did*,
not a claim that it worked.

Skip this only when there is no MR yet. Otherwise, two commands:

```bash
# 1 · upload each screenshot; the response carries the ready-to-paste markdown
glab api --method POST "projects/coachbot-ai%2Fcoachbot-monorepo/uploads" \
  --form "file=@shot-01.png"
# → {"id":…,"alt":"shot-01","url":"/uploads/<hash>/shot-01.png",
#    "markdown":"![shot-01](/uploads/<hash>/shot-01.png)"}

# 2 · post the report with those markdown strings embedded, as one note
glab mr note <iid> --message "$(cat ~/project-workspace/Tasks/<slug>/verify.md)"
```

**Use the `markdown` field verbatim — do not add a `!` in front of it.** For an
image upload GitLab already returns the embed form (`![alt](url)`), so prefixing
it yields `!![alt](url)`, which renders as a literal `!` followed by a broken
image. Verified against the live endpoint 2026-08-12. For a non-image attachment
the same field comes back as a plain link, which is also correct as-is.

Build the note by appending a `### Screenshots` section to the Step 5 report, one
uploaded image per item that has one. Post **one** note per verify run, not one
per item; a wall of comments is noise and reviewers stop reading it.

**For a bug fix the section is a Before / After table, not a single shot.** The
"before" half is captured while reproducing the bug, before the fix exists. That is
the cheapest moment: the failing state is on screen anyway, and it can never be
re-captured once the fix lands. `red-test.sh` is the same rule for tests; this is
the rule for behaviour. Take the shot from the same instance, route and viewport
as the after shot, and use the uploaded `markdown` fields verbatim:

```markdown
### Before / After

| Before (bug, commit abc1234) | After (fix, commit def5678) |
| --- | --- |
| ![before-01](/uploads/<hash>/before-01.png) | ![after-01](/uploads/<hash>/after-01.png) |
| 0 citations shown, console: `TypeError …` | 3 citations shown, console clean |
```

One row per DoD item that a bug touched, the observed delta in the second row.
A fix MR with only an after shot is a claim about the past that nobody can check.
Non-visual fixes get the same table with output pairs: the failing command output
against the passing one. (Pattern from vercel-labs/before-and-after; their CLI is
not used because its default upload host is public, and Studio screenshots carry
seeded org and coach names.)

Two rules on what goes in the note:

- **FAIL and BLOCKED items stay in.** A note that shows only the green items is
  worse than no note, because it manufactures confidence. The point is that the
  reviewer sees the same picture you do.
- **Say which instance produced it** (base URL, worktree or main, round count) —
  the same reason Step 5 requires it. A screenshot from the wrong instance proves
  the wrong thing, and on the MR nobody can tell.

If the upload fails (token scope, network), post the report **without** the
images and say so in the note. Silently dropping the evidence section is the one
failure mode that defeats the whole step.

## Rules

- **Screenshots are evidence, not garnish.** A PASS without one is a claim.
- **Capture the failure before you fix it.** When the DoD is a bug fix, the first
  round reproduces the bug and screenshots it before any code changes. No before
  shot means the Before / After table in Step 6 cannot be built.
- **Never report green on an unchecked item.** Say `BLOCKED` and why.
- **The agent may never `git commit` or `git push`** — the global hook
  (`~/.claude/hooks/block-git-commit-push.sh`) denies it. Hand those to the user.
- **Console warnings count.** They are the cheapest early signal in the whole
  pipeline and the easiest to wave away.
- **State the instance in every report.** Wrong-instance testing is the most
  common false result.
