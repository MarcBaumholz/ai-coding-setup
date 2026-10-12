#!/usr/bin/env bash
# Decide which reviewers /full-review spawns, from the changed paths alone.
# Usage: route.sh [base] [--deep]
#   base defaults to the merge-base with dev. Reviews committed + staged + unstaged.
# Test seam: ROUTE_FILES (git diff --name-status text) and ROUTE_LINES (changed lines)
#   replace the git calls, so route.test.sh runs without a repo.
# Output: one line per reviewer, `run <name> <reason>` or `skip <name> <reason>`,
#   then `files=<n> lines=<n>`. The orchestrator spawns every `run` line and copies
#   every `skip` line into the report. Deciding stays here; the skill only executes.
set -euo pipefail

DEEP=0
BASE=""
for arg in "$@"; do
    case "$arg" in
        --deep) DEEP=1 ;;
        *) BASE="$arg" ;;
    esac
done

if [[ -n "${ROUTE_FILES+x}" ]]; then
    STATUS="$ROUTE_FILES"
    LINES="${ROUTE_LINES:-0}"
else
    BASE="${BASE:-$(git merge-base origin/dev HEAD)}"
    # A diff to the worktree already includes staged and unstaged changes once.
    STATUS="$(git diff --name-status "$BASE")"
    LINES="$(git diff --numstat "$BASE" | awk '$1 != "-" && $3 !~ /\.(spec|test)\.|^e2e\/|\/__tests__\/|pnpm-lock\.yaml$|openapi\.json$|schema\.sql$/ {n += $1 + $2} END {print n + 0}')"
fi

# Generated and lock files never decide who reviews.
STATUS="$(printf '%s\n' "$STATUS" | grep -Ev '(pnpm-lock\.yaml|openapi\.json|schema\.sql)$' || true)"
FILES="$(printf '%s\n' "$STATUS" | awk 'NF {print $NF}')"
# Tests and e2e specs never call in a domain reviewer; greptile-review still reads them.
CODE="$(printf '%s\n' "$FILES" | grep -Ev '(\.(spec|test)\.[a-z]+$|^e2e/|/__tests__/)' || true)"
NEW="$(printf '%s\n' "$STATUS" | awk '$1 == "A" {print $NF}' | grep -Ev '(\.(spec|test)\.[a-z]+$|^e2e/|/__tests__/)' || true)"
COUNT="$(printf '%s\n' "$FILES" | grep -c . || true)"

has() { printf '%s\n' "$CODE" | grep -Eq "$1"; }
has_new() { printf '%s\n' "$NEW" | grep -Eq "$1"; }
run() { echo "run $1 $2"; }
skip() { echo "skip $1 $2"; }

if [[ "$COUNT" -eq 0 ]]; then
    echo "skip all empty diff"
    echo "files=0 lines=0"
    exit 0
fi

SERVER='(packages/(database|permissions|agents|auth|sveltekit-auth|queues)/|\.repository\.ts$|\+server\.ts$|\+page\.server\.ts$|\+layout\.server\.ts$|hooks\.server\.ts$|/processors/|apps/(conversation-worker|queue-worker|voice-gateway)/)'
SVELTE='(\.svelte$|\.svelte\.ts$)'
DESIGN='(packages/(coachbot-ui|design-system)/|app\.css$)'
SQL='(packages/database/src/repositories/|\.repository\.ts$|\.queries\.ts$|db/migrations/|\.sql$)'
INFRA='(\.gitlab-ci\.yml$|\.gitlab/|Dockerfile|infra_tf/|gitlab-runner-tf/|turbo\.json$|cloudbuild)'
RAG='(packages/agents/src/(knowledge|retrieval|memory)/|packages/moderation/|knowledge-chunk)'
RISK='(db/migrations/|packages/(permissions|auth|sveltekit-auth)/|/lib/auth/|\.zed$|hooks\.server\.ts$)'
DOCS_ONLY='^(.*\.(md|txt|png|jpg|svg))$'

if ! printf '%s\n' "$FILES" | grep -Evq "$DOCS_ONLY"; then
    run greptile-review:state "docs-only diff, claims and prose only"
    skip greptile-review:callers "docs-only diff"
    for r in thermo-nuclear security rebac-security-review ponytail backend-review database-optimizer frontend-review design-review ux-flow-review devops-review rag-review codex; do
        skip "$r" "docs-only diff"
    done
    echo "files=$COUNT lines=$LINES"
    exit 0
fi

run greptile-review:state "always: claims, every file, state over time"
# Round 3 measured the two-lens union; routed recall and these additions remain unproven.
if [[ "$DEEP" -eq 1 || "$LINES" -gt 150 ]] || has "$SERVER" || has "$SQL" || has "$INFRA" || has "$RISK"; then
    run greptile-review:callers "server, data, infra or auth paths, or ${LINES} lines"
else
    skip greptile-review:callers "small diff, no server, data or infra path"
fi
run thermo-nuclear "always: structure, duplication, file size"
run security "always: security-audit guidance + CoachBot checklist"
if has "$SERVER"; then
    run rebac-security-review "server, repository or permission paths touched"
else
    skip rebac-security-review "no server, repository or permission paths"
fi

if [[ "$DEEP" -eq 1 || "$LINES" -gt 150 || -n "$NEW" ]]; then
    run ponytail "diff ${LINES} lines or new files"
else
    skip ponytail "diff ${LINES} lines, no new files (threshold 150)"
fi

if has "$SERVER"; then run backend-review "server paths"; else skip backend-review "no server paths"; fi
if has "$SQL"; then run database-optimizer "repository, migration or SQL"; else skip database-optimizer "no SQL or repository"; fi
if has "$SVELTE"; then run frontend-review "svelte touched"; else skip frontend-review "no svelte"; fi
if has "$DESIGN" || has "$SVELTE"; then
    run design-review "design system, app.css or svelte (including existing controls)"
else
    skip design-review "no design-system path or non-test svelte"
fi
if has_new '\+page\.svelte$'; then run ux-flow-review "new page"; else skip ux-flow-review "no new page"; fi
if has "$INFRA"; then run devops-review "ci, docker or infra"; else skip devops-review "no ci, docker or infra"; fi
if has "$RAG"; then run rag-review "retrieval pipeline"; else skip rag-review "no retrieval path"; fi

if [[ "$DEEP" -eq 1 ]]; then
    run codex "deep mode"
elif has "$RISK"; then
    run codex "risk path: $(printf '%s\n' "$FILES" | grep -E "$RISK" | head -3 | tr '\n' ' ')"
else
    skip codex "no migration, auth or permission path, not deep"
fi

echo "files=$COUNT lines=$LINES"
