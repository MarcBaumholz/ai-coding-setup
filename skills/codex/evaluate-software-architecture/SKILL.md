---
name: evaluate-software-architecture
description: Apply Mark Richards and Neal Ford's Fundamentals of Software Architecture, Second Edition to evaluate architecture characteristics, modularity, architecture styles, data/team topology, fitness functions, and decisions. Use for architecture option comparisons, system decomposition, ADRs, quality-attribute reviews, governance checks, or proposals driven by a fashionable style rather than measurable requirements.
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Evaluate Software Architecture

Architecture is contextual trade-off analysis. Start with drivers and evidence, not a preferred topology.

## Workflow

1. Inspect the system, tests, runtime/deployment topology, data ownership, team ownership, operational evidence, and decision goal.
2. Identify the smallest set of differentiating architecture characteristics and define measurable scenarios.
3. Read [references/principles.md](references/principles.md), then build the comparison using [references/codebase-playbook.md](references/codebase-playbook.md).
4. Compare at least two viable options, including the current architecture where applicable. Show benefits and liabilities for each driver.
5. Validate uncertainty with the cheapest useful evidence: dependency query, fitness function, benchmark, failure drill, deployment data, or focused spike.
6. Record a bounded ADR or recommendation with context, decision, consequences, and revisit trigger.
7. Prefer a code/test/governance artifact over a new architecture agent or tool.

## Output contract

Return decision context, prioritized measurable drivers, current constraints, options matrix, selected option and why, evidence, negative consequences, assumptions, revisit trigger, and bounded ADR/fitness artifact.

## Do not apply literally

Do not choose an architecture style from generic star ratings, maximize every “-ility,” or split deployment units before team/data/operational constraints support it. The second edition is broad survey material; use chapter models selectively and verify technology-specific claims against the current codebase and platform.
