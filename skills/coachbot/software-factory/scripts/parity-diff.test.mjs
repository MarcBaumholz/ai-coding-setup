// node --test parity-diff.test.mjs
import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { verdict, diff, validate } from './parity-diff.mjs';

const row = (o) => ({ id: 'P1', type: 'copy', what: 'x', probe: 'p', ref: 'Add stage', ...o });

test('equal values are done; whitespace does not count', () => {
  assert.equal(verdict(row({ target: ' Add stage ' })), 'done');
});
test('a different value is partial, a missing one is missing', () => {
  assert.equal(verdict(row({ target: 'Add step' })), 'partial');
  assert.equal(verdict(row({ target: null })), 'missing');
  assert.equal(verdict(row({ target: '' })), 'missing');
});
test('numbers compare within the row tolerance', () => {
  assert.equal(verdict(row({ type: 'layout', ref: 16, target: 17, tol: 1 })), 'done');
  assert.equal(verdict(row({ type: 'layout', ref: 16, target: 20, tol: 1 })), 'partial');
});
test('lists: same members done, some members partial, none missing', () => {
  const ref = ['a', 'b', 'c'];
  assert.equal(verdict(row({ ref, target: ['c', 'b', 'a'] })), 'done');
  assert.equal(verdict(row({ ref, target: ['a'] })), 'partial');
  assert.equal(verdict(row({ ref, target: ['z'] })), 'missing');
});
test('visual rows and layout measured on a mock always need a human', () => {
  assert.equal(verdict(row({ type: 'visual', target: 'Add stage' })), 'needs-human');
  assert.equal(verdict(row({ type: 'layout', refKind: 'mock', ref: 16, target: 16 })), 'needs-human');
});
test('a waived row is waived whatever its values', () => {
  assert.equal(verdict(row({ target: null, waived: 'owner: not in v1' })), 'waived');
});
test('a row that was done last round and is not now is a regression', () => {
  const out = diff([row({ target: 'Add step' })], [{ id: 'P1', verdict: 'done' }]);
  assert.deepEqual(out.regressions, ['P1']);
  assert.equal(out.open, 1);
});
test('validate rejects a ledger without probes, refs or known types', () => {
  assert.deepEqual(validate([]), ['ledger must be a non-empty array']);
  const errs = validate([{ id: 'P1', type: 'shape' }]);
  assert.ok(errs.some((e) => e.includes('unknown type')));
  assert.ok(errs.some((e) => e.includes('no probe')));
  assert.ok(errs.some((e) => e.includes('no reference value')));
});
test('CLI exit codes: 0 all done, 1 gaps, 2 malformed', () => {
  const dir = mkdtempSync(join(tmpdir(), 'parity-'));
  const cli = join(dirname(fileURLToPath(import.meta.url)), 'parity-diff.mjs');
  const run = (rows) => {
    const f = join(dir, `${Math.random()}.json`);
    writeFileSync(f, JSON.stringify(rows));
    try { execFileSync('node', [cli, f], { stdio: 'pipe' }); return 0; } catch (e) { return e.status; }
  };
  assert.equal(run([row({ target: 'Add stage' })]), 0);
  assert.equal(run([row({ target: null })]), 1);
  assert.equal(run([{ id: 'P1' }]), 2);
});
