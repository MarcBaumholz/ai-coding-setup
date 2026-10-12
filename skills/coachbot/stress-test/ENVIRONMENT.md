# CoachBot local environment — navigation playbook

Everything an explorer needs to reach a feature fast, and the warts that otherwise
cost a round of debugging each. **Keep this current** — every stale line here is a
false finding in some future report. Explorers report corrections under
`playbookCorrections`; the orchestrator folds them back in.

Last verified: **2026-08-04**, worktree `knowledge-rag-v1`.

---

## Are you even pointed at the right thing

|                     |                                                             |
| ------------------- | ----------------------------------------------------------- |
| Studio              | <http://localhost:3010>                                     |
| Chat                | <http://localhost:3021>                                     |
| queue-worker health | <http://localhost:8095>                                     |
| Postgres            | `localhost:5432`, db `coachbot`, user `user`, pw `password` |
| Logs                | `/tmp/knowledge-rag-v1-{studio,chat,worker}.log`            |

**Corrected 2026-08-04**: this table drifted — `knowledge-rag-v1`'s Studio moved to `:3010`
(the port was previously `:3000`, which now belongs to a different worktree). **Do not trust
this table over the worktree's own `.env`** — read `.env.local` then `.env` every time, for
every worktree, before navigating anywhere. `.env` loads second and wins.

Ports are per-worktree. **Read `.env.local` then `.env`** — `.env` is loaded second and
wins, which is how one worktree deliberately shares another checkout's Docker stack. If
`PGPORT` disagrees between them, `.env` is the truth.

