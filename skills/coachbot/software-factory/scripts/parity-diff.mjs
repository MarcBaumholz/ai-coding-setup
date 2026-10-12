#!/usr/bin/env node
// parity-diff.mjs — the parity verdict per ledger row, computed from two recorded values.
// No agent grades a row: the extractor records the reference value, the inspector records the
// target value, this script compares them.
//
//   node parity-diff.mjs ledger.json [--prev previous-result.json] [--json]
//
// Row: { id, type, what, probe, ref, target, refKind?: "live"|"mock", tol?: number, waived?: string }
//   type: copy | state | interaction | layout | behaviour | visual
//   target: what the inspector's probe returned; null when the element or call was not found.
// Verdict: done · partial · missing · needs-human · waived.
//   visual rows, and layout rows measured on a design-lab mock (refKind "mock"), are
//   needs-human: a mock's tokens are not the product's, so numbers never match by design.
// Exit 0 = every row done or waived · 1 = gaps remain · 2 = the ledger is malformed (fail closed).
import { readFileSync } from 'node:fs';

const TYPES = new Set(['copy', 'state', 'interaction', 'layout', 'behaviour', 'visual']);

export function verdict(row) {
  if (row.waived) return 'waived';
  if (row.type === 'visual') return 'needs-human';
  if (row.type === 'layout' && row.refKind === 'mock') return 'needs-human';
  const t = row.target;
  if (t === null || t === undefined || t === '' || (Array.isArray(t) && t.length === 0)) return 'missing';
  if (equal(row.ref, t, row.tol)) return 'done';
  if (Array.isArray(row.ref) && Array.isArray(t)) {
    return row.ref.some((r) => t.some((x) => equal(r, x, row.tol))) ? 'partial' : 'missing';
  }
  return 'partial';
}

function equal(a, b, tol) {
  if (typeof a === 'number' && typeof b === 'number') return Math.abs(a - b) <= (tol ?? 0);
  if (typeof a === 'string' && typeof b === 'string') return a.trim() === b.trim();
  if (Array.isArray(a) && Array.isArray(b)) {
    return a.length === b.length && a.every((x) => b.some((y) => equal(x, y, tol)));
  }
  return JSON.stringify(a) === JSON.stringify(b);
}

export function validate(rows) {
  const errors = [];
  if (!Array.isArray(rows) || rows.length === 0) return ['ledger must be a non-empty array'];
  const ids = new Set();
  for (const r of rows) {
    if (!r.id) errors.push('row without id');
    else if (ids.has(r.id)) errors.push(`duplicate id ${r.id}`);
    ids.add(r.id);
    if (!TYPES.has(r.type)) errors.push(`${r.id}: unknown type ${r.type}`);
    if (r.type !== 'visual' && !r.probe) errors.push(`${r.id}: no probe`);
    if (!('ref' in r)) errors.push(`${r.id}: no reference value`);
  }
  return errors;
}

export function diff(rows, prev = []) {
  const before = new Map(prev.map((r) => [r.id, r.verdict]));
  const result = rows.map((r) => ({ id: r.id, type: r.type, what: r.what, verdict: verdict(r) }));
  const counts = {};
  for (const r of result) counts[r.verdict] = (counts[r.verdict] ?? 0) + 1;
  const regressions = result.filter((r) => before.get(r.id) === 'done' && r.verdict !== 'done').map((r) => r.id);
  const open = result.filter((r) => r.verdict !== 'done' && r.verdict !== 'waived').length;
  return { result, counts, regressions, open };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [file, ...rest] = process.argv.slice(2);
  const prevAt = rest.indexOf('--prev');
  let rows;
  let prev = [];
  try {
    rows = JSON.parse(readFileSync(file, 'utf8'));
    if (prevAt >= 0) prev = JSON.parse(readFileSync(rest[prevAt + 1], 'utf8')).result ?? [];
  } catch (e) {
    console.error(`BLOCKED: cannot read ledger: ${e.message}`);
    process.exit(2);
  }
  const errors = validate(rows);
  if (errors.length) {
    console.error(`BLOCKED: malformed ledger\n  ${errors.join('\n  ')}`);
    process.exit(2);
  }
  const out = diff(rows, prev);
  if (rest.includes('--json')) console.log(JSON.stringify(out, null, 2));
  else {
    for (const r of out.result) console.log(`${r.verdict.padEnd(11)} ${r.id.padEnd(6)} ${r.type.padEnd(11)} ${r.what ?? ''}`);
    console.log(`\n${Object.entries(out.counts).map(([k, v]) => `${v} ${k}`).join(' · ')} · ${rows.length} rows`);
    if (out.regressions.length) console.log(`REGRESSED since last round: ${out.regressions.join(', ')}`);
  }
  process.exit(out.open === 0 ? 0 : 1);
}
