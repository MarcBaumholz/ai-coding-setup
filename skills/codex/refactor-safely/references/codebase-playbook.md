# Codebase playbook

## Invoke when

- a feature is hard because one concern is scattered or entangled;
- duplicated logic changes together;
- a function mixes separable levels of abstraction;
- a class has an unstable reason to change;
- a review claims “no behavior change” and needs verification;
- a safe rename, extraction, move, or conditional simplification is needed.

## Questions

### Before coding

- Which observable behaviors and contracts are invariant?
- What specific next change becomes easier?
- Which test boundary sees the relevant risk?
- Is this truly refactoring, or a migration/optimization/behavior change?

### During implementation

- Am I wearing the structure hat or behavior hat?
- Can this move be smaller or IDE/compiler-assisted?
- Did I run the focused check after the last conceptual step?
- Does the new abstraction name a stable concept?

### In code review

- Can each step be explained as a named transformation?
- Did serialization names, errors, ordering, side effects, queries, or timing change?
- Is the diff broader than the stated design friction?
- Has useful cohesion been replaced by navigation overhead?

### After deployment

- Did the target change become safer or shorter?
- Did latency, allocation, query count, or failure shape drift?
- Is the abstraction reused by change, or merely present?

## Step-by-step codebase workflow

1. Inspect target code, callers, tests, public API, data and I/O effects.
2. Record an invariant and a single design objective.
3. Run the narrow baseline; add characterization coverage if needed.
4. Choose one transformation and make it mechanically.
5. Compile/type-check, run the focused test, and inspect the diff.
6. Continue in small steps until the objective is met; stop when another smell is unrelated.
7. Run broader proportionate tests and any relevant performance or contract check.
8. Report transformation sequence, evidence, and non-verified observables.

## Compact example

```ts
// Before: policy and formatting change together.
function invoiceTotal(invoice: Invoice) {
  let total = 0;
  for (const line of invoice.lines) total += line.quantity * line.unitPrice;
  return `${invoice.currency} ${total.toFixed(2)}`;
}

// Step 1: Extract Function while preserving output.
function invoiceAmount(invoice: Invoice) {
  return invoice.lines.reduce((sum, line) => sum + line.quantity * line.unitPrice, 0);
}

function invoiceTotal(invoice: Invoice) {
  return `${invoice.currency} ${invoiceAmount(invoice).toFixed(2)}`;
}
```

Verify exact rounding, empty invoices, ordering, and output formatting before moving currency formatting elsewhere. Extraction alone is not proof of improvement; it is useful if pricing policy now changes independently.

## Anti-patterns and counterexamples

- “Refactoring” that changes error behavior or data contracts without saying so.
- One large cleanup commit with no intermediate green checks.
- Fixing every nearby smell while implementing one feature.
- Extracting one-use wrappers that add no name or boundary value.
- Trusting compiler-assisted rename around reflection or string-based registration.
- Applying object-oriented catalog moves to functional/data-oriented code verbatim.

## Selected now implementation node

- **Learning:** behavior-preserving structure changes become safe through small verified steps.
- **Coding impact:** failures are localized and design can evolve alongside features.
- **Package:** project instruction.
- **Trigger:** any refactor larger than a trivial rename.
- **Artifact:** invariant note, named transformation sequence, and test evidence.
- **First step:** write the invariant and run the narrow baseline.
- **Evidence:** focused checks stay green after each step and broader relevant checks pass at the end.
- **Priority:** now.

## Ready-to-copy project instruction

> For refactors, state the observable behavior that must remain unchanged. Use one named, reversible transformation at a time, run the narrowest relevant check after each step, and separate behavior changes from structural cleanup.
