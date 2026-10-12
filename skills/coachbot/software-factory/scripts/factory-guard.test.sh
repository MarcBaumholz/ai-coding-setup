#!/bin/bash
# Self-test for factory-guard.sh: builds throwaway git repos and plays each cheat the guard
# claims to catch. Every cheat must exit 1 FOR ITS OWN REASON (the expected FAIL text must
# appear); the honest runs must exit 0.
#   bash factory-guard.test.sh        exit 0 = every case behaved
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
GUARD="$HERE/factory-guard.sh"
export FACTORY_GUARD_RUNNER="$HERE/runners/node-test.sh"
WORK=$(mktemp -d) || exit 1
PASSED=0 FAILED=0

STUB='// factory:stub
export function add(a, b) { return 0; }'
THROWING='// factory:stub
export function add(a, b) { throw new Error("not implemented"); }'
IMPL='export function add(a, b) { return a + b; }'
HEAD_='import test from "node:test";
import assert from "node:assert/strict";
import { add } from "./add.mjs";'
TEST="$HEAD_
test(\"adds two numbers\", () => assert.equal(add(2, 3), 5));
test(\"adds a negative\", () => assert.equal(add(2, -3), -1));"
VACUOUS="$HEAD_
test(\"returns something\", () => assert.ok(add(2, 3) !== undefined));"

# repo [stub-content] [test-content]: base commit (a fixture and an older spec), then ONE
# contract commit holding the stub (omitted when empty) and the test. Sets CONTRACT.
repo() {
  stub=${1-$STUB} test=${2-$TEST}
  d="$WORK/r$((PASSED + FAILED))"; mkdir -p "$d/src/fixtures" "$d/lib"; cd "$d" || exit 1
  git init -q && git config user.email t@t && git config user.name t
  echo '{"n": 1}' > src/fixtures/data.json
  printf 'import test from "node:test";\ntest("old", () => {});\n' > lib/old.test.mjs
  git add -A; git commit -qm base
  [ -n "$stub" ] && printf '%s\n' "$stub" > src/add.mjs
  printf '%s\n' "$test" > src/add.test.mjs
  git add -A; git commit -qm contract; CONTRACT=$(git rev-parse HEAD)
}
commit() { git add -A; git commit -qm "$1"; }

# expect <exit> <reason-substring|-> <name> <command...>
expect() {
  want=$1 why=$2 name=$3; shift 3
  out=$("$@" 2>&1); got=$?
  if [ "$got" -eq "$want" ] && { [ "$why" = - ] || printf '%s' "$out" | grep -qF "$why"; }; then
    PASSED=$((PASSED + 1)); echo "ok    $name (exit $got)"
  else
    FAILED=$((FAILED + 1)); echo "WRONG $name: wanted exit $want with \"$why\", got $got"
    printf '%s\n' "$out" | sed 's/^/      /'
  fi
}

repo; expect 0 - "honest contract: tests fail on assertions" "$GUARD" contract
repo ""; expect 1 "failed to load" "contract with no stub: load error" "$GUARD" contract
repo "$IMPL"; expect 1 "already pass against the stubs" "contract test already passes" "$GUARD" contract
repo "$THROWING"; expect 1 "stub throws" "contract with a throwing stub" "$GUARD" contract
repo "$STUB" "$VACUOUS"; expect 1 "already pass against the stubs" "contract with a vacuous test" "$GUARD" contract

repo; printf '%s\n' "$IMPL" > src/add.mjs; commit impl
expect 0 - "honest implementation" "$GUARD" check "$CONTRACT"
expect 0 - "honest implementation inside owned paths" "$GUARD" check "$CONTRACT" 'src/*'

repo; printf '%s\n' "$IMPL" > src/add.mjs
printf 'import test from "node:test";\ntest("mine", () => {});\n' > src/extra.test.mjs; commit 'impl + own test'
expect 0 - "implementer adds its own test" "$GUARD" check "$CONTRACT"

repo; printf '%s\n' "$IMPL" > src/add.mjs; echo '// touched' >> lib/old.test.mjs; commit 'refactor'
expect 0 "REVIEW" "refactor edits a pre-existing spec (listed for review)" "$GUARD" check "$CONTRACT"

repo; printf '%s\n' "$IMPL" > src/add.mjs; echo 'export const x = 1;' > lib/elsewhere.mjs; commit 'outside'
expect 1 "outside the owned paths" "cheat: write outside the owned paths" "$GUARD" check "$CONTRACT" 'src/*'

repo; printf '%s\n' "$IMPL" > src/add.mjs; echo '// loosened' >> src/add.test.mjs; commit 'edit'
expect 1 "frozen by the contract commit" "cheat: edit a contract test" "$GUARD" check "$CONTRACT"

repo; git rm -q src/add.test.mjs; printf '%s\n' "$IMPL" > src/add.mjs; commit 'delete'
expect 1 "frozen by the contract commit" "cheat: delete a contract test" "$GUARD" check "$CONTRACT"

repo; git mv src/add.test.mjs src/add.renamed.mjs; printf '%s\n' "$IMPL" > src/add.mjs; commit 'rename'
expect 1 "frozen by the contract commit" "cheat: rename a contract test away" "$GUARD" check "$CONTRACT"

repo; printf '%s\n' "$IMPL" > src/add.mjs; echo '{"n": 2}' > src/fixtures/data.json; commit 'fixture'
expect 1 "test infrastructure" "cheat: change a test fixture" "$GUARD" check "$CONTRACT"

repo; printf '%s\n' "$IMPL" > src/add.mjs
printf 'import test from "node:test";\ntest.skip("later", () => {});\n' > src/more.test.mjs; commit 'skip'
expect 1 "focus or skip added" "cheat: add a .skip" "$GUARD" check "$CONTRACT"

repo; printf 'export function add(a, b) { return 5; }\n' > src/add.mjs; commit 'half'
expect 1 "contract tests: 1 of 2 pass" "incomplete implementation: a contract test fails" "$GUARD" check "$CONTRACT"

repo; printf '%s\n' "$IMPL" > src/add.mjs; commit impl; echo '// uncommitted' >> src/add.mjs
expect 1 "not clean" "dirty tree: guard refuses to judge" "$GUARD" check "$CONTRACT"

repo; FACTORY_GUARD_RUNNER=/nonexistent expect 1 "runner not executable" "runner missing: fail closed" "$GUARD" contract

echo; echo "$PASSED ok, $FAILED wrong   (scratch repos in $WORK)"
[ "$FAILED" -eq 0 ]
