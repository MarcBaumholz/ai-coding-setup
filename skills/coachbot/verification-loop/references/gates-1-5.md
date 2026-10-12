# Gates 1–5 — completeness, scope, simplicity, structure, not breaking

Part of the verification loop; `SKILL.md` links here. Gate semantics are unchanged.

## Contents

- [Gate 1 · Completeness — does the branch even work for someone else?](#gate-1--completeness--does-the-branch-even-work-for-someone-else)
- [Gate 2 · Scope — is this the change that was asked for?](#gate-2--scope--is-this-the-change-that-was-asked-for)
- [Gate 3 · Simplicity — what can be deleted?](#gate-3--simplicity--what-can-be-deleted)
- [Gate 4 · Structure — is the codebase cleaner or messier than before?](#gate-4--structure--is-the-codebase-cleaner-or-messier-than-before)
- [Gate 5 · Not breaking — what else touches this?](#gate-5--not-breaking--what-else-touches-this)

## Gate 1 · Completeness — does the branch even work for someone else?

A working directory is not a branch. This gate catches the things that pass locally
and break on a fresh clone.

```bash
git status --porcelain | grep '^??'
# every untracked path: is it imported by a tracked file?
git --no-pager grep -n "$(basename <untracked> .ts)" -- '*.ts' '*.svelte'
```

Fails if: an untracked file is imported anywhere · a user-facing string exists in
`messages/en.json` but not `de.json` (or vice versa) · one `openapi.json` copy
changed without the other · a migration has no tested `down` · a new env var is
missing from a consuming app's `env.ts`.

Never claim "CI green" or "tests pass" until this gate is green. A count from
`git status --porcelain | wc -l` is not an inspection.

### 1b · Reachability — is the new code actually *reached* in production?

The failure this catches: complete, tested, documented code that **runs nowhere**. It
passes every other gate, because every other gate asks whether the code is correct and
none asks whether it executes. Two measured cases in this repo:

- `stateful-graph-agent.ts` — `RERANKER_ENABLED = false`, a fully built and tested
  reranking module doing nothing in production since 2026-08-06.
- Participant context — **nine** passing tests asserted on `getInstructions()` while the
  feature was completely inert, because the prompt is persisted once and never re-sent.
  The tests proved a string was built, never that the model saw it.

For every new capability in the diff, answer in one line each:

1. **Who calls it?** Name the production call site, file:line. Not the test, not the
   export, not the barrel file. If the only callers are specs, it is inert.
2. **Under what condition?** Quote the branch that gates it. A literal `false`, an env var
   nobody sets, an option no real caller passes, or a flag only the eval harness supplies
   is **not** enabled — it is staged.
3. **Would a revert be noticed?** If this code were replaced with a no-op, which test goes
   red? (`red-test.sh` answers this mechanically. "None" is a Gate 6 failure too.)

```bash
# hard-coded kill switches introduced by this diff
git diff <base>...HEAD -U0 | grep -nE '^\+.*(const|let) [A-Z_]{3,} *(=|:) *(false|0)\b'
# capabilities exported but never imported outside their own package/spec
git --no-pager grep -n "<newExport>" -- '*.ts' '*.svelte' | grep -v spec
```

Fails if a capability's only reachable state is off, **unless** the diff says so in one
line at the switch: who turns it on, what must be true first, and where that work is
tracked. A pause with a written owner is a note; a pause with none is a failure — that is
the whole difference between the reranker (documented, dated, escalation named) and dead
code.

## Gate 2 · Scope — is this the change that was asked for?

Three lists against `ASK` / `DONE-WHEN` / `NOT-DOING`:

- **Missing** — a `DONE-WHEN` item with no code behind it.
- **Extra** — behaviour in the diff nobody asked for. Quote the hunk. Refactors
  that rode along, a flag nobody sets, a second feature.
- **Wrong** — implemented, but not what the line actually says.

Also judge **size**: one concern per change. If the diff is >~400 net lines or
spans >2 unrelated areas, say which slice should have shipped alone. `NOT-DOING`
violations are failures, not notes.

## Gate 3 · Simplicity — what can be deleted?

`/ponytail review`'s pass, applied by you. One line per finding:
`file:L<n>: <tag> <what>. <replacement>.`

- `delete:` dead code, unused flexibility, speculative feature → nothing replaces it
- `stdlib:` hand-rolled thing the standard library ships → name the function
- `native:` dependency or code the platform already does → name the feature
- `yagni:` abstraction with one implementation, config nobody sets, layer with one caller
- `shrink:` same logic, fewer lines → show the shorter form

End with `net: -<N> lines possible.` A new dependency needs a written reason.
A fallback layered next to code that should have been deleted is a failure, not a note.
A single smoke test or `assert` self-check is the minimum, never flag it for deletion.

## Gate 4 · Structure — is the codebase cleaner or messier than before?

Be ambitious: look for the reframing that makes whole branches disappear, not local tidying.

Fails (presumptive blockers unless justified in one line):

- the diff pushes a file from under **500 lines** to over it, or grows a file
  already over 500 lines (target is 300; a file already over 500 may only shrink)
- new ad-hoc conditionals bolted into an existing unrelated flow (spaghetti growth)
- feature-specific logic leaking into a shared/general path
- a thin wrapper, pass-through helper, or identity abstraction earning nothing
- a new `any` / `unknown` / cast / optional papering over an unclear invariant
- a bespoke helper where a canonical one already exists, or logic in the wrong package/layer
- a new circular dependency between packages — never acceptable
- a second byte-identical copy of a file across apps that is not registered in `TWIN_SETS`
  (`scripts/check-twins.mjs`), so `pnpm check:twins` cannot see the two drift apart
- a changed or new function over the complexity budget: **>6** flag · **>8** justify
  or decompose · **>10** decompose or supply branch-level test evidence

File size is checked by `gates.sh` (it fails when *this* change crosses 500, and also
when a file already over 500 grows any further — "pre-existing giant: decompose, do
not grow"). Two things it cannot decide, do them yourself:

- **Complexity budget** — measure, do not eyeball: `find_large_functions_tool` from the
  code-review-graph MCP over the changed files, then apply >6 flag / >8 justify /
  >10 decompose. This is the gate people skip because it feels unmeasurable; it isn't.
- **Dependency cycles and dead exports** — `gates.sh --deep` (npx madge / knip; neither
  is a devDependency, so it downloads per run). A new cycle is never acceptable.
- **Complexity, scripted** — `gates.sh --deep` also runs ESLint's built-in `complexity`
  rule (no plugin needed, no new dependency) per touched `.ts` file as a `note`; it is
  whole-file, so treat it as a second signal, not a replacement for the MCP tool above.

Fowler smells worth naming when present: duplicated code · feature envy · data clumps ·
primitive obsession · repeated switches · shotgun surgery · divergent change · speculative generality · message chains · middle man.

## Gate 5 · Not breaking — what else touches this?

The diff cannot tell you this. Widen the lens.

```
mcp__code-review-graph__get_impact_radius_tool   (detail_level: minimal, max_depth: 1-2)
mcp__code-review-graph__get_review_context_tool
```

For every changed public signature, route, repository method, DB column, SpiceDB
relation, queue payload or event, ask:

- **Callers** — does every one still compile and still mean the same thing?
- **Legacy data** — does this break rows/threads that predate the change? New
  nullable/boolean columns default to preserving current behaviour. A new
  `maxLength` on an editor is a _migration_, not a validation: existing longer
  values must stay editable and savable.
- **Fail-open or fail-closed** — a deliberate, stated choice per check, in a
  comment. Auth on a transient DB blip: open. A known-bad state: closed.
- **Defense in depth** — an invariant that matters is enforced in app code _and_
  in SQL, not one or the other.
- **Cache** — added a cache read? Every mutation on that entity is invalidated in
  _this_ change. A corrupt entry is caught, logged, deleted, refetched — never thrown past.
- **Coexistence** — a breaking change needs a path where old and new both work,
  or it is a `FIX-FIRST`.

House conventions by touched area (the rule file auto-loads; this is the headline): actor-first repository signatures · check-then-act reads/writes, dual-write creates,
`lookupResources` pre-filtering for lists · a server-side guard behind every UI gate · `locals.logger` in routes, never `err.message` to the user, and **never** a
`logger.error` inside a `catch` that also rethrows · `SECURITY LABEL` masking on new PII columns · `@coachbot/ui` only, semantic tokens only, no raw `<input>`/`<dialog>`.

`gates.sh` decides the scriptable half of this gate: log-and-rethrow catches · `err.message` in a response body · a **new** route file with no `protectedApi`/`Load`/`Action` ·
a new repository method whose first arg is not `actorId` · a PII-shaped migration column with no `SECURITY LABEL` · hardcoded secret literals · an HMAC compared with `===` ·
a mass object drop in `schema.sql` (the regeneration trap) · `debugger` and `it.only` left behind. The rest of this gate is yours.
