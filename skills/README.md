# Core skill files

This directory contains **14 selected skills in 15 folders**. Ponytail has separate Codex and CoachBot variants. The selection covers the coding and factory workflow. Private design-system files are excluded.

| Skill | Purpose |
| --- | --- |
| [software-factory](coachbot/software-factory/SKILL.md) | Coordinate planning, tests, implementation, review and QA |
| [develop-things](codex/develop-things/SKILL.md) | Use a short default process for smaller changes |
| [brainstorming](coachbot/brainstorming/SKILL.md) | Clarify an idea before deciding what to build |
| [ponytail](coachbot/ponytail/SKILL.md), [Codex variant](codex/ponytail/SKILL.md) | Reuse existing solutions and keep changes small |
| [verification-loop](coachbot/verification-loop/SKILL.md) | Check scope, implementation and mechanical gates |
| [verify-loop](coachbot/verify-loop/SKILL.md) | Check acceptance criteria in the running app |
| [full-review](coachbot/full-review/SKILL.md) | Select reviewers for the changed areas |
| [second-opinion](coachbot/second-opinion/SKILL.md) | Review from the original request |
| [stress-test](coachbot/stress-test/SKILL.md) | Explore user flows and failures |
| [thermo-nuclear-code-quality-review](coachbot/thermo-nuclear-code-quality-review/SKILL.md) | Look for structural problems and unnecessary complexity |
| [evaluate-software-architecture](codex/evaluate-software-architecture/SKILL.md) | Compare designs against concrete requirements |
| [design-deep-modules](codex/design-deep-modules/SKILL.md) | Reduce complexity at module and API boundaries |
| [debug-programs-systematically](codex/debug-programs-systematically/SKILL.md) | Reproduce a bug and test possible causes |
| [refactor-safely](codex/refactor-safely/SKILL.md) | Change structure while preserving behaviour |

Use the skills that fit the task. This list is not a requirement to run all of them on every change.

## Using a copy

Keep the whole skill folder so references and scripts remain beside `SKILL.md`. For a user-level Codex installation, copy a selected folder to `~/.codex/skills/`; for Claude Code, use `~/.claude/skills/`. Check the target tool's supported format and compare any existing same-name skill before replacing it.

The CoachBot skills also refer to private project rules, helper scripts, agent definitions and plugins. These copies describe that workflow; they do not provide a configured CoachBot runtime.

## Publication edits

The [manifest](manifest.json) records source locations, hashes, edits, omitted files and dependencies. The installed originals were not edited.

The copies use `~/project-workspace` for workspace paths and `app.example.test` for project service addresses. Private account and issue identifiers have been replaced with examples. Configure these values for your project. The factory's private application-invariants file has been replaced with a checklist for your own baseline.

One retained source description needed YAML quoting in the exported copy. Other source metadata and invocation policies remain intact, including tool-specific fields.

Private incident history, customer personas, design-system files, account configuration and wiki links are outside the export. The review panel's private `greptile/` history is omitted. The factory and verification skills can still refer to private design tools as external dependencies; those tools are not included here.

## Sources and licences

Existing notices are retained. Both Ponytail variants include the MIT licence from the recorded upstream repository. Some local files have no recorded licence or confirmed author; their manifest entries identify that gap. There is no new blanket licence for this collection.

The [source guide](../docs/skills-and-sources.md) covers the selected skills.

## Checks

All 15 entrypoints parse as YAML. Syntax checks pass for 7 shell and 2 Node scripts. The retained files match their recorded export hashes. The factory tests previously passed 18 guard cases and 9 comparison cases; the review router passed 15 cases. Curation leaves those script contents unchanged.

The publication checker verifies hashes, counts, local links and common sensitive-content patterns. These checks do not verify every plugin or private helper, or a complete factory run in another environment.
