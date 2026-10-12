#!/bin/bash
# vitest runner for factory-guard.sh. Args: test files relative to the repo root.
# Runs each file from its nearest package.json with vitest's JSON reporter and sums the counts.
# Prints the guard's summary line last: total= passed= failed= skipped= loaderror=
# A file whose suite never reached a test (import failed, config excluded it, no JSON written)
# counts as a load error: a test that did not run has proven nothing.
# Second copy of red-test.sh's package lookup and integration-config choice, deliberately:
# red-test needs exit codes per file, the guard needs counts. Not extracted, because
# ~/.claude/scripts is shared by every workspace; if a third caller appears, extract then.
set -uo pipefail
T=0 P=0 F=0 S=0 L=0
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
i=0
for t in "$@"; do
  i=$((i + 1))
  pkg=$(dirname "$t")
  while [ "$pkg" != "." ] && [ ! -f "$pkg/package.json" ]; do pkg=$(dirname "$pkg"); done
  rel="${t#"$pkg"/}"
  cfg=""
  case "$t" in *.integration.spec.ts)
    [ -f "$pkg/vitest.integration.config.ts" ] && cfg="--config vitest.integration.config.ts" ;;
  esac
  json="$tmp/$i.json"
  # shellcheck disable=SC2086
  ( cd "$pkg" && NO_COLOR=1 pnpm exec vitest run $cfg --reporter=json --outputFile="$json" "$rel" ) >"$tmp/$i.log" 2>&1
  if [ ! -s "$json" ]; then
    echo "no result for $t:"; tail -5 "$tmp/$i.log" | sed 's/^/  /'
    L=$((L + 1)); continue
  fi
  read -r t_ p_ f_ s_ l_ <<EOF
$(node -e '
  const r = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  const load = r.numTotalTests === 0
    || r.testResults.some(s => s.status === "failed" && s.assertionResults.length === 0) ? 1 : 0;
  console.log(r.numTotalTests, r.numPassedTests, r.numFailedTests, r.numPendingTests + r.numTodoTests, load);
' "$json")
EOF
  echo "$t: total=$t_ passed=$p_ failed=$f_ skipped=$s_ loaderror=$l_"
  T=$((T + t_)) P=$((P + p_)) F=$((F + f_)) S=$((S + s_)) L=$((L + l_))
done
echo "total=$T passed=$P failed=$F skipped=$S loaderror=$L"
