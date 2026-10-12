---
name: stress-test
description: Autonomously stress-test a shipped CoachBot feature in a real browser. Writes a product-grounded test charter, fans out parallel Sonnet browser agents across lanes (job-to-be-done, boundaries, cross-surface consistency, lifecycle, permissions, resilience, adversarial content), verifies their findings, and returns a ranked bug report plus a hardening backlog. This is the one QA entry point, so use it for any ask to test, QA or break the app, including a vague one that names no feature - "stress test X", "try to break X", "QA the RAG feature", "teste meine App", "teste die App irgendwie", "mach mal QA", "findest du Fehler", "test my app", "QA testing". Phase 0.0 routes by failure class and sizes the run down to one lane for a small change, so a vague ask is never a reason to skip it. Hand off to verify-loop only when a written Definition of Done already exists; do not use before the feature runs at all.
argument-hint: "what shipped (feature name, ticket, or 'the current diff')"
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Stress test

Try to break something we just shipped, the way a user would break it, and report
honestly. You are the orchestrator: **you** supply the product judgment and the verdict,
Sonnet explorers supply the hands.

The pre-MR gate is `/verification-loop` then `/full-review`, then the hand-off (Marc
runs git). This skill is the autonomous, browser-driven one and covers the human-driven
"QA a feature" role too. It is **review-and-report only — it never fixes anything.**

## Non-negotiables

- **Local only.** `localhost` / `127.0.0.1`. Never `app.example.test`, never production.
- **No repository writes and no git operations**, by you or any explorer. The output is a
  report.
- **Explorers never emit a verdict.** They report observations with evidence; you decide.
  If a report contains "works correctly" with no evidence, treat that lane as _not run_.
- **A clean report is a suspicious report.** If seven lanes come back with nothing, either
  the environment was broken or the lanes were too timid. Say which; do not present it as
  a pass.

---

## Phase 0.0 · Route and size the run

Two decisions before anything else. Both are cheap, and both default to wrong when skipped.

**1. Which failure class are you hunting?** A vague ask ("teste meine App", "mach mal QA")
names none, so read the diff and pick one. Say which you picked.

| Failure class | Cheapest tool that can see it | A lane here? |
| --- | --- | --- |
| Looks wrong, text overflows, breaks at 375px | `chrome-devtools-fast`: `evaluate` first, `screenshot` only if the question is genuinely visual | yes |
| Flow does not work, console error, failed request | `chrome-devtools-headless` | yes — most lanes |
| Surface looks healthy, the data behind it is wrong | a probe on the network payload or the repository row, never a screenshot | yes — and it is the class this product fails in |
| The wrong person can see it | L5, plus reading the repository query | yes |
| Must hold on every commit from now on | a Playwright spec | no — that is Phase 4, not a lane |
| Types, lint, unit tests | `pnpm run ci` | no — run it **before** the browser |

Run `pnpm run ci` first if the diff is not already green. A failing typecheck fans out into
seven lanes all reporting the same broken page.

**Reticle is not installed, deliberately.** `reticlehq/reticle` is a dev-only SDK that reads
network, store, console and route from inside the running app and can replay a saved flow with
no model in the loop. It would own the third row above. It is blocked on two things this skill
depends on: it sees no pixels, while Phase 3 requires a screenshot per finding, and it breaks
when two dev servers run at once, which Phase 1 recommends for destructive lanes. Do not reach
for it mid-run. Re-evaluate only after a separate pilot.

**2. How big is this run?** The default is not seven lanes.

| The change | Lanes | Second stack | Charter round with the user | Published HTML artifact |
| --- | --- | --- | --- | --- |
| One surface, no new state — a tab bar, copy, a list row | 1–2, read-only | no | skip it; name the lanes in one line and go | no, markdown + shots only |
| A feature with new state or a new route | 3–4 | no | yes | yes |
| Auth, money, deletion, migration, cross-app data | 5–7, incl. L5 and L6 | yes, per Phase 1 | yes | yes |

State the tier you chose and the reason, in one sentence, before Phase 0. The expensive parts
of this skill — the charter round, the second stack, seven parallel explorers, the published
artifact — are built for the bottom row. Spending them on a tab bar is the most common way a
run burns an hour and returns a report about buttons.

The non-negotiables above never scale down. A one-lane run still needs the probe, the
screenshot, and the honest Coverage section.

## Phase 0 · Understand what shipped, and for whom

Do not start the browser yet. A charter written without product understanding produces an
agent that clicks around and reports that buttons are clickable.

1. **Read the change.** `git log --oneline main..HEAD` and the diff for the named feature.
   If the user said "the current diff", that is your scope.
