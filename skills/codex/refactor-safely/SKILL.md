---
name: refactor-safely
description: "Apply Martin Fowler's Refactoring: Improving the Design of Existing Code (first edition) as a disciplined, behavior-preserving workflow. Use when improving an existing design, removing a specific code smell, preparing code for a feature, or reviewing a refactor that must remain safe; require tests and small reversible steps."
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Refactor Safely

Use refactoring to improve internal structure without changing observable behavior. Do not label a feature, migration, optimization, or compatibility change as refactoring.

## Workflow

1. Inspect the target, callers, tests, public contracts, persistence effects, and runtime boundary.
2. State the behavior that must remain invariant and the design friction that blocks the next change.
3. Read [references/principles.md](references/principles.md), then select a treatment through [references/codebase-playbook.md](references/codebase-playbook.md).
4. Establish fast, relevant feedback. If it is missing, switch to `$change-legacy-code-safely` before structural work.
5. Put on one hat at a time: either change structure or change behavior.
6. Perform one named, reversible transformation; compile/type-check and test immediately.
7. Repeat only while each step serves the stated goal. Inspect the final diff and public behavior.
8. Report trade-offs, evidence, and any behavior that could not be verified.

## Output contract

Return the invariant, observed design friction, sequence of transformations, bounded diff/review artifact, checks after each meaningful step, final evidence, trade-offs, and unresolved risk.

## Do not apply literally

The local source is the 1999 first edition with Java and object-oriented examples. Translate intent to current language tooling; do not recreate dated inheritance-heavy mechanics. Avoid refactoring generated code, frozen vendor code, an unstable incident path, or performance-sensitive code without an appropriate characterization and measurement plan.
