# Codebase playbook

## Triggers

- A test or production failure cannot be reproduced reliably.
- Engineers are adding speculative fixes or broad logs.
- The visible error is far from the suspected cause.
- A regression depends on input, config, version, timing, or a change set.
- The fix has no test that fails before it.

## Questions

### Before coding

- What exact observation constitutes failure, and what is the smallest executable oracle?
- What version, input, environment, dependency, clock, random seed, and schedule produced it?
- What is the earliest confirmed infected state?

### During implementation

- What hypothesis does this change test, and what outcome would reject it?
- Did the experiment change only one causal factor?
- Can the input, trace, or commit set be reduced further?

### Code review

- Does the patch repair the cause or mask the final symptom?
- Does the regression test fail against the old code for the intended reason?
- Are unrelated cleanup and new behavior excluded?

### After deployment

- Did the failure rate and causal signal change as predicted?
- Is the new invariant observable, affordable, and privacy-safe?

## Workflow

1. Preserve logs/traces and create a structured failure record.
2. Turn the report into a deterministic or frequency-based automated oracle.
3. Establish the defect-infection-failure chain with confirmed vs unknown links.
4. Reduce circumstances using input minimization, config toggles, commit bisection, or event-trace reduction.
5. Rank origins with dependency tracing and passing/failing comparisons.
6. Run one falsifiable experiment at a time; record prediction and result.
7. Patch the earliest causal boundary available without scope expansion.
8. Prove old-fails/new-passes, run neighboring tests, and check runtime evidence.

## Compact example

```text
Failure: invoice total is occasionally negative.
Oracle: replay captured line items and assert total >= 0.
Reduction: 46 events -> two: DiscountApplied arrives before ItemAdded.
Hypothesis: consumer applies per-entity events in arrival rather than sequence order.
Prediction: ordering by sequence makes both permutations converge.
Fix: reject/gap-buffer out-of-sequence events; add both-order property test.
Evidence: old code fails one permutation; new code passes 10,000 generated permutations.
```

## Anti-patterns and counterexamples

- Shotgun edits that prevent knowing which change mattered.
- Reading code indefinitely without a failure oracle.
- Treating a stack-trace endpoint as the origin.
- Accepting "could not reproduce" without recording circumstances and frequency.
- Counterexample: credentials are actively leaking; revoke and contain first, diagnose second.
- Counterexample: a typo at the failing assertion with a direct deterministic test needs no elaborate reduction.

## Ready-to-copy project instruction

> For bug fixes, preserve a minimal failing oracle, distinguish defect from infected state and observed failure, test one falsifiable hypothesis at a time, and provide old-fails/new-passes evidence. Keep unrelated refactors out of the causal patch.

## Selected now implementation node

- **Learning:** A reproducer and hypothesis log turn debugging into controlled evidence.
- **Coding impact:** Reduce speculative edits and prevent symptom-only fixes.
- **Package:** Project instruction and bug-fix template.
- **Trigger:** Every nontrivial defect or regression.
- **Artifact:** Failing regression test plus a short `hypothesis / prediction / result` record.
- **First step:** Express the current failure as one automated oracle.
- **Evidence:** Test fails on the old revision, passes after the bounded fix, and adjacent tests pass.
- **Priority:** Now.