2. **Find the product intent**, in this order: the MR description (`glab mr view <n>`),
   the Linear ticket, `~/project-workspace/Tasks/<feature>/PLAN.md`, then the code
   comments — this codebase puts the _why_ in comments, and they are usually the best
   source.
3. **Name the persona and the job.** CoachBot has two, and they break things differently:

   |                             |                                                                                                                                                                           |
   | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | **Coach designer** (Studio) | Configures a coach and its knowledge. Needs to know whether what they configured _actually reaches a coachee_. Their characteristic failure is believing a green surface. |
   | **Coachee** (Chat)          | Talks to the coach. Never sees Studio. Their characteristic failure is a confident, ungrounded answer.                                                                    |

   A feature that only works for the first persona is not shipped. **Most lanes must cross
   from Studio into chat**, because that boundary is where this product's bugs live.

4. **Write the charter.** Keep it short and concrete:
   - The **job** as one sentence, in the persona's words.
   - The **invariants** the feature claims — the promises a user would feel betrayed by.
     Pull them from the code's own comments; they are usually stated there explicitly.
   - **Break hypotheses**: 5–10 specific guesses at how it fails. Be adversarial and be
     specific. "Upload a document, turn the flag off, and see whether the chunk UI still
     claims it is retrievable" is a hypothesis. "Test edge cases" is not.
   - The **lanes** you are running, from `LANES.md`, each filled in with concrete steps,
     concrete ids, and concrete values.

5. **Show the charter to the user and stop** — unless Phase 0.0 put this run in the
   one-surface tier, where you post the job sentence and the lane names in one line and
   start. For every other tier it is one round: they know which invariant matters and which
   corner is load-bearing, and it costs one message to find out. Ask whether to add or drop
   lanes.

## Phase 1 · Pre-flight

Cheap, and it prevents a whole report of environment artefacts:

- `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/` → expect `302`.
  On `500`, read "Dev-server warts" in `ENVIRONMENT.md` and fix the environment **before**
  fanning out. A 500 from a stale SpiceDB client will otherwise be reported seven times.
- **Check every app a lane will touch, not just Studio.** Each dev server carries the
  SpiceDB wart independently — Studio can be healthy on `302` while chat 500s on the same
  cause. Restarting the one you tested is the classic way to fan out into a broken app.
- Confirm the flags the feature needs are on in `.env.local`.
- **You** are the only one who may mutate `.env.local` or restart a server. Explorers run
  concurrently; a flag flipped under a running lane invalidates its whole report. Sequence
  the flag-off lane after the others, never alongside them.
- **Or stop sequencing and isolate instead.** Sequencing the destructive lanes is what makes
  a run slow, and it penalises exactly the lanes worth most — L6 (flag off, kill Redis or
  SpiceDB) and the mutating half of L2/L4. If those lanes matter for this feature, stand up a
  second stack with `/second-instance` (own ports, own Docker) and point them at it, so they
  run **alongside** the read-only lanes rather than after them. Give each explorer the base
  URL for its own instance explicitly; an explorer that guesses `localhost:3000` will
  contend with the read-only lanes and produce fake findings. One instance is fine for a
  small change — the cost of a second stack is only worth paying when a destructive lane is
  in the charter.
- **Create the artifact root now**, before fanning out:
  `mkdir -p ~/project-workspace/Tasks/<feature>/artifacts`. Explorers write evidence
  into per-lane subdirectories under it, and a lane that has to create the root itself races
  the other six.

## Phase 2 · Fan out

One `qa-explorer` per lane, in parallel, in one message. Non-browser lanes always
parallel. Browser lanes run in parallel only when each lane has its own browser
server; one headed `chrome-devtools` profile is single-client, so lanes that need
the ZITADEL session share it and run one at a time. To parallelise authenticated
lanes, register a second headed server with its own `--user-data-dir` (see
`ENVIRONMENT.md`). **Driving lanes yourself, serially, is not the fallback — it is
the failure mode.** It burns the context you need for judgment in Phase 3 on
pixel-level navigation, which is the one thing that must not compete for room.

> **If `qa-explorer` is not in the available-agents list**, the registry was loaded before
> the file existed. Do not stop: launch `general-purpose` with `model: sonnet` and open the
> prompt with _"Read `~/.claude/agents/qa-explorer.md`
> first and follow it exactly, including the no-verdict rule and the action budget."_ Same
> behaviour, one extra read. It resolves by name in the next session.
>
> Do **not** hand that fallback a `tools:` allowlist. An allowlist strips every `mcp__` tool
> and the lane will report that the browser is unreachable — the exact bug above, reintroduced.

