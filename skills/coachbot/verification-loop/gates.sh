#!/bin/bash
# Mechanical gates for /verification-loop. bash 3.2 safe (no mapfile, no assoc arrays).
# Every check is a documented rule (MISTAKES.md, .claude/rules/, quality-gates) that a
# grep or an existing script can actually decide. Judgment lives in SKILL.md, not here.
#
# Usage: gates.sh [--tests] [--coverage] [--deep] [base-ref]
#   base-ref defaults to origin/dev and is always pinned to its merge-base with HEAD.
#   The tree is the one you run it from (REPO= overrides).
#   (no flag)   static gates + existing scripts, ~40s — safe to re-run every round
#   --tests     + lint/check/test scoped to the touched workspaces (minutes)
#   --coverage  + per-changed-file coverage % for touched packages/* (implies --tests)
#   --deep      + dependency cycles, dead exports, complexity, red-test mutation check,
#               migration up→rollback→up (slow, npx + eslint + git revert/restore)
#
# FAIL = mechanically certain, fix it.  note = needs your eyes, may be legitimate.
# Exit 0 = no FAIL. Exit 1 = at least one FAIL. Exit 2 = bad invocation.
set -u
# The tree you ran it from, so a second worktree judges itself. The fallback is the
# main checkout, for a call from outside any repo. design-audit.sh reads its own
# variable name, so hand the same tree on.
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/Documents/Coachbot_dev/coachbot-monorepo")}"
export COACHBOT_REPO="${COACHBOT_REPO:-$REPO}"
DESIGN="${DESIGN:-$HOME/Documents/Coachbot_dev/.claude/skills/coachbot-design/scripts}"
WTFILES="${WTFILES:-$HOME/.claude/scripts/wt-files.sh}"
# Resolve self BEFORE the cd — otherwise --help cannot read a relative $0.
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$REPO" || exit 2

RUN_TESTS=0
RUN_COV=0
RUN_DEEP=0
BASE=""
for a in "$@"; do
	case "$a" in
	--tests) RUN_TESTS=1 ;;
	--coverage)
		RUN_COV=1
		RUN_TESTS=1
		;;
	--deep) RUN_DEEP=1 ;;
	-h | --help)
		sed -n '2,13p' "$SELF"
		exit 0
		;;
	*) BASE="$a" ;;
	esac
done
# Always the branch point, never a moving tip: a two-dot diff against an origin/dev
# that advanced counts every file dev gained as part of this change.
BASE=$(git merge-base HEAD "${BASE:-origin/dev}") || { echo "no merge-base with ${BASE:-origin/dev}"; exit 2; }
TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TMP"' EXIT

say() { printf '%s\n' "$1"; }
pass() { printf '  ok   %s\n' "$1"; }
note() { printf '  note %s\n' "$1"; }
# Marker file, not a variable: most checks run inside a pipe, and a subshell cannot
# set a parent variable. That bug once printed FAIL and still exited 0.
fail() {
	printf '  FAIL %s\n' "$1"
	: >"$TMP/failed"
}
indent() { sed 's/^/       /'; }

{
	git diff --name-only "$BASE"
	git diff --name-only
	git diff --name-only --cached
} | sort -u | while IFS= read -r f; do
	[ -f "$f" ] && printf '%s\n' "$f"
done >"$TMP/changed"

# Files added by this change (guards below only apply to NEW routes, not old ones).
git diff --name-only --diff-filter=A "$BASE" | sort -u >"$TMP/added"

# Source worth judging: no specs, generated, barrels, fixtures.
grep -E '\.(ts|svelte)$' "$TMP/changed" |
	grep -v -E '\.(spec|test|stories|d)\.ts$' |
	grep -v -E '(^|/)(index\.ts|.*\.config\.ts)$' |
	grep -v -E '/(test-utils|__fixtures__|scripts)/' >"$TMP/src"

# Added lines of the whole change, once — many checks below only look at these.
git diff "$BASE" >"$TMP/diff"
grep '^+[^+]' "$TMP/diff" >"$TMP/added_lines"

# Added lines of APP/SERVICE source only. CLI packages (eval-datasets) and scripts
# legitimately console.log and read process.env directly; counting them was pure noise.
grep -v -E '^packages/eval-datasets/' "$TMP/src" >"$TMP/appsrc"
: >"$TMP/app_added"
while IFS= read -r f; do
	git diff "$BASE" -- "$f" | grep '^+[^+]' >>"$TMP/app_added"
done <"$TMP/appsrc"

# Strip comment lines so prose stops matching code patterns.
nocomment() { grep -v -E '^\+?[[:space:]]*(\*|//|/\*|--)'; }

touched() { grep -qE "$1" "$TMP/changed"; }

say "== Gate 1 · completeness =="

UNTRACKED=$(git status --porcelain | sed -n 's/^?? //p' | grep -E '\.(ts|svelte|js)$')
if [ -z "$UNTRACKED" ]; then
	pass "no untracked source files"
