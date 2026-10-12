# CoachBot security checklist

The repo-specific checks the `/full-review` security lens applies to a diff, next to the
generic method of the `security-audit` skill (Cloudflare, guidance mode). That skill decides
what counts as a finding: a crossed trust boundary with a concrete affected principal and
result, not a checklist deviation. This file names the CoachBot invariants to check against.

Was the body of the CoachBot `security-audit` skill until 2026-10-09; archived copy in
`~/project-workspace/.claude/archive/2026-10-09/skills/security-audit/`.
Complements the in-repo `rebac-security-review` agent, which goes deeper on authorization.

## Checklist (work top-down; cite file:line for every finding)

### 1. Authorization (SpiceDB ReBAC)

- Every repo method actor-first with `checkPermission` as the first statement;
  `dangerous*` methods only called from workers/system paths.
- Creates dual-write (`createResource` inside the txn, before COMMIT); deletes use
  `markDeleted`/`deleteResource` consistently.
- Lists pre-filter via `lookupResources` — never fetch-then-filter.
- Cross-project isolation: thread-by-agent queries join through `agents.project_id`.
- Bind every client-supplied org/project/coach id to the authorized resource chain before
  flag targeting, credential resolution or model calls. A checked thread does not validate
  an unrelated orgId passed to an actorless BYOK secret lookup.
- Client `usePermissions().can()` gates paired with server `guard.check` — grep for
  `.can(` in the touched routes and verify each has a server twin.
- Schema changes: `zed validate` assertions (`schema.assertions.yaml`) updated;
  the `deleter` wildcard subtraction pattern preserved on new definitions.

### 2. HTTP surface

- Inspect headers in each app's `hooks.server.ts` and CSP in `svelte.config.js` at
  the reviewed ref. Distinguish `reportOnly` from enforced directives; missing enforcement
  alone is a note unless a reachable injection crosses a boundary.
- Rate limiting (`packages/database/src/ratelimit.ts`, Upstash sliding window):
  new public/API endpoints need a limiter tier (service-account 100/min,
  shadow-user 50/min, project 1000/min are the precedents).
- Error responses: no `err.message` to clients; SvelteKit `error(500, generic)` +
  `logger.error(detail)`. Public API uses `ApiErrors.*`.

### 3. Input & data

- All request bodies/params Zod-validated (`safeParse` + 400); branded ID schemas
  for every ID param.
- **SQL injection**: no string-interpolated/concatenated SQL — parameterized
  queries only; any dynamic identifier (table/column/`ORDER BY`) allow-listed
  against a fixed set, never taken raw from user input.
- New PII / user-content / prompt columns carry
  `SECURITY LABEL FOR anon ... MASKED WITH VALUE ...` (up) + `NULL` (down) —
  inspect the migration, masking views and role grants. A mask view does not protect
  `public.table` if the analytics role can still SELECT the base table.
- Trace private text through logger `err`, nested causes, SDK `recordException` and span
  status messages. `recordInputs=false` / `recordOutputs=false` alone do not redact errors.
  Consent withdrawal must preserve protection for private text already in conversation history.
- File uploads: size/type limits, and served through the local-dev proxy pattern.

### 4. Auth & secrets

- Hook order intact: `apiAuthHandle → authHandle → authenticatedUserHook`.
- No secrets in committed files: `git diff` scan for tokens/keys; remember
  `infra_tf/tf` (gitignored) holds a live GitLab token — never let it into a commit.
  This is now also enforced mechanically by the **pre-push secret scan**
  (`.git/hooks/pre-push`) — the manual scan is the
  defense-in-depth pass, not the only line.
- Crypto: no hand-rolled crypto and no weak/legacy primitives (MD5/SHA-1 for
  security, ECB mode, `Math.random()` for tokens/IDs). Use the platform —
  `node:crypto`, `crypto.randomUUID()` — and vetted libraries only.
- Feature flags never gate _authorization_ (they gate features; `guard.check` gates
  access).
- Compare every flag reader's distinctId, groups, overrides and unknown/off policy.
  Removal/revocation retries must work with the feature off. Queued private-data work
  rechecks consent before provider calls and before writes; a read-side filter is insufficient.

### 5. AI surface

- New AI output paths run moderation (`packages/moderation`, threshold 0.82).
- Prompt/knowledge content columns masked (see §3).
- Retrieved/user text cannot select another tenant's resource or grant a tool permission.
  Trace each tool to a server permission check; model instructions and tool-list hiding
  alone are not enforcement. A provider failure containing private text stays private.

## How the lens uses this

1. Scope is the diff. Check each changed file against the sections above that its path
   touches; the `security-audit` skill's guidance mode supplies the bar for what counts.
2. Authorization depth belongs to `rebac-security-review`, which `route.sh` runs alongside
   this lens on server, repository or permission paths. Do not spawn it from here.
3. Report only findings with a concrete failure (`input → wrong result`), ranked by
   severity, each with `file:line`. A missing hardening layer behind a control that already
   holds is a note, not a finding.