Each prompt contains:

- The lane id and its filled-in steps.
- The job sentence and the invariants — an explorer that knows the promise recognises a
  violation it was not told to look for.
- Concrete entry URLs and ids, so it does not spend its budget hunting. Name the **base URL
  of the instance this lane owns** if you stood up a second stack.
- `Read ~/.claude/skills/stress-test/ENVIRONMENT.md first.`
- Its action budget and whether it may restart a dev server.
- **Its artifact directory**, as an absolute path:
  `~/project-workspace/Tasks/<feature>/artifacts/<lane-id>/`. One directory per lane, so
  two explorers never write the same filename.
- The reminder that it reports observations, never a verdict, and that every observation
  needs a **probe** — the `evaluate_script` value that shows the observable — not just prose.

Lanes must be independent. If two need the same mutation, sequence them or merge them into
one lane — two agents mutating one document is a fake finding generator.

## Phase 3 · Verify before you believe

Explorer output is a lead, not a fact. For every observation:

1. **Discard environment artefacts.** Anything matching a known wart in `ENVIRONMENT.md`,
   or flagged `couldBeEnvironment`, gets checked against the logs before it survives.
2. **Read the artifact before you re-drive the browser.** Open `evidence.artifact` and check
   the probe: does the recorded value actually show the claimed behaviour? Most findings are
   confirmed or killed right here, at the cost of one file read instead of a browser session.
   Re-drive it yourself, once, only when the probe is **absent, ambiguous, or contradicts the
   prose** — and always for a P0, because a ship-blocking claim you have not seen with your
   own eyes does not go in the report. A missing probe on a P1 is itself worth one line in
   Coverage and gaps: it tells the next run which lane is under-instrumented.
3. **Explain it in the code.** Find the line that produces the behaviour. An observation
   you cannot locate in the source is either wrong or environmental — say which. This is
   also what turns "the badge is wrong" into "the list column computes `ready + chunks +