else
	while IFS= read -r u; do
		[ -n "$u" ] || continue
		stem=$(basename "$u" | sed 's/\.[^.]*$//')
		hits=$(git grep -l -- "$stem" -- '*.ts' '*.svelte' 2>/dev/null | grep -v -F "$u" | head -3)
		if [ -n "$hits" ]; then
			fail "untracked $u referenced by tracked file(s): $(echo "$hits" | tr '\n' ' ')"
		else
			note "untracked $u — no tracked referent, but still needs git add"
		fi
	done <<EOF
$UNTRACKED
EOF
fi

# i18n: file symmetry is the cheap pre-check; the repo's own validator is the real one.
for app in studio chat admin home; do
	en=$(grep -c "^apps/$app/messages/en\.json$" "$TMP/changed")
	de=$(grep -c "^apps/$app/messages/de\.json$" "$TMP/changed")
	[ "$en" = "0" ] && [ "$de" = "0" ] && continue
	[ "$en" = "$de" ] || fail "i18n asymmetry in apps/$app — en changed=$en, de changed=$de"
	if node -e "process.exit(require('./apps/$app/package.json').scripts?.['i18n:validate']?0:1)" 2>/dev/null; then
		if out=$(cd "apps/$app" && timeout 300 pnpm run i18n:validate 2>&1); then
			pass "apps/$app i18n:validate (missing + unused keys)"
		else
			fail "apps/$app i18n:validate:"
			printf '%s\n' "$out" | tail -12 | indent
		fi
	fi
done

OA=$(grep -c 'openapi\.json$' "$TMP/changed")
case "$OA" in
2) pass "both openapi.json copies changed" ;;
0)
	if touched '^packages/types/src/api/|/routes/api/.*\+server\.ts$'; then
		note "public API surface changed but no openapi.json did — run /openapi if the spec moved"
	fi
	;;
*) fail "openapi.json changed in $OA place(s) — must be 0 or 2 (see /openapi)" ;;
esac

if touched 'schema\.zed$'; then
	if command -v zed >/dev/null 2>&1; then
		if out=$(zed validate packages/permissions/src/schema.assertions.yaml 2>&1); then
			pass "zed validate against schema.assertions.yaml"
		else
			fail "zed validate:"
			printf '%s\n' "$out" | tail -12 | indent
		fi
	else
		note "schema.zed changed but \`zed\` is not on PATH — validate before the MR"
	fi
fi

# New process.env reads belong in the app's env.ts, not scattered through code.
# NOTE: no `case` inside this $( … | while … ) — bash 3.2 fails to parse one there,
# single-line or not (verified on 3.2.57). The exclusions are a grep instead.
STRAY_ENV=$(nocomment <"$TMP/app_added" |
	grep -oE 'process\.env\.[A-Z][A-Z0-9_]+' | sed 's/^process\.env\.//' | sort -u |
	grep -vE '^(NODE_ENV|CI|PORT|HOME|PATH|npm_.*)$' |
	while IFS= read -r n; do
		git grep -q -- "$n" -- '*/env.ts' 'packages/*/src/env*' 2>/dev/null || printf '%s\n' "$n"
	done)
if [ -z "$STRAY_ENV" ]; then
	pass "no new env var read outside an env.ts"
else
	note "env var(s) read but not declared in any env.ts (add + Secret Manager): $(echo "$STRAY_ENV" | tr '\n' ' ')"
fi

grep '/db/migrations/' "$TMP/changed" >"$TMP/migrations"
if [ -s "$TMP/migrations" ]; then
	NODOWN=""
	while IFS= read -r m; do
		grep -q 'migrate:down' "$m" || NODOWN="$NODOWN $(basename "$m")"
	done <"$TMP/migrations"
	[ -n "$NODOWN" ] && fail "migration without a down section:$NODOWN" ||
		pass "$(wc -l <"$TMP/migrations" | tr -d ' ') migration(s) touched, all have a down section"

	# PII / user-content columns need a masking rule (analytics-user-masking.md).
	while IFS= read -r m; do
		cols=$(grep -iE '^\s*(ADD COLUMN\s+)?[a-z_]+\s+(text|varchar|citext|jsonb)' "$m" |
			grep -oiE '[a-z_]*(name|email|title|content|message|description|summary|note|phone|address|feedback|prompt|answer|reason|transcript)[a-z_]*' |
			sort -u)
		[ -z "$cols" ] && continue
		miss=""
		for c in $cols; do
			grep -qi "SECURITY LABEL.*$c" "$m" || miss="$miss $c"
		done
		[ -n "$miss" ] && fail "$(basename "$m"): PII-shaped column(s) with no SECURITY LABEL:$miss"
	done <"$TMP/migrations"
fi

