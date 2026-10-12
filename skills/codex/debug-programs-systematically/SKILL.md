---
name: debug-programs-systematically
description: Apply Andreas Zeller's Why Programs Fail to diagnose reproducible, intermittent, input-dependent, state-dependent, regression, and production failures with scientific hypotheses, controlled experiments, reduction, origin tracking, assertions, and causal evidence. Use when debugging is stuck, fixes are speculative, logs are noisy, or a regression needs a minimal test and verified cause.
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Debug Programs Systematically

## Workflow

1. Inspect the failure report, code, tests, runtime boundary, recent changes, and desired behavior. Preserve raw evidence before changing code.
2. Separate defect, infection, propagation, and observed failure. Write the earliest known wrong state.
3. Reproduce with an automated oracle that says pass/fail. Record environment, input, schedule, version, and frequency.
4. Reduce the failing input, configuration, trace, or change set while preserving the oracle.
5. State one falsifiable hypothesis with a predicted observation. Change one factor or add one targeted observation.
6. Trace data and control origins backward from the infected state; compare passing and failing executions.
7. Fix the cause, not the final symptom. Add the smallest regression test and useful invariant/assertion.
8. Re-run the reproducer, adjacent tests, and relevant runtime checks. Report disconfirmed hypotheses and remaining uncertainty.

Read [principles.md](references/principles.md) for the source models. Use [codebase-playbook.md](references/codebase-playbook.md) during diagnosis.

## Output contract

Return the failure oracle, defect-infection-failure chain, minimized reproducer, hypothesis log, causal evidence, bounded fix or recommendation, regression evidence, and unresolved risks.

Do not apply the full method literally when the failure is already localized, nondeterminism invalidates the oracle, observability changes timing materially, or incident containment must precede diagnosis. Do not force delta debugging or heavy instrumentation, and do not "clean up" unrelated code during a causal fix.
