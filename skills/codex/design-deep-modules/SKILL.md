---
name: design-deep-modules
description: Apply John Ousterhout's A Philosophy of Software Design to reduce codebase complexity. Use for module or API design, refactoring, information leakage, excessive configuration, shallow wrappers, exception-heavy interfaces, unclear names, change amplification, cognitive-load reviews, and design alternatives before implementation.
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Design Deep Modules

Inspect the relevant code, tests, callers, runtime boundary, change goal, and recent change history before redesigning. Read [principles.md](references/principles.md) for the book-derived models and [codebase-playbook.md](references/codebase-playbook.md) for the review loop.

## Workflow

1. Trace one representative change through callers, interfaces, implementation, configuration, errors, and tests. Record change amplification, cognitive load, and unknown unknowns.
2. Identify leaked decisions and shallow abstractions. Separate unavoidable domain complexity from complexity created by the design.
3. Produce at least two designs with different boundaries. Compare interface surface, hidden knowledge, failure semantics, generality, performance, migration, and testability.
4. Select the smallest design that pulls recurring complexity behind a stable, understandable interface. Keep special policy outside a reusable mechanism where useful.
5. Implement a bounded slice with precise names, interface comments, compatibility handling, and tests at the abstraction boundary.
6. Verify a representative caller becomes simpler and the design does not merely move complexity invisibly.

## Output contract

Return the inspected path, complexity symptoms, leaked decisions, two design alternatives and trade-offs, selected boundary, code/review artifact, caller before/after, tests/evidence, and remaining complexity.

Do not apply every maxim literally. Do not generalize speculative use cases, hide operationally essential controls, swallow actionable errors, write comments that repeat code, or redesign a stable module without observed complexity. Treat the book as an opinionated complexity lens, not a universal style law.