`curl -s -o /dev/null -w "%{http_code}" http://localhost:3010/` before anything else (substitute
this worktree's actual Studio port from `.env`). `302` is healthy (redirect to login). `500`
means read "Dev-server warts" below.

## Login

**The browser is already authenticated** as `user@example.test` — but only in the **headed**
`chrome-devtools` server, and only because ZITADEL's own "remember this browser" cookie is
still valid there; it is not a CoachBot session cookie that travels with the tool. `navigate_page`
to Studio's root lands on `/organizations` directly. Do not try to type a password; if a
"Sign in" click surfaces a ZITADEL "Select Account" screen with `Marc Baumholz` already listed,
click that account button — that's expected, not a stall.

**Confirmed 2026-08-04: `chrome-devtools-fast` and `chrome-devtools-headless` do NOT have this
session.** Both run `--isolated` with no persisted cookies, so navigating Studio in either
lands on `/auth/login` with no way through (no dev-login bypass exists in this codebase —
checked). If your lane needs an authenticated route, it needs the **headed** `chrome-devtools`
server, full stop; don't burn budget retrying headless variants hoping for a login. This
matches the routing table in `~/project-workspace/.claude/CLAUDE.md`'s "Browser
verification" section — read that if unsure which of the three servers to reach for.

If you land on a login page in the **headed** server specifically, stop and report it — the
session expired and a human has to re-auth.

Seeded access is limited to the orgs that user belongs to. A 404 on a valid-looking URL
usually means _that org is not yours_, not that the route is broken. Check before
reporting.

## Finding things without clicking

Hashids are **salted per resource type**, and the salt is not always the table name.
Guessing produces ids that 404. The salts live in
`packages/database/src/repositories/id-salts.ts` — note `org: 'org'`, **not**
`'organization'`.

**Use the salt VALUE, never the TS key — and note that the wrong one fails silently.**
`id-salts.ts` maps `knowledgePiece: 'knowledge_piece'`. Calling
`resource_id_encode(id,'knowledgePiece')` produces a hashid that **round-trips perfectly in
SQL** (because you decode it with the same wrong salt) and **404s in the app** (because the
app decodes with `'knowledge_piece'`). This cost a lane real actions on 2026-08-06: the
orchestrator handed it `HAPjAlp3tsb`, which was self-consistent in psql and dead in the
browser; the real id was `LFuae0yPsg7`.

So: quote the salt string from `id-salts.ts`, and **sanity-check any id you hand to an
explorer by loading it in the browser once** before putting it in a charter. Self-consistency
in SQL proves nothing.

Encode/decode in SQL rather than in your head:

```bash
docker exec coachbot-monorepo-postgres-1 psql -U user -d coachbot -t -A -F'|' -c "
SELECT resource_id_encode(o.id,'org'), resource_id_encode(p.id,'project'), p.name
FROM projects p JOIN organizations o ON o.id = p.org_id ORDER BY p.id;"
```

`projects.org_id` — not `organization_id`. Read-only `SELECT` only.

URL shape:
`/organizations/<orgId>/projects/<projectId>/knowledge/<pieceId>`
`/organizations/<orgId>/projects/<projectId>/coaches/<coachId>/graph`

## Feature flags

Local has no PostHog key, so **every flag defaults OFF**. Turn them on in `.env.local`:

```
LOCAL_FLAG_OVERRIDES=knowledge-base=true,knowledge-rag=true,coach-observability=true
```

Overrides are ignored in production by design. **A flag-off run is a real lane, not a
broken environment** — half the interesting bugs are surfaces that forget to hide.

## Seeded QA fixtures (knowledge)

In project `4UXqIJDJ6cs` ("Modern Granite Ball"), org `93kDPNWshb7`. Created by hand, so
treat their names as _intent_, not guaranteed state:

| Document                               | Covers                                 |
| -------------------------------------- | -------------------------------------- |
| `[QA] fully active`                    | ready + chunked + attached             |
| `[QA] unreviewed and never indexed`    | needs review, no text                  |
| `[QA] indexed but attached to nothing` | chunked, no coach                      |
| `[QA] ready but never indexed`         | ready, zero chunks                     |
| `[QA] hit the 400-chunk cap`           | at `KNOWLEDGE_MAX_CHUNKS_PER_DOCUMENT` |
| `[QA] still processing`                | mid-pipeline                           |

**Known drift (2026-07-29):** `[QA] fully active` reports `Needs publish` on the Usage
tab, because its coach was published before the per-stage retrieval flags existed. That is
correct behaviour and a stale fixture — the name is aspirational. Do not report it as a
bug; do report it if it _stops_ saying that without anyone republishing.

**Second drift (2026-08-04):** `[QA] fully active` now also shows `Needs Review` /
`Pending review · 1 chunks` in the knowledge list, not the "ready + chunked" its name
promises. Also not this MR's doing as far as could be traced — accumulated churn from
repeated QA runs reusing the same seed data. Its name is aspirational on two separate axes
now; check its actual status column before relying on it for anything.

**Third drift (2026-08-06) — this table is now unreliable enough that you should query, not
read it.** Measured state in `4UXqIJDJ6cs`: `[QA] ready but never indexed` is `unreviewed`
with **1** chunk (its name claims ready with zero); **two** distinct documents now share the
name `coachbot-vs-llm-onepager` (`Dsp7j8Os5bS` with 10 attachments, `FS9Ucq1YvXr` with 0), so
matching by name silently picks the wrong one; and `qa-upload-test` / `qa-upload-test-2` are
leftovers from earlier stress runs that are not in this table at all.

Three drifts in nine days is a pattern, not bad luck — these fixtures are hand-made and every
QA run mutates them. **Always resolve fixtures by `pieceId` and confirm status/chunk counts
with SQL before relying on any of them**, and prefer creating your own documents in an empty
project over reusing these. Empty projects available at the time of writing: `7ZPS28YGho6`,
`4JH9HARj69Z` and `7kg92DiMHvJ` had no documents before 2026-08-05 (the last two now hold
stress-test uploads).

## 2026-08-06 — browser lanes CANNOT run in parallel. Run them one at a time.

The frontmatter fix below was necessary and is still correct — explorers do get the
`mcp__chrome-devtools*` tools now. But it was not sufficient, and the very next run
discovered why: **the headed server drives a single non-isolated Chrome profile, so only one
client can hold it.** Four browser lanes launched together each failed identically with

```
The browser is already running for ~/.cache/chrome-devtools-mcp/chrome-profile.
Use --isolated to run multiple browser instances.
```

and performed **zero** browser actions between them — a whole fan-out wasted. Do not read
SKILL.md's "fan out browser lanes in parallel again" as applying to more than one at a time;
that line predates this finding.

**Telling this apart from a page race:** if `list_pages` itself errors with the profile-lock
message rather than returning a list, this is a _connection-level_ failure. Retrying never
helps, and no amount of `select_page` discipline addresses it. Stop after two attempts and
report.

**Recovery (orchestrator only):** a stale Chrome can hold the lock with no MCP server
attached, which blocks even the parent session. Verify with
`ps aux | grep chrome-devtools-mcp/chrome-profile`, then:

```bash
pkill -f "chrome-devtools-mcp/chrome-profile"; sleep 4
```

**The ZITADEL login survives this** — it lives in the profile directory on disk, not in the
process. Reconnect with `list_pages` and carry on.

**So: serialise.** Run one browser lane, wait for it, run the next. Budget wall-clock
accordingly (~5–8 min per lane), and prefer merging two small browser lanes into one over
launching them together. Non-browser lanes (SQL, code reading, repository-level harnesses)
still run fine alongside a browser lane — put those in the parallel batch instead.

SKILL.md now states this rule; the parallel default applies to non-browser lanes and
to lanes on distinct servers.

## 2026-08-06 — `upload_file` only accepts paths inside the git worktree

Not the Tasks artifacts dir, not `/tmp`, not the session scratchpad. A lane that stores its
fixtures outside the worktree cannot upload them.

The working pattern, confirmed by two lanes across eight uploads:

1. copy the fixture into the worktree root,
2. `upload_file`,
3. click the final submit button,
4. delete it,
5. verify `git status --porcelain` is clean.

**Do not delete or replace the file between step 2 and step 3.** The browser reads the file
lazily at submit time, so touching it in between raises `ERR_FILE_NOT_FOUND` or
`ERR_UPLOAD_FILE_CHANGED`.

Also: the sandbox refuses to create filenames containing `<` or `>`, so a filename-injection
payload has to use other characters.

## 2026-08-06 — a fresh upload is `unreviewed`, and the Attach dialog only lists `ready`

This dead-ends the obvious path and cost two lanes real budget, so it is a navigation fact
before it is a bug (it is also filed as one — see the F3 finding in
`Tasks/knowledge-rag-v1/STRESS-TEST-2026-08-05.md`).

A newly uploaded document lands in `status = 'unreviewed'`. The coach's "Attach Knowledge"
dialog filters to `status === 'ready'`, so it reports **"No knowledge pieces available. Upload
one first."** while the knowledge list simultaneously tells you to "Attach it from a coach's
knowledge panel."

To promote it: open `/…/knowledge/<pieceId>/chat`, wait for the AI summary to generate
(PDFs are slow — poll rather than assume), then click **"Save Knowledge Piece"**. Budget 2–8
extra actions per document.

Two smaller warts from the same surface:

- **`new_page` can report a 10 s navigation timeout while the page actually loaded.** Check
  `list_pages` before concluding a navigation failed.
- **The Attach Knowledge dropdown's options are absent from the a11y snapshot** (unlabelled
  portal). `take_screenshot` to read them, then ArrowDown/ArrowUp + Enter to select. Clicking
  the trigger twice just toggles it shut.

