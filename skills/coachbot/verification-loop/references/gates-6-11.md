# Gates 6–11 — tests, mistakes, critique, design, parallel work, pipeline

Part of the verification loop; `SKILL.md` links here. Gate semantics are unchanged.

## Contents

- [Gate 6 · Tests — does the coverage actually guard anything?](#gate-6--tests--does-the-coverage-actually-guard-anything)
- [Gate 7 · Mistake replay — am I repeating a documented mistake?](#gate-7--mistake-replay--am-i-repeating-a-documented-mistake)
- [Gate 8 · Adversarial self-critique](#gate-8--adversarial-self-critique)
- [Gate 9 · Design & a11y — only when the diff touches UI](#gate-9--design--a11y--only-when-the-diff-touches-ui)
- [Gate 9b · Browser evidence — a screenshot, or a named blocker](#gate-9b--browser-evidence--a-screenshot-or-a-named-blocker)
- [Gate 10 · Parallel work — will this collide with another worktree?](#gate-10--parallel-work--will-this-collide-with-another-worktree)
- [Gate 11 · Mechanical pipeline — did build/test/sync actually run green?](#gate-11--mechanical-pipeline--did-buildtestsync-actually-run-green)

## Gate 6 · Tests — does the coverage actually guard anything?

Volume matches **logic risk**, not file size: a branchy pure function outweighs a route.

Fails if:

- a test asserts on the wrong layer. A test on a prompt-_building_ function proves
  nothing about what the model _received_ — assert on the messages handed to
  `agent.stream()` / `agent.generate()`. Same shape everywhere: assert on the value
  that actually ships.
- a new test is not **mutation-checked**. Break the line it guards, confirm red,
  restore. A passing test that cannot fail guards nothing. `gates.sh --deep` runs
  `red-test.sh` for this on a clean tree (reverts source, expects the new tests red).
- a sanitizer, regex, parser or checker was not run over the **real corpus** —
  including non-ASCII (German NFD, Vietnamese, Arabic, CJK) where it strips or
  rewrites characters. An ASCII-only fixture for "ordinary input" cannot fail.
- behaviour was proven with a throwaway script that never became a repo test.
- a bug fix has no regression test using the exact failing input, in the same commit.
- a **new gate** — anything that refuses: a script that exits non-zero, a git or session
  hook, a permission branch, a CI job — has no test that drives its refusal path. The
  accept path alone is not evidence, because a gate replaced by `exit 0` still passes it.
  Count how many of the new tests go red when the gate is neutralised, and write that
  number down rather than the total.
- an existing test was deleted or weakened without stating why the old behaviour
  was invalid. Never to make a change pass.
- coverage on touched files went down.

```bash
pnpm --filter <touched-pkg> test
```

## Gate 7 · Mistake replay — am I repeating a documented mistake?

The gate nothing else runs. Read the **Prevention rules index** at the top of
`~/project-workspace/.claude/MISTAKES.md` and check every rule whose area the
diff touches. It grows over time — the index is the source of truth, not this list.

The mechanical subset runs as one script — **run it first, every round**, because it
decides in ~8s what would otherwise cost a careful read of the whole diff:

```bash
~/project-workspace/.claude/skills/verification-loop/gates.sh
# optional: gates.sh <base-ref>   · exit 0 = no FAIL, 1 = at least one FAIL
```

It covers the decidable parts of Gates 1, 4, 5 and 6: untracked-but-imported files ·
i18n en/de symmetry per app · the `openapi.json` pair · migration `down` sections ·
log-and-rethrow catches · `err.message` in a response · new `any`/`unknown`/`never`/
`ts-ignore` · files pushed past 500 lines (or already-over-500 files that grew) ·
changed source without a sibling spec.

`FAIL` is mechanically certain. `note` needs your eyes and may be legitimate — the
distinction is deliberate: a check that cries wolf gets ignored, which is worse than
not having it.

**Do not "improve" it without re-running it over the real tree.** Four
false-positive classes were found and killed by doing exactly that, and each is
commented at its check: prose matching code patterns (`"was never given"` matches
`as never`; a comment `"the database: any later …"` matches `: any`), `logger.warn({
error: err.message })` counted as a client leak, already-over-500-line files counted
as newly crossed, and route specs living at `page.server.spec.ts` **without** the `+`.

Judgment rules from the same index that no grep catches:

- Never propose a fix without opening the file — quote the throwing line, or say the cause is unknown.
- Never call an existing check "already works / free / just wire it in" before executing it.
- In-repo docs state intent; **source states fact**. Verify any enumerable list against source.
- Shell scripts must run on **bash 3.2** — no `mapfile`, no `${var^^}`, no associative arrays. `bash -n` then execute.
- Commands handed to the user carry **no trailing `#` comments** — this zsh passes them as arguments.
- Never chain a preparatory step with `&&` onto a `git commit`/`push` a hook may block.
- "Is X running?" is `lsof -nP -iTCP -sTCP:LISTEN` plus the configured port, then curl it. LISTEN is not healthy.
- Merge is proven by content (`git diff --stat origin/<target> HEAD -- <paths>` empty + remote `[gone]`), never by `--is-ancestor` — MRs squash here.

If the diff repeats a rule in that index, that is a **failure**, and after fixing it
say which rule it was. If the loop uncovers a _new_ class of mistake, append an entry
to `MISTAKES.md` immediately — what happened, why (the wrong belief), one checkable
prevention rule — and add it to the index.

## Gate 8 · Adversarial self-critique

A separate pass, in writing, before the verdict. Fix what is valid; carry the rest
into the report's risk section.

1. How could this be wrong even though every test passes?
2. Which assumption is most likely false in production?
3. What behaviour changed that nobody asked to change?
4. What became coupled — which future change is now harder?
5. What data, authorization, concurrency or migration risk remains?
6. What would Felix push back on? (fail-open/closed, cache invalidation, migration
   symmetry, dangerous naming, scope discipline)
7. If a reviewer called this over-engineered, what would they point at — and are they right?

## Gate 9 · Design & a11y — only when the diff touches UI

`gates.sh` runs the three existing scripts for you and summarises them:

- **`design-audit.sh`** over the changed `.svelte` files — raw palette colors instead of
  tokens, `dark:` color overrides, `w-N h-N` instead of `size-N`, `space-y-*`, emoji in
  markup, icon-only controls with no accessible name. Advisory: every category has
  documented legitimate exceptions, so read before "fixing".
- **`a11y-gate.sh`** when `packages/coachbot-ui` is touched — the real axe-core suite,
  baseline-guarded, so it fails only on a **new** violation. ~12s.
- **`tokens-sync.sh`** — token drift.

Not checkable by any script, so judge them yourself (they are the four-states rule from
`/coachbot-design`): loaded · loading · empty · error present on every async surface ·
client gate mirrored server-side · contrast in **both** themes · one primary action per
view · copy in sentence case with verbs on buttons.

## Gate 9b · Browser evidence — a screenshot, or a named blocker

Any `.svelte` or route file in the diff makes this gate applicable, and it fails unless a
`.png`, `.jpg` or `.webp` under `~/project-workspace/Tasks/shots/<branch-with-dashes>/`
is newer than the branch point. The gate looks for a file; it never asks whether you
verified anything, because that question has only ever had one answer.

Genuinely blocked — no login, no service, headless cannot reach the route:

```sh
mkdir -p ~/project-workspace/Tasks/shots/<branch> && touch .../BLOCKED-<why>
```

That is a `note`, not a FAIL, and it lands in the ledger as `blocked` so the skipped
verification stays visible instead of disappearing into a `none` on the hand-off line.

Measured 2026-09-17: 11 of 49 push sessions touched a browser at all. The screenshot is
the Behaviour line of the evidence packet — take it with `chrome-devtools`, save it there.

Not handled: a screenshot of the right page taken before the last fix. The mtime proves
when, not what.

## Gate 10 · Parallel work — will this collide with another worktree?

`gates.sh` runs `wt-files.sh` per touched workspace. Only the state **dirty** blocks —
another checkout has uncommitted work in the same files, which lives in no commit, no
branch and no MR, so it surfaces at merge time and not before. `ahead` and `mr!<iid>`
are ordinary rebases and are fine to edit over.

On a `dirty` hit: name the owning worktree and offer the fork — pick different files ·
ask that session to commit, which turns it into a normal rebase · or confirm a
deliberate parallel edit. Never `git checkout --`, `git reset`, or a bare `git stash`.

## Gate 11 · Mechanical pipeline — did build/test/sync actually run green?

The last gate, once before the verdict, not every round. Folded in from
`/quality-gates` (now archived) — points at `/ci` for commands, doesn't copy them,
and covers the two sync checks `gates.sh` cannot decide on its own.

- **typecheck/lint/format/test** — invoke `/ci`. Targeted tests on touched
  workspaces only is already `gates.sh --tests` (Gate 6b) — prefer it mid-loop,
  run `/ci`'s full sweep once before the verdict.
- **Feature flag** — new flag exists in staging + prod PostHog, default OFF.
- **Dockerfile / CI yaml** — `docker build` the changed stage or `glab ci lint`, run.

Fails if `/ci` is red, or a touched flag/Dockerfile/CI-yaml was unverified.
