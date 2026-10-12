#!/bin/bash
# node:test runner for factory-guard.sh — used by its self-test and by plain .test.mjs files.
# Prints the guard's summary line last: total= passed= failed= skipped= loaderror=
set -uo pipefail
out=$(node --test --test-reporter=tap "$@" 2>&1)
num() { printf '%s\n' "$out" | sed -nE "s/^# $1 ([0-9]+)$/\1/p" | tail -1; }
load=0
printf '%s' "$out" | grep -Eq 'ERR_MODULE_NOT_FOUND|Cannot find module|SyntaxError' && load=1
printf '%s\n' "$out" | tail -12
skipped=$(( $(num skipped) + $(num todo) ))
echo "total=$(num tests) passed=$(num pass) failed=$(num fail) skipped=$skipped loaderror=$load"