## 2026-08-06 — running a repository-level harness without writing to the repo

`/tmp` cannot resolve `@coachbot/*` (see "Standalone scripts" below), but you do not have to
put a script in the repo to get around it. Module resolution for `-e` follows **cwd**:

```bash
cd apps/queue-worker
node --env-file=../../.env.local --env-file-if-exists=../../.env \
     --input-type=module -e "$(cat /tmp/harness.mjs)"
```

The script must initialise both clients itself — `initializeDatabase({postgres, redis})` and
`initializeClient({endpoint, presharedKey, insecure})` — or you get
"Database not initialized" / "SpiceDB client has not been initialized".

This is the cheapest way to A/B a retrieval change: call
`db.knowledgeChunks.searchByEmbedding()` twice with and without a parameter and diff the
hits. It measures the real query against the real corpus with no browser and no repo write.
**Rebuild first** (`pnpm --filter "@coachbot/database" --filter "@coachbot/agents" run build`)
— `dist` is frequently an hour stale on an actively developed branch, and a harness against a
stale `dist` measures code that is not under review.

## RESOLVED 2026-08-05 — qa-explorer could not reach chrome-devtools: the cause was its own frontmatter

**The 2026-08-04 diagnosis in this section was wrong, and it cost a full run of serial
browser driving.** It concluded MCP-server-to-worktree scoping. It was not that.

