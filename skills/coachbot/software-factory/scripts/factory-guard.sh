#!/bin/bash
# factory-guard.sh — the test author writes the tests, the implementer may not touch them.
#
#   factory-guard.sh contract
#       HEAD is the contract commit. Its tests must load, run, and ALL fail against the stubs.
#       Stubs are inert: they return a wrong value of the right type and never throw, so a
#       vacuous assertion (toBeDefined) passes against the stub and is caught here.
#   factory-guard.sh check <contract-sha> [owned-glob ...]
#       After the build: no frozen file changed, no test infrastructure changed, no
#       .only/.skip added, every contract test runs and passes, and — when owned globs are
#       given — every changed path sits inside them.
#
# Exit 0 = every check passed. Exit 1 = a check failed OR could not run (fail closed).
#
# Frozen = every file in the contract commit except the stubs (marker `factory:stub`).
# Test infrastructure (configs, setup, fixtures, mocks, test-utils) may be added to, never
# modified. Specs that existed before the contract may change — a refactor must update them —
# but each one is listed under REVIEW so the quality gate reads it.
#
# Not handled: package.json test scripts, because dependency edits are routine there; review
# catches a changed test script. Source special-cased to the visible test inputs, because no
# diff rule can see intent; the holdout scenarios exist for that.
#
# The runner prints `total=N passed=P failed=F skipped=S loaderror=L` as its last line.
# Default runs vitest per package; FACTORY_GUARD_RUNNER swaps it (the self-test uses node:test).
#
# bash 3.2 compatible (macOS system bash).

set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
RUNNER="${FACTORY_GUARD_RUNNER:-$HERE/runners/vitest.sh}"

die() { echo "BLOCKED: $*"; exit 1; }

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || die "not a git repo"
cd "$ROOT" || die "cannot enter $ROOT"
[ -x "$RUNNER" ] || die "runner not executable: $RUNNER"
[ -z "$(git status --porcelain)" ] || die "working tree is not clean; the guard judges commits, commit first"

