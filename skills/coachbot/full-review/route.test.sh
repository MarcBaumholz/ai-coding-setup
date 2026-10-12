#!/usr/bin/env bash
# Asserts routing at real missed paths and a real staged/unstaged diff boundary.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0

expect() { # name files lines pattern-that-must-match...
    local name="$1" files="$2" lines="$3"; shift 3
    local out; out="$(ROUTE_FILES="$files" ROUTE_LINES="$lines" bash "$DIR/route.sh")" || { echo "FAIL $name: router exited nonzero"; fail=1; return; }
    for want in "$@"; do
        if ! grep -qx -- "$want.*" <<<"$out"; then
            echo "FAIL $name: expected '$want'"; echo "$out" | sed 's/^/    /'; fail=1
        fi
    done
    [[ $fail -eq 0 ]] && echo "ok   $name"
}

expect "backend-only fix, no svelte" \
    $'M\tpackages/database/src/repositories/thread.repository.ts\nM\tapps/studio/src/routes/api/x/+server.ts' 40 \
    "run greptile-review:state" "run greptile-review:callers" "run thermo-nuclear" "run rebac-security-review" "run backend-review" \
    "run database-optimizer" "skip frontend-review" "skip design-review" "skip ponytail" "skip codex" "skip devops-review"

expect "new svelte page, no server" \
    $'A\tapps/chat/src/routes/profile/+page.svelte\nM\tapps/chat/messages/de.json' 90 \
    "run security" "run frontend-review" "run design-review" "run ux-flow-review" "run ponytail" "run greptile-review:state" "skip greptile-review:callers" \
    "skip backend-review" "skip database-optimizer" "skip codex"

expect "migration triggers codex and db" \
    $'A\tpackages/database/db/migrations/20260930_x.sql\nM\tpnpm-lock.yaml' 20 \
    "run database-optimizer" "run codex" "run backend-review" "run ponytail"

expect "docs only" $'M\tREADME.md\nM\tdocs/a.md' 300 \
    "run greptile-review:state" "skip greptile-review:callers" "skip thermo-nuclear" "skip security" "skip codex"

expect "ci change" $'M\t.gitlab/ci/quality.yml' 12 \
    "run devops-review" "run greptile-review:callers" "skip frontend-review" "skip backend-review" "run security"

expect "large modify-only diff crosses the ponytail threshold" $'M\tapps/chat/src/lib/chat-request.ts' 200 \
    "run ponytail"

expect "spec-only svelte change calls no frontend reviewer" $'M\tpackages/voice/src/lib/voice-session.svelte.spec.ts\nM\tpackages/voice/src/lib/voice-capture-policy.ts' 60 \
    "skip frontend-review" "skip design-review" "run greptile-review:state" "skip greptile-review:callers"

expect "dashboard SQL helper routes the callers review" $'M\tpackages/database/src/project-dashboard.queries.ts' 40 \
    "run database-optimizer" "run greptile-review:callers" "run security" "run rebac-security-review"
expect "PII migration keeps general security beside ReBAC" $'A\tpackages/database/db/migrations/20261006143000_personal_materials.sql' 80 \
    "run security" "run rebac-security-review" "run database-optimizer" "run codex"
expect "small client auth change still traces callers" $'A\tapps/chat/src/lib/auth/session-expiry.ts' 136 \
    "run greptile-review:callers" "run security" "run codex" "skip rebac-security-review"
expect "existing form gets design and a11y review" $'M\tapps/chat/src/lib/components/settings/VoicePicker.svelte' 35 \
    "run design-review" "run frontend-review"
expect "memory tools get RAG review" $'M\tpackages/agents/src/memory/tools.ts' 25 \
    "run rag-review" "run security" "run rebac-security-review"
expect "generated-only diff" $'M\tpnpm-lock.yaml\nM\tpackages/database/db/schema.sql' 0 "skip all"
expect "150 source lines stays below size trigger" $'M\tpackages/voice/src/lib/example.ts' 150 "skip greptile-review:callers" "skip ponytail"

# The actual git seam: 100 unstaged source lines must not count as 200; generated
# and spec lines must not call the callers lens or ponytail. Also include staged code.
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
(
    cd "$T" || exit 1
    git init -q
    mkdir -p packages/voice/src/lib
    touch packages/voice/src/lib/example.ts
    git add packages/voice/src/lib/example.ts
    git -c user.name=route-test -c user.email=user@example.test commit -qm base
    base="$(git rev-parse HEAD)"
    awk 'BEGIN {for(i=0;i<100;i++) print "source"}' > packages/voice/src/lib/example.ts
    git add packages/voice/src/lib/example.ts
    awk 'BEGIN {for(i=0;i<20;i++) print "more"}' >> packages/voice/src/lib/example.ts
    awk 'BEGIN {for(i=0;i<300;i++) print "test"}' > packages/voice/src/lib/example.spec.ts
    awk 'BEGIN {for(i=0;i<300;i++) print "lock"}' > pnpm-lock.yaml
    git add packages/voice/src/lib/example.spec.ts pnpm-lock.yaml
    bash "$DIR/route.sh" "$base"
) > "$T/actual.txt" || fail=1
for want in 'files=2 lines=120' 'skip greptile-review:callers' 'skip ponytail'; do
    if ! grep -q "^$want" "$T/actual.txt"; then echo "FAIL real git diff: $want"; cat "$T/actual.txt"; fail=1; fi
done
[[ $fail -ne 0 ]] || echo "ok   real staged/unstaged diff counts source once"

exit $fail