`qa-explorer.md` declared `tools: Read, Glob, Grep, Bash, ToolSearch`. Per the subagent
docs, a `tools:` list is an **allowlist**, and the docs say plainly that a subagent so
restricted _"can't edit files, write files, or use any MCP tools."_ Every `mcp__*` tool was
stripped at spawn — no amount of prompt rewording or `ToolSearch` query tuning could have
recovered it, which is exactly why four launches failed identically. The evidence that
looked like project scoping (`.mcp.json` registering only `posthog`) was real but
irrelevant: `~/.claude.json` registers all three `chrome-devtools*` servers under the
`coachbot-monorepo` project key, and subagents inherit the **main conversation's** MCP pool,
not a per-worktree file.

**Fix applied:** `qa-explorer.md` now uses `disallowedTools: Write, Edit, NotebookEdit`
instead. Per the same docs a `disallowedTools` subagent _"keeps Bash, MCP tools, and the
rest of its pool"_ — so browser lanes work again while the no-repo-writes guarantee the
agent's own instructions promise is still enforced by the harness, not just by prose.

**Therefore: fan out browser lanes in parallel again.** The orchestrator does not drive
lanes by hand. If a lane still reports no `mcp__chrome-devtools*` tools:

1. Check the frontmatter is still `disallowedTools`, not `tools`. A well-meaning edit that
   re-adds a `tools:` allowlist silently reintroduces this exact bug.
2. Confirm the parent session itself has the tools (`ToolSearch("select:mcp__chrome-devtools-fast__navigate", 1)`).
   A subagent cannot inherit what the parent never had.
3. Only then suspect anything else — and record what you actually tested here.

**Generalisable rule, worth remembering beyond this file:** a capability missing from a
subagent is a _permissions_ question before it is an _infrastructure_ question. Four
identical failures pointed at a config-level cause, and that inference was correct; the
mistake was guessing which config without reading the one document that defines the field.

**Verified 2026-07-29: the list's `Indexed` column and the Usage tab agree.** Both route
through `resolveRetrievalEffect`, and all seven fixtures in that project match across the
two surfaces. An earlier session suspected the list overstated retrievability; that was a
**false positive read off a stale page** rendered before a Studio restart. Lesson for
explorers: after any restart or rebuild, hard-navigate and re-read before trusting a
surface. A cached render is the likeliest source of a fake cross-surface finding.

A 6-chunk real document good for retrieval tests: `Goal-Setting-Agent-Description`
(`KkbAS6OGekP`) in project `1EPDe7svG6n`.

## Dev-server warts — recognise, do not chase

**Studio serves `packages/*/dist`, not `src` (2026-10-01).** A repository or package fix is
invisible in the browser until `pnpm --filter @coachbot/<pkg> build` and a Studio restart. The
symptom is a page that shows the pre-fix numbers while the integration test is green. Before
reporting a data mismatch, compare `stat dist/<file>.js` with `stat src/<file>.ts`, and fetch
`<route>/__data.json` with `cache: 'no-store'` to separate a stale server from a stale tab.

**Screenshots and `filePath` only write inside `coachbot-monorepo/` (2026-10-01).** Paths under
`Tasks/` are refused ("not within configured workspace roots"). Save under
`coachbot-monorepo/.claude/` with a lane prefix, then move with Bash.

**Theme and language live in the user menu, Settings dialog (2026-10-01).** Each select has its
own Save. Listbox options are not in the a11y tree: click the trigger, ArrowUp/ArrowDown, Enter,
then Save, and wait for the save before reloading. An immediate reload drops the change.


**Studio 500s on every route after any build.** `pnpm build` / `pnpm lint` / `pnpm check`
rewrite `packages/*/dist`; vite SSR-reloads every repository module, `hooks.server.ts`
re-runs, and SpiceDB throws _"client already initialized with different configuration"_.
Symptom: `Internal Error` on every page. Check with
`grep -c "already initialized with different" /tmp/*-studio.log`. **This is never a
finding about the feature.** Recovery, if your charter authorises it:

```bash
pkill -f "studio run dev"; sleep 1; lsof -ti :3000 | xargs -r kill; sleep 2
nohup pnpm --filter studio run dev > /tmp/<wt>-studio.log 2>&1 &
```

**The chat app has the same wart, through ZITADEL.** Seen 2026-09-23: a `turbo run check
lint` for `--filter=chat` rebuilt `packages/zitadel/dist` mid-run and every chat route
returned 500 with _"Zitadel client already initialized with different configuration"_
(`apps/chat/src/hooks.server.ts`). The orchestrator must not run package builds or turbo
gates while lanes are driving the app — run them before the fan-out or after it rejoins.
Recovery is the same restart, for the chat dev server.

**Killing one app kills its siblings** if they were started under one
`pnpm --filter a --filter b run dev` — pnpm tears down the group. Run each app as its own
process.

**Coach graph page: hydration dies — DID NOT REPRODUCE on 2026-08-06.** Two independent
lanes used this page that day: one clicked **Publish** successfully through both confirmation
dialogs and got a working published version, and both drove the preview chat to completion
over dozens of turns. So treat the paragraph below as unverified rather than current: if
Publish or the graph controls do nothing for you now, that is a **fresh observation worth
reporting**, not this known issue. Re-verify or delete this section on the next run that
touches the graph page.

**Coach graph page: hydration dies.** `replaceState()` at `graph/+page.svelte:101` rejects
before the router is initialised. Consequence: the chat pane hangs on "Loading chat…" and
**Publish, Save and the graph controls have no handlers** — clicks do nothing, silently.
Loading `…/graph#graph` skips the `replaceState` (its guard is `currentHash !== viewMode`)
but the chat pane still hangs. **Known open bug.** If your lane needs Publish, report that
you were blocked rather than concluding Publish is broken — and never fake a published
version in SQL, because `publish()` snapshots the graph, mirrors every knowledge
attachment onto the new version and writes SpiceDB tuples.

**Standalone scripts** need `node --env-file=../../.env.local --env-file-if-exists=../../.env --import=tsx`,
must live _inside_ a package (module resolution is path-based, so `/tmp` cannot resolve
`@coachbot/database`), and must be `.mts` — a bare `.ts` outside a package is treated as
CJS and rejects top-level `await`. `tsx` is a devDependency of `apps/queue-worker` only.

**`apps/studio/scripts/seed.ts` is deliberately dirty** — it carries a local Zitadel id.
Leave it. Never commit it.

**Integration tests rewrite `db/schema.sql`** with a fresh `pg_dump` nonce and nothing
else. Revert it; it is not a schema change.

## The bug classes that actually recur here

Bias your exploration toward these — they are where CoachBot breaks, repeatedly:

1. **Two surfaces, two answers to one question.** The knowledge list says a document is
   `Active` while the Usage tab says `Needs publish`, because only one of them accounts
   for the publish gap. Whenever two screens describe the same object, compare them.
2. **Draft vs published.** Flags live in the session graph; publishing snapshots it.
   Anything toggled on a draft does nothing for coachees until republish. Studio shows the
   draft, coachees run the published version.
3. **Silent clipping and silent caps.** `formatKnowledgeIndex` clips a summary to 400 or
   1200 chars depending on retrievability; documents cap at 400 chunks. Both used to
   happen with no UI trace.
4. **Fail-soft that hides an outage.** Retrieval degrades to "nothing found" on a Vertex
   or SpiceDB failure — indistinguishable from a genuine miss unless the reason is
   surfaced. Check that a broken dependency is _reported_, not swallowed.
5. **Tenancy via URL.** Swap an org/project/piece id from another tenant into the path.
   SpiceDB should refuse; SQL scoping is the second line.

**Chat phone probes (2026-09-23).** The chat `(app)` layout nests two `<main>`s, and on
the home, project and Sessions routes the scroll container is a `div.overflow-y-auto`, not
either `main`: find scrollers by computed `overflow-y`, never by tag. A `md:hidden` element
returns an all-zero `getBoundingClientRect()`, which reads as a huge overlap if you
subtract from it. Serialize Playwright probe scripts against one dev server; three in
parallel returned error-page geometry (`innerWidth≈980`).