# Test infrastructure: a closed list. A path not named here is source or a spec.
is_infra() {
  case "$1" in
    */__mocks__/*|*/test-utils/*|*/src/test/*|*/src/tests/*|*/fixtures/*|*/.storybook/*|e2e/fixtures/*) return 0 ;;
  esac
  case "$(basename "$1")" in
    vitest.*|vite.config.*|playwright.config.*|*setup-tests*|*test-setup*) return 0 ;;
  esac
  return 1
}

is_spec() {
  case "$1" in *.spec.*|*.test.*|*.stories.*|e2e/tests/*) return 0 ;; esac
  return 1
}

is_runnable_test() {
  case "$1" in *.spec.*|*.test.*) return 0 ;; esac
  return 1
}

# Files the commit added or modified (root commits included).
commit_files() {
  git diff-tree --root --no-commit-id --name-only -r --diff-filter=AM "$1"
}

is_stub() { git show "$1:$2" 2>/dev/null | grep -q 'factory:stub'; }

# Runs the runner and parses its summary line into R_TOTAL, R_PASSED, R_FAILED, R_SKIPPED, R_LOAD.
run_tests() {
  out=$("$RUNNER" "$@" 2>&1)
  summary=$(printf '%s\n' "$out" | grep -E '^total=[0-9]+ passed=[0-9]+ failed=[0-9]+ skipped=[0-9]+ loaderror=[0-9]+$' | tail -1)
  if [ -z "$summary" ]; then
    echo "BLOCKED: the runner printed no summary line. Last lines:"
    printf '%s\n' "$out" | tail -8 | sed 's/^/  /'
    exit 1
  fi
  eval "$(printf '%s' "$summary" | sed -E 's/total=([0-9]+) passed=([0-9]+) failed=([0-9]+) skipped=([0-9]+) loaderror=([0-9]+)/R_TOTAL=\1 R_PASSED=\2 R_FAILED=\3 R_SKIPPED=\4 R_LOAD=\5/')"
  echo "  runner: $summary"
}

FAILS=0
fail() { echo "  FAIL    $*"; FAILS=$((FAILS + 1)); }
pass() { echo "  pass    $*"; }
review() { echo "  REVIEW  $*"; }

contract_tests() {
  tests=""
  for f in $(commit_files "$1"); do is_runnable_test "$f" && tests="$tests $f"; done
  [ -n "$tests" ] || die "contract commit $1 holds no test file"
  echo "$tests"
}

cmd_contract() {
  sha=$(git rev-parse HEAD)
  echo "factory-guard contract $sha"
  tests=$(contract_tests "$sha") || { echo "$tests"; exit 1; }
  throwing=""
  for f in $(commit_files "$sha"); do
    is_stub "$sha" "$f" && git show "$sha:$f" | grep -qE '\bthrow\b' && throwing="$throwing $f"
  done
  [ -z "$throwing" ] && pass "stubs are inert (no throw)" || fail "stub throws:$throwing — return a wrong value of the right type, so vacuous tests show up as passing"
  # shellcheck disable=SC2086
  run_tests $tests
  [ "$R_LOAD" -eq 0 ] && pass "every test file loaded" || fail "$R_LOAD test file(s) failed to load: red for the wrong reason"
  [ "$R_TOTAL" -gt 0 ] && pass "$R_TOTAL test(s) ran" || fail "no test ran"
  [ "$R_SKIPPED" -eq 0 ] && pass "nothing skipped" || fail "$R_SKIPPED test(s) skipped in the contract"
  [ "$R_PASSED" -eq 0 ] && pass "no test passes against the stubs" || fail "$R_PASSED test(s) already pass against the stubs: they test nothing"
  finish "contract=$sha tests=$R_TOTAL"
}

cmd_check() {
  [ $# -ge 1 ] || die "usage: factory-guard.sh check <contract-sha> [owned-glob ...]"
  sha=$(git rev-parse --verify --quiet "$1^{commit}") || die "unknown commit $1"
  shift
  git merge-base --is-ancestor "$sha" HEAD || die "$sha is not an ancestor of HEAD"
  echo "factory-guard check $sha..HEAD${1:+  owned: $*}"

  frozen=""
  for f in $(commit_files "$sha"); do is_stub "$sha" "$f" || frozen="$frozen
$f"; done

  bad=0
  while IFS="$(printf '\t')" read -r st p1 p2; do
    [ -n "$st" ] || continue
    for p in $p1 $p2; do
      if [ $# -gt 0 ]; then
        owned=0
        for g in "$@"; do case "$p" in $g) owned=1 ;; esac; done
        [ "$owned" -eq 1 ] || { fail "$st $p — outside the owned paths"; bad=1; }
      fi
      case "$st" in A*) continue ;; esac
      if printf '%s\n' "$frozen" | grep -qxF "$p"; then fail "$st $p — frozen by the contract commit"; bad=1
      elif is_infra "$p"; then fail "$st $p — test infrastructure"; bad=1
      elif is_spec "$p"; then review "$st $p — pre-existing spec changed"
      fi
    done
  done <<EOF
$(git diff --name-status -M "$sha" HEAD)
EOF
  [ "$bad" -eq 0 ] && pass "no frozen, infrastructure or unowned file touched"

  skips=$(git diff -U0 "$sha" HEAD | grep -E '^\+[^+]' | grep -E '\b(it|test|describe|suite)\.(only|skip|todo|skipIf|runIf|fails)\b')
  [ -z "$skips" ] && pass "no .only/.skip/.todo/.fails added" || fail "focus or skip added: $(printf '%s' "$skips" | head -3 | tr '\n' ' ')"

  tests=$(contract_tests "$sha") || { echo "$tests"; exit 1; }
  # shellcheck disable=SC2086
  run_tests $tests
  [ "$R_LOAD" -eq 0 ] && pass "every contract test file loaded" || fail "$R_LOAD contract test file(s) failed to load"
  [ "$R_SKIPPED" -eq 0 ] && pass "no contract test skipped" || fail "$R_SKIPPED contract test(s) skipped"
  if [ "$R_TOTAL" -gt 0 ] && [ "$R_PASSED" -eq "$R_TOTAL" ] && [ "$R_FAILED" -eq 0 ]; then
    pass "all $R_TOTAL contract test(s) pass"
  else
    fail "contract tests: $R_PASSED of $R_TOTAL pass, $R_FAILED fail"
  fi
  finish "contract=$sha head=$(git rev-parse --short HEAD)"
}

finish() {
  if [ "$FAILS" -eq 0 ]; then echo "GUARD OK  $1"; exit 0; fi
  echo "GUARD FAILED  $FAILS check(s)  $1"; exit 1
}

case "${1:-}" in
  contract) shift; cmd_contract "$@" ;;
  check) shift; cmd_check "$@" ;;
  *) die "usage: factory-guard.sh contract | check <contract-sha> [owned-glob ...]" ;;
esac