attached` and does not account for the publish gap, unlike `resolveRetrievalEffect`".
4. **Dedupe by cause, not by symptom.** Four surfaces disagreeing usually share one
   missing predicate. Report the cause once, and list the surfaces it shows on.
5. **Re-run flaky ones.** An observation that reproduces 2 of 3 times is a finding _and_
   its flakiness is part of the finding.
6. **Capture the pixels, not just the prose.** Every finding that survives verification gets
   at least one screenshot saved to `Tasks/<feature>/artifacts/shots/<nn>-<slug>.png`, taken
   with `take_screenshot`'s `filePath`. A finding about a difference — before/after, English
   vs German, live vs reloaded — gets **both** frames, because the claim IS the comparison
   and one frame cannot carry it.

   The rule this enforces: **a finding with no image is a claim, and claims do not go in the
   report as facts.** A P0 without a screenshot is downgraded to Unconfirmed until someone
   takes one. This is the same discipline as the probe in Phase 2, moved to the thing a human
   actually reviews — a reader who has to take your word for a visual defect cannot check
   your work, and this session's whole failure mode has been reasoning that looked sound and
   was not.

   Two exceptions, both stated explicitly in the report rather than left silent: a finding
   that is invisible by nature (a log line, a DB value, a network payload) is evidenced by
   the captured **text** in a `<pre>` instead — same file, `.txt`; and a finding you could
   not reach in the UI says so in one line and moves to Unconfirmed.

## Phase 4 · Report

**The deliverable is an interactive HTML page, published as an Artifact — not a markdown
file.** A stress-test report is read by someone deciding whether to ship, and that decision
turns on evidence they can inspect: the screenshot beside the claim, the two frames of a
before/after next to each other, the failing probe in full. Markdown puts that behind file
paths nobody opens, so findings get believed or dismissed on the strength of the prose,
which is exactly the failure this phase exists to prevent.

Write the page to `Tasks/<feature>/artifacts/stress-test-<date>.html` and publish it with the
`Artifact` tool. **Load the `artifact-design` skill before writing it** (required), and
`coachbot-design` for our tokens. Screenshots are embedded as `data:` URIs — the artifact CSP
blocks every external host, so a `<img src="shots/01.png">` renders as a broken image on the
published page even though it worked locally. Keep the page under 16 MB; downscale shots
rather than dropping them.

What "interactive" has to earn:

- **Every finding is collapsible**, collapsed by default past the first, so the page opens as
  a scannable verdict rather than a wall.
- **Severity filter** — P0/P1/P2/Unconfirmed toggles that actually hide rows. A reader
  triaging wants the P0s alone on screen.
- **Before/after findings use a slider or a tabbed pair**, not two stacked images a reader has
  to eyeball across. The comparison is the finding; make the UI perform it.
- **Every claim links to its evidence inline** — the screenshot, the `file:line`, the probe
  value. No "see artifacts/".

Still write `Tasks/<feature>/STRESS-TEST-<date>.md` alongside it as the plain-text record —
it is what greps, diffs, and pastes into a ticket. The HTML is the thing a human reads; the
markdown is the thing a machine reads. Same findings, same order, no divergence.

Both carry this structure:

**Verdict** — one paragraph. Ship / ship with caveats / fix first, and the single reason.
Lead with the worst confirmed thing. No score.

**Confirmed findings**, worst first. Each one:

- What a user experiences, in their words.
- **The screenshot**, inline and full-width — the first thing under the title, before any
  prose. A reader should be able to agree or disagree with the finding before reading a word
  of your explanation.
- Why it happens, with `file:line`.
- Reproduction steps that actually work.
- Severity per `LANES.md`, and what it blocks.

A finding whose screenshot does not obviously show the defect needs an annotation — a box or
arrow drawn over the `data:` URI in an `<svg>` overlay, not a sentence asking the reader to
look at the top-left. If you cannot point at it, you have not confirmed it.

**Unconfirmed and questions** — leads you could not verify, and behaviour you could not
classify as bug or intent. Do not pad this to look thorough; do not hide it to look clean.

**Coverage and gaps** — which lanes ran, what they exercised, and **what nobody looked
at**. This section is the one a reader trusts the rest of the report by. Name the lanes
that were blocked and why.

**Hardening backlog** — the point of the whole exercise. For each confirmed finding, the
deterministic check that would have caught it and where it belongs: a `*.spec.ts` next to
the logic, a repository assertion, a gate in the eval suite. Exploration finds a bug once;
a test finds it forever. Flag which are cheap and which need infrastructure that does not
exist yet (this app has no component-mounting test project — logic must be extracted to
`.ts` to be testable, see `retrieval-ranking.ts` for the pattern).

**When a confirmed P0/P1 should be guarded permanently, land ONE Playwright spec —
do not just propose it.** Exploration itself stays on chrome-devtools; the spec is
only for the finding worth guarding forever. This section has been a list of good
intentions — the repo has five `e2e/tests/**/*.spec.ts` for the entire product, which is the
measurable proof that proposing a test is not the same as having one. So for the single worst
confirmed P0/P1 that is reproducible through the UI, **write the actual spec file**, as
`Tasks/<feature>/artifacts/<name>.spec.ts`.

It goes in `Tasks/`, not the repo: this skill writes nothing into `coachbot-monorepo` and
that invariant is worth more than saving one copy command. The file is complete and
ready to land — moving it into `e2e/tests/<studio|chat>/` and running it is one of the
offers at the end of this phase, for the user to accept.

Write it against the real infrastructure, which is already there:

- `playwright.config.ts` already carries `storageState: 'auth-state-studio.json'` /
  `'auth-state-chat.json'`, so a spec is authenticated without you scripting a login.
- It already sets `trace: 'on-first-retry'` and `screenshot: 'only-on-failure'`. Run the new
  spec with `--retries=1` and the trace becomes the replayable record of the bug — the same
  artifact a screen recording would give you, except you can step through the DOM, console,
  and network in it.
- An explorer's `steps` plus its probe **are** the spec: the steps are the navigation, and
  the probe is the `expect`. That is the whole reason Phase 2 demands a probe.

Leave the spec failing and say so in the report — it is the regression proof, and it turns
green when the bug is fixed. If the worst finding is not reachable through the UI, say which
finding you wrote a spec for instead, and why.

**Playbook corrections** — fold every `playbookCorrections` entry into `ENVIRONMENT.md`
now, in the same session. Skip this and the next run rediscovers the same warts.

Then offer, without doing it: **land the spec** (`cp` it into `e2e/tests/`, run it with
`--retries=1`, confirm it fails for the right reason and attach the trace), file the P0/P1s as
Linear tickets, or implement the hardening backlog. Lead with the spec — it is the only one of
the three that stops the bug from coming back.

---

## Adapting this to a different feature

Only Phase 0 changes. Rewrite the job sentence, the invariants and the break hypotheses;
reselect lanes from `LANES.md`. Nothing else is feature-specific.

The two things that make it good rather than generic are **an invariant list taken from the
code's own claims** and **lanes that cross from Studio into chat**. A charter that skips
either produces a report about buttons.