# schema.sql is regenerated FROM THE LIVE DB. A cluster missing SpiceDB silently drops
# its objects — this happened before (see MISTAKES.md / the schema.sql trap memory).
if touched 'db/schema\.sql$'; then
	DROPPED=$(git diff "$BASE" -- packages/database/db/schema.sql |
		grep -cE '^-(CREATE|ALTER|COMMENT|SECURITY LABEL|GRANT)')
	ADDED=$(git diff "$BASE" -- packages/database/db/schema.sql |
		grep -cE '^\+(CREATE|ALTER|COMMENT|SECURITY LABEL|GRANT)')
	if [ "$DROPPED" -gt 3 ] && [ "$DROPPED" -gt "$ADDED" ]; then
		fail "schema.sql lost $DROPPED object definitions (added $ADDED) — regenerated against a cluster missing objects? Re-run dbmate against a full local stack."
	else
		pass "schema.sql: $ADDED object def(s) added, $DROPPED removed — no mass drop"
	fi
fi

# Reachability: code that is complete, tested and RUNS NOWHERE. Two real cases motivated
# this — RERANKER_ENABLED=false (a built, tested reranker inert in prod since 2026-08-06)
# and nine passing tests on getInstructions() while the feature never reached the model.
# Every other gate asks whether the code is correct; none asks whether it executes.
#
# `note`, never `fail`: a deliberately staged capability is legitimate and common. Only a
# human can tell "paused, owner named" from "dead". Deciding that mechanically is exactly
# the cry-wolf failure the header warns about.
#
# Comments are stripped first (nocomment) so prose about a flag does not match the flag.
SWITCHES=$(grep -v -E '^\+\+\+' "$TMP/added_lines" | nocomment |
	grep -oE '(const|let)[[:space:]]+[A-Z][A-Z0-9_]{2,}[[:space:]]*=[[:space:]]*false' |
	awk '{print $2}' | sort -u)
if [ -n "$SWITCHES" ]; then
	while IFS= read -r s; do
		[ -n "$s" ] || continue
		note "kill switch added: $s = false — name who flips it, what must be true first, and where that is tracked (Gate 1b)"
	done <<EOF
$SWITCHES
EOF
else
	pass "no hard-coded false kill switches added"
fi

# An export whose only importers are specs is staged, not shipped. Limited to newly added
# exported symbols in packages/ — apps wire themselves through routes, where "who imports
# this" is not the right question.
#
# FUNCTIONS AND CLASSES ONLY, deliberately. `const` was in this pattern for one run and
# measured as pure noise: on feab3088 it reported RRF_K, COMPRESSION_THRESHOLD,
# KNOWLEDGE_RETRIEVAL_MAX_CHARS and six more, all exported constants consumed inside their
# own file (or by a sibling package that greps as one hit). A constant is configuration;
# the thing that can be inert is behaviour.
#
# Pathspec is a plain `packages/` prefix, NOT `packages/**/src/**/*.ts`. That glob was here
# for one run and matched nothing: without `:(glob)` magic git needs a directory between
# `src/` and the file, so anything at `packages/<pkg>/src/foo.ts` was invisible. Verified by
# probe — an exported function with no caller must produce a note, and under the old
# pattern it did not. The `^+export` match is what restricts this to TypeScript.
NEWEXPORTS=$(git diff "$BASE" -- 'packages/' ':!*.spec.ts' ':!*.test.ts' 2>/dev/null |
	grep '^+[^+]' | nocomment |
	grep -oE '^\+export (async function|function|class) [a-zA-Z_][a-zA-Z0-9_]*' |
	awk '{print $NF}' | sort -u)
INERT=""
if [ -n "$NEWEXPORTS" ]; then
	while IFS= read -r sym; do
		[ -n "$sym" ] || continue
		# Definition sites and spec files do not count as production callers.
		users=$(git grep -l -- "$sym" -- 'packages/**/*.ts' 'apps/**/*.ts' 'apps/**/*.svelte' 2>/dev/null |
			grep -v -E '\.(spec|test)\.ts$' | wc -l | tr -d ' ')
		[ "$users" -le 1 ] && INERT="$INERT $sym"
	done <<EOF
$NEWEXPORTS
EOF
fi
if [ -n "$INERT" ]; then
	note "new export(s) with no non-spec caller outside their own file:$INERT — inert until wired (Gate 1b)"
else
	pass "new package exports have a non-spec caller"
fi

say "== Gate 2b · leftovers =="

LEFT=$(grep -v -E '^\+\+\+' "$TMP/added_lines" | nocomment |
	grep -nE '(\bdebugger\b|\b(it|test|describe)\.only\(|\bfdescribe\b|\bfit\()')
if [ -z "$LEFT" ]; then
	pass "no debugger / .only left in the diff"
else
	fail ".only or debugger left behind — CI stays green while the suite stops running:"
	printf '%s\n' "$LEFT" | head -8 | indent
fi

CLOG=$(nocomment <"$TMP/app_added" | grep -cE 'console\.(log|debug)\(')
[ "$CLOG" -gt 0 ] && note "$CLOG new console.log/debug in app source (CLI/scripts excluded)"

TODO=$(grep -E '(TODO|FIXME|HACK)' "$TMP/app_added" |
	grep -v -E '(EPD-|#[0-9]+|ponytail:)' | head -5)
[ -n "$TODO" ] && note "TODO/FIXME with no ticket ref: $(printf '%s' "$TODO" | wc -l | tr -d ' ') hit(s)"

PONY=$(grep -c 'ponytail:' "$TMP/added_lines")
[ "$PONY" -gt 0 ] && note "$PONY new ponytail: marker(s) — they belong in the /ponytail debt ledger"

say "== Gate 5 · not breaking =="

# Log-and-rethrow in one catch (logging-standards.md). note, not FAIL: the log and the
# throw can sit on different branches of the same catch — a guard rethrow is legitimate.
DL=$(while IFS= read -r f; do
	perl -0777 -ne 'while (/catch\s*\(([^)]*)\)\s*\{/g) {
			my $s = pos($_); my $d = 1; my $i = $s; my $len = length($_);
			while ($i < $len && $d > 0) {
				my $c = substr($_, $i, 1);
				$d++ if $c eq "{"; $d-- if $c eq "}"; $i++;
			}
			my $body = substr($_, $s, $i - $s);
			next unless $body =~ /logger[^;]*\.error\(/s;
			next unless $body =~ /(^|[^.\w])throw\s/s;
			printf "%s:%d\n", $ARGV, 1 + (substr($_, 0, $s) =~ tr/\n//);
		}' "$f"
done <"$TMP/src")
[ -z "$DL" ] && pass "no catch block logs .error and throws" || {
	note "catch logs .error AND throws — same branch = defect, guard rethrow = fine:"
	printf '%s\n' "$DL" | indent
}

# err.message in a CLIENT RESPONSE — not a log line, not a condition.
LEAK=$(grep -E '\+server\.ts$|\+page\.server\.ts$' "$TMP/changed" | while IFS= read -r f; do
	perl -ne '
		push @w, $_; shift @w if @w > 6;
		next unless /(err|error)\.message/;
		next if /^\s*(\*|\/\/)/;
		next if /(if|while)\s*\(|\.includes\(|\.match\(|===|!==|\.startsWith\(/;
		my $ctx = join "", @w;
		next if $ctx =~ /(logger|log)\s*\.\s*(error|warn|info|debug)\s*\(/s;
		next unless $ctx =~ /(\berror\s*\(|\bjson\s*\(|new Response\s*\(|\bfail\s*\(|body\s*:)/s;
		printf "%s:%d:%s", $ARGV, $., $_;
	' "$f"
done)
[ -z "$LEAK" ] && pass "no err.message in a server response body" || {
	fail "err.message reaches the client (error-handling.md):"
	printf '%s\n' "$LEAK" | indent
}

HATCH=$(while IFS= read -r f; do
	git diff "$BASE" -- "$f" | grep -E '^\+' | nocomment |
		grep -nE '(:[[:space:]]*any\b|as any\b|as unknown\b|as never[;,)]|@ts-(ignore|expect-error))' |
		sed "s|^|$f:|"
done <"$TMP/src")
[ -z "$HATCH" ] && pass "no new any/unknown/never-cast/ts-ignore in non-test source" || {
	note "$(printf '%s\n' "$HATCH" | wc -l | tr -d ' ') type escape hatch(es) added — justify each:"
	printf '%s\n' "$HATCH" | head -8 | indent
}

say "== Gate 5b · authorization & secrets =="

# A NEW route file with no guard. Only new files: existing public routes are not this
# change's business.
UNGUARDED=$(grep -E '/routes/.*(\+server|\+page\.server)\.ts$' "$TMP/added" | while IFS= read -r f; do
	[ -f "$f" ] || continue
	grep -qE 'protected(Api|Load|Action)' "$f" || printf '%s\n' "$f"
done)
if [ -z "$UNGUARDED" ]; then
	pass "every new route file uses protectedApi/Load/Action"
else
	fail "new route with no server-side guard (auth-patterns.md):"
	printf '%s\n' "$UNGUARDED" | indent
fi

# Actor-first repository signatures. Read the FILE, not the diff: signatures span
# several lines, so a diff-line grep matched SQL continuations (COALESCE(, MIN(, COUNT(*)).
# Lowercase-initial only, and the following 120 chars must contain the actor param.
ACTORLESS=$(grep '\.repository\.ts$' "$TMP/changed" | while IFS= read -r f; do
	# Method names this diff introduced (definition line added).
	git diff "$BASE" -- "$f" | grep -E '^\+[[:space:]]*(public |private )?(async )?[a-z][A-Za-z0-9_]*[[:space:]]*\(' |
		grep -oE '[a-z][A-Za-z0-9_]*[[:space:]]*\($' | sed 's/[[:space:]]*($//' | sort -u >"$TMP/newnames"
	[ -s "$TMP/newnames" ] || continue
	# Judge each against its real (possibly multi-line) signature in the file.
	perl -0777 -ne 'while (/(?:^|\n)\s*(?:public\s+|private\s+)?(?:async\s+)?([a-z][A-Za-z0-9_]*)\s*\(/g) {
			my $name = $1; my $p = pos($_);
			next if $name =~ /^(if|for|while|switch|catch|return|await|function|constructor|map|filter|then)$/;
			next if substr($_, $p, 120) =~ /\b(actorId|actor)\b/;
			printf "%s\t%s\n", $name, $ARGV;
		}' "$f" | grep -F -f "$TMP/newnames" |
		awk -F'\t' '$1 !~ /_/ {
			tag = ($1 ~ /^dangerous/) ? "  (dangerous-prefixed: deliberate exception, verify)" : "";
			printf "%s: %s()%s\n", $2, $1, tag }'
done | sort -u)
[ -z "$ACTORLESS" ] && pass "no new repository method without an actor-first param" || {
	note "repository method(s) whose first arg is not actorId (architecture-patterns.md):"
	printf '%s\n' "$ACTORLESS" | head -6 | indent
}

SECRETS=$(grep -v -E '^\+\+\+' "$TMP/added_lines" | nocomment |
	grep -nEi "(api[_-]?key|secret|token|password|passphrase)[\"']?[[:space:]]*[:=][[:space:]]*[\"'][A-Za-z0-9_/+-]{16,}[\"']" |
	grep -v -E '(process\.env|placeholder|example|xxx|redacted|test-|fake)')
[ -z "$SECRETS" ] && pass "no hardcoded secret-shaped literal" || {
	fail "hardcoded secret-shaped literal:"
	printf '%s\n' "$SECRETS" | head -5 | indent
}

# Deliberately NOT matching `hash` or `digest`: `currentHash !== tab` is ordinary
# router code and fired as a false positive. Only true signature comparisons here.
TIMING=$(grep -v -E '^\+\+\+' "$TMP/added_lines" | nocomment |
	grep -nEi '(hmac|signature|createHmac|webhookSig)[a-z]*[[:space:]]*(===|!==)')
[ -n "$TIMING" ] && {
	fail "signature/HMAC compared with === — use timingSafeEqual (Felix's rule):"
	printf '%s\n' "$TIMING" | indent
}

say "== Gate 4 · structure =="

CROSSED=""
GREW=""
ALREADY=0
while IFS= read -r f; do
	now=$(wc -l <"$f" | tr -d ' ')
	[ "$now" -gt 500 ] || continue
	was=$(git show "$BASE:$f" 2>/dev/null | wc -l | tr -d ' ')
	[ -z "$was" ] && was=0
	if [ "$was" -le 500 ]; then
		CROSSED="$CROSSED       $f: $was → $now
"
	elif [ "$now" -gt "$was" ]; then
		GREW="$GREW       $f: $was → $now
"
	else
		ALREADY=$((ALREADY + 1))
	fi
done <"$TMP/src"
if [ -n "$CROSSED" ]; then
	fail "file pushed past 500 lines — decompose or justify:"
	printf '%s' "$CROSSED"
else
	pass "no file pushed past 500 lines by this change"
fi
if [ -n "$GREW" ]; then
	fail "pre-existing giant grew: decompose, do not grow:"
	printf '%s' "$GREW"
fi
[ "$ALREADY" -gt 0 ] && note "$ALREADY changed file(s) were already over 500 lines and did not grow — pre-existing"

say "== Gate 6 · tests =="

NOSPEC=""
N=0
while IFS= read -r f; do
	case "$f" in *.ts) ;; *) continue ;; esac
	# Route specs drop the `+`: page.server.spec.ts, not +page.server.spec.ts.
	b="${f%.ts}"
	nb="$(dirname "$f")/$(basename "$b" | sed 's/^+//')"
	[ -f "$b.spec.ts" ] && continue
	[ -f "$b.test.ts" ] && continue
	[ -f "$nb.spec.ts" ] && continue
	[ -f "$nb.test.ts" ] && continue
	added=$(git diff "$BASE" -- "$f" | grep -c '^+[^+]')
	[ "$added" -lt 20 ] && continue
	NOSPEC="$NOSPEC       $f (+$added lines)
"
	N=$((N + 1))
done <"$TMP/src"
if [ "$N" = "0" ]; then
	pass "every changed source .ts has a sibling spec"
else
	note "$N changed .ts without a sibling spec — thin glue is fine, logic is a finding:"
	printf '%s' "$NOSPEC" | head -10
	[ "$N" -gt 10 ] && printf '       … and %d more\n' $((N - 10))
fi

say "== Gate 9 · design & a11y =="

SVELTE=$(grep '\.svelte$' "$TMP/changed")
if [ -z "$SVELTE" ]; then
	pass "no .svelte touched — design gates not applicable"
else
	if [ -x "$DESIGN/design-audit.sh" ]; then
		# shellcheck disable=SC2086
		if out=$(printf '%s\n' "$SVELTE" | tr '\n' ' ' | xargs "$DESIGN/design-audit.sh" 2>&1); then
			pass "design-audit.sh clean over $(printf '%s\n' "$SVELTE" | wc -l | tr -d ' ') .svelte file(s)"
		else
			# Category headers + counts, not 20 raw lines. `design-audit.sh <paths>`
			# prints the full list when you want it. Its repo-wide i18n parity section
			# is dropped: Gate 1 already runs the repo's own validator.
			note "design-audit.sh findings (advisory — each has documented exceptions):"
			printf '%s\n' "$out" | sed '/^─\{5,\}/,$d' |
				perl -ne 's/\e\[[0-9;]*m//g;
					if (/^\s*▲\s*(.+?)\s*$/) { $h = $1; next if $h =~ /i18n key parity/; $c{$h} //= 0; $cur = $h; next }
					$c{$cur}++ if defined $cur && /:\d+:/;
					END { printf "  %-42s %d\n", $_, $c{$_} for sort keys %c }' | indent
			note "full list: $DESIGN/design-audit.sh <changed .svelte paths>"
		fi
	else
		note "design-audit.sh not found at $DESIGN"
	fi
	if touched '^packages/coachbot-ui/'; then
		if [ -x "$DESIGN/a11y-gate.sh" ]; then
			if out=$(timeout 600 "$DESIGN/a11y-gate.sh" 2>&1); then
				pass "a11y-gate.sh — no NEW axe violations vs baseline"
			else
				fail "a11y-gate.sh — new accessibility violation(s):"
				printf '%s\n' "$out" | tail -15 | indent
			fi
		else
			note "a11y-gate.sh not found at $DESIGN"
		fi
		[ -x "$DESIGN/tokens-sync.sh" ] && {
			if out=$("$DESIGN/tokens-sync.sh" 2>&1); then pass "tokens-sync.sh clean"; else
				note "tokens-sync.sh drift:"
				printf '%s\n' "$out" | tail -10 | indent
			fi
		}
	else
		note "@coachbot/ui untouched — skipping a11y-gate (12s) and tokens-sync"
	fi
fi

say "== Gate 9b · browser evidence =="

# A .svelte or route change is a claim about what a person sees. This gate cannot look at
# a screenshot, but it can look FOR one: a file under SHOTS newer than the branch point.
# That is the whole mechanism — a file on disk, not a line the model writes about itself.
# Measured 2026-09-17: 11 of 49 push sessions touched a browser at all, and the Behaviour
# line of the hand-off may say `none`, so a field one word satisfies got satisfied in one
# word. Not handled: a stale screenshot of the right page taken before the last fix — the
# mtime proves when, not what.
BROWSER="n/a"
UI=$(grep -E '\.svelte$|/\+(page|layout|server)(\.server)?\.ts$' "$TMP/changed")
if [ -z "$UI" ]; then
	pass "no .svelte and no route touched — browser evidence not applicable"
else
	SHOTS="$HOME/Documents/Coachbot_dev/Tasks/shots/$(git branch --show-current | tr '/' '-')"
	# `%ci`, not `%cI`: BSD find rejects the ISO `T`/`+00:00` form, and the error was
	# silenced, so this gate failed every run on macOS whatever was in SHOTS.
	SINCE=$(git log -1 --format=%ci "$BASE" 2>/dev/null)
	FRESH=""
	BLOCKED=""
	if [ -d "$SHOTS" ] && [ -n "$SINCE" ]; then
		FRESH=$(find "$SHOTS" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.webp' \) -newermt "$SINCE")
		BLOCKED=$(find "$SHOTS" -type f -name 'BLOCKED-*' -newermt "$SINCE")
	fi
	if [ -n "$FRESH" ]; then
		BROWSER="yes"
		pass "$(printf '%s\n' "$FRESH" | wc -l | tr -d ' ') screenshot(s) newer than the branch point in $SHOTS"
	elif [ -n "$BLOCKED" ]; then
		# A named blocker is an answer; silence is not. It still shows up in the ledger.
		BROWSER="blocked"
		note "browser verification blocked: $(basename "$(printf '%s\n' "$BLOCKED" | head -1)")"
	else
		BROWSER="no"
		fail "$(printf '%s\n' "$UI" | wc -l | tr -d ' ') user-facing file(s) changed and no screenshot proves it:"
		printf '%s\n' "$UI" | head -8 | indent
		printf 'put them here, then re-run:  %s\n' "$SHOTS" | indent
		printf 'genuinely blocked? %s\n' "mkdir -p '$SHOTS' && touch '$SHOTS/BLOCKED-<why>'" | indent
	fi
fi

say "== Gate 10 · parallel work =="

if [ -x "$WTFILES" ]; then
	WS=$(sed -n -E 's#^(apps|packages)/([^/]+)/.*#\1/\2#p' "$TMP/changed" | sort -u)
	HIT=0
	while IFS= read -r d; do
		[ -n "$d" ] || continue
		out=$("$WTFILES" "$d" 2>&1)
		dirty=$(printf '%s\n' "$out" | grep -w 'dirty' | grep -vE '\.smoke-out/|\.png$' | head -5)
		aheadn=$(printf '%s\n' "$out" | grep -cw 'ahead')
		if [ -n "$dirty" ]; then
			HIT=1
			note "$d — another worktree has UNCOMMITTED work here (this one blocks):"
			printf '%s\n' "$dirty" | indent
		elif [ "$aheadn" -gt 0 ]; then
			HIT=1
			note "$d — $aheadn file(s) ahead on another branch/MR: an ordinary rebase, not a block"
		fi
	done <<EOF
$WS
EOF
	[ "$HIT" = "0" ] && pass "no other worktree/MR is dirty on these paths"
else
	note "wt-files.sh not found at $WTFILES"
fi

if [ "$RUN_TESTS" = "1" ]; then
	# Delimiter must NOT be `|` — it would end the pattern inside (apps|packages).
	sed -n -E 's#^(apps|packages)/([^/]+)/.*#\1/\2#p' "$TMP/changed" | sort -u |
		while IFS= read -r d; do [ -f "$d/package.json" ] && printf '%s\n' "$d"; done >"$TMP/ws"

	say "== Gate 6b · lint · check · test ($(wc -l <"$TMP/ws" | tr -d ' ') workspace(s)) =="
	while IFS= read -r d; do
		[ -n "$d" ] || continue
		for s in lint check test; do
			node -e "process.exit(require('./$d/package.json').scripts?.['$s']?0:1)" 2>/dev/null || continue
			# Always the package's own `test`, never `test:unit` — in agents, chat and
			# studio that one is bare `vitest`, i.e. watch mode: it hangs forever.
			if out=$(cd "$d" && timeout 1200 pnpm run "$s" 2>&1); then
				pass "$d · $s"
			else
				fail "$d · $s — last lines:"
				printf '%s\n' "$out" | tail -12 | indent
			fi
		done
	done <"$TMP/ws"
fi

if [ "$RUN_COV" = "1" ]; then
	say "== Gate 6c · coverage of the files this change touched =="
	# packages/* only: apps run Svelte/storybook vitest projects that may want a browser.
	# No baseline delta — that needs a stash-and-rerun, slow and flaky. This answers the
	# useful question instead: is what I just changed covered at all?
	# `pnpm run test -- --coverage` does NOT work: the `--` is swallowed and coverage
	# silently never runs. `pnpm exec vitest run --coverage` is the form that works.
	grep '^packages/' "$TMP/ws" | while IFS= read -r d; do
		[ -n "$d" ] || continue
		grep -q "coverage" "$d/vitest.config.ts" 2>/dev/null || {
			note "$d · no coverage config"
			continue
		}
		(cd "$d" && timeout 1200 pnpm exec vitest run --coverage --coverage.reporter=json-summary >/dev/null 2>&1)
		sum="$d/coverage/coverage-summary.json"
		[ -f "$sum" ] || {
			note "$d · coverage run produced no summary"
			continue
		}
		grep "^$d/" "$TMP/src" | while IFS= read -r f; do
			pct=$(node -e "
				const s=require('$REPO/$sum');
				const e=Object.entries(s).find(([p])=>p==='$REPO/$f');
				console.log(e?e[1].statements.pct:'n/a');
			" 2>/dev/null)
			case "$pct" in
			n/a) note "$f — not in the coverage report (no test imports it)" ;;
			0) fail "$f — 0% statement coverage" ;;
			*) awk -v p="$pct" -v f="$f" 'BEGIN{
					if (p+0 < 50) printf "  note %s — %s%% statements (thin)\n", f, p;
					else printf "  ok   %s — %s%% statements\n", f, p }' ;;
			esac
		done
	done
	note "coverage is measured, never gated — CI reports it (.gitlab/ci/quality.yml), no threshold"
fi

if [ "$RUN_DEEP" = "1" ]; then
	say "== Gate 4b · cycles & dead exports (npx, not installed locally) =="
	DIRS=$(sed -n -E 's#^(apps|packages)/([^/]+)/.*#\1/\2#p' "$TMP/changed" | sort -u | tr '\n' ' ')
	if [ -n "$DIRS" ]; then
		if out=$(timeout 900 npx --yes madge --circular --extensions ts,svelte $DIRS 2>&1); then
			pass "madge: no circular dependency in $DIRS"
		else
			fail "circular dependency (never acceptable):"
			printf '%s\n' "$out" | tail -15 | indent
		fi
		if out=$(timeout 900 npx --yes knip --no-exit-code 2>&1); then
			note "knip (dead exports / unused deps) — read, do not auto-delete:"
			printf '%s\n' "$out" | tail -20 | indent
		else
			note "knip did not run cleanly (needs a knip.json for a monorepo this size)"
		fi
	fi

	if [ -s "$TMP/migrations" ]; then
		say "== Gate 1b · migration round-trip (real) =="
		if docker compose ps 2>/dev/null | grep -q healthy; then
			if out=$(cd packages/database && timeout 900 sh -c 'pnpm migrate:up && pnpm migrate:rollback && pnpm migrate:up' 2>&1); then
				pass "migrate up→rollback→up"
			else
				fail "migration round-trip failed:"
				printf '%s\n' "$out" | tail -15 | indent
			fi
		else
			note "docker services not healthy — round-trip skipped, NOT proven"
		fi
	fi

	# Complexity: ESLint's built-in `complexity` rule needs no plugin and eslint is
	# already a devDependency, so this is a real gate, not a to-be-installed one — unlike
	# madge/knip above. Whole-file, not diff-scoped (a per-changed-line AST walk is out of
	# reach for a shell script), so a pre-existing function can surface here too: judge it
	# as a `note`, same as the MCP-based check in references/gates-1-5.md Gate 4, never a `fail`.
	say "== Gate 4c · complexity (eslint built-in complexity rule) =="
	COMPLEX=$(grep -E '\.ts$' "$TMP/src" | while IFS= read -r f; do
		pkgdir=$(printf '%s\n' "$f" | sed -E 's#^((apps|packages)/[^/]+)/.*#\1#')
		[ -f "$pkgdir/eslint.config.js" ] || continue
		rel="${f#"$pkgdir"/}"
		(cd "$pkgdir" && timeout 60 pnpm exec eslint --rule '{"complexity":["warn",6]}' "$rel" 2>/dev/null) |
			grep -oE 'complexity of [0-9]+\. Maximum allowed is [0-9]+' | sed "s|^|$f: |"
	done)
	if [ -z "$COMPLEX" ]; then
		pass "no changed .ts function over complexity 6 (eslint complexity rule)"
	else
		note "function(s) over complexity budget — >6 flag, >8 justify/decompose, >10 decompose:"
		printf '%s\n' "$COMPLEX" | head -12 | indent
	fi

	# red-test.sh: prove the new/changed tests actually go red without their source
	# change (MISTAKES.md coverage-theatre gate). Only runs on a clean tree — it reverts
	# tracked files and restores from HEAD, so uncommitted work must go first.
	say "== Gate 6d · red-test (mutation check) =="
	RT="$HOME/.claude/scripts/red-test.sh"
	if [ -x "$RT" ]; then
		if [ -z "$(git status --porcelain)" ]; then
			if out=$(timeout 900 "$RT" "$BASE" 2>&1); then
				pass "red-test.sh — new/changed tests go red without their source change"
			else
				fail "red-test.sh — a test stayed green without its source change (coverage theatre):"
				printf '%s\n' "$out" | tail -15 | indent
			fi
		else
			note "red-test.sh needs a clean tree (commit first): $RT $BASE"
		fi
	else
		note "red-test.sh not found at $RT"
	fi
fi

# --- the run leaves a trace ----------------------------------------------------------
# Whether this gate ran before an MR was not answerable from anything: 113 Skill calls
# over 200 sessions, and no way to tell which push they belonged to. One row per run, same
# shape as the triage and review ledgers, read back by outcome-metrics.sh. It records that
# the gate ran and what it found, never that the change was good.
LEDGER="$HOME/Documents/Coachbot_dev/Triage/gates-ledger.tsv"
if [ ! -s "$LEDGER" ]; then
	mkdir -p "$(dirname "$LEDGER")"
	printf 'date\tbranch\thead\tmode\tfails\tbrowser\n' >"$LEDGER"
fi
MODE="static"
[ "$RUN_TESTS" = "1" ] && MODE="tests"
[ "$RUN_COV" = "1" ] && MODE="coverage"
[ "$RUN_DEEP" = "1" ] && MODE="deep"
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
	"$(date +%F)" \
	"$(git branch --show-current)" \
	"$(git rev-parse --short HEAD)" \
	"$MODE" \
	"$([ -f "$TMP/failed" ] && echo fail || echo clean)" \
	"$BROWSER" >>"$LEDGER"

say ""
if [ -f "$TMP/failed" ]; then
	say "MECHANICAL GATES: at least one FAIL — fix before judging anything else"
	exit 1
fi
say "MECHANICAL GATES: no FAIL — go on to the judgment gates (2, 3, 4, 7, 8)"
exit 0
