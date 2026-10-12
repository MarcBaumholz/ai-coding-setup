# Sources for the selected skills

This repository includes 14 skills in 15 folders. The two Ponytail folders contain different local variants. The files are a dated public snapshot of the selected coding workflow.

## Local workflow skills

| Skill | Source location | Notes |
| --- | --- | --- |
| `software-factory` | CoachBot parent workspace | Locally maintained process, phases, roles and guard scripts |
| `brainstorming` | CoachBot parent workspace | Local file; exact upstream origin not established |
| `verification-loop` | CoachBot parent workspace | Local self-review and mechanical checks |
| `verify-loop` | CoachBot parent workspace | Local acceptance checks in a running app |
| `full-review` | CoachBot parent workspace | Local routing and review instructions |
| `second-opinion` | CoachBot parent workspace | Local independent review process |
| `stress-test` | Global Claude skills directory | Local browser-QA instructions |
| `thermo-nuclear-code-quality-review` | CoachBot parent workspace | Local maintainability-review instructions; original author not established |
| `develop-things` | Local Codex skills directory | Short process for smaller changes |

These source locations establish where the files came from. They do not establish authorship or a licence. The [manifest](../skills/manifest.json) records the source hashes and any publication edits.

## Ponytail

Both [Ponytail](https://github.com/DietrichGebert/ponytail) variants retain their local contents and include the upstream MIT licence. A checkout remote and local skill files establish the source relationship. The inspection did not fully match the local variants to an upstream release.

## Skills based on technical books

| Skill | Method source named in the local file |
| --- | --- |
| `evaluate-software-architecture` | Mark Richards / Neal Ford, *Fundamentals of Software Architecture*, second edition |
| `design-deep-modules` | John Ousterhout, *A Philosophy of Software Design* |
| `debug-programs-systematically` | Andreas Zeller, *Why Programs Fail* |
| `refactor-safely` | Martin Fowler, *Refactoring*, first edition |

Book attribution identifies the source of the ideas. It does not identify who wrote or installed the local skill. The export includes local working notes and references, not source books.

## Runtime dependencies

The factory and review skills refer to Claude-specific plugins, agent definitions, project helpers and private project instructions. Those dependencies need their matching environment.

For example, the original setup names [Matt Pocock's skills](https://github.com/mattpocock/skills) for planning questions and handoffs, and the [Claude/Codex plugin](https://github.com/openai/codex-plugin-cc) for another review engine. Their presence in the original metadata does not verify a complete exported workflow.

The private CoachBot design-system skill and its files are excluded. A reference to a private project tool in the remaining instructions is a dependency, not a copy of that tool's contents.

## Updates

Choose the skill that fits the task. Check local changes, runtime support and existing licences before replacing an installed version. Same-name files can contain different instructions. The export does not assign a new blanket licence or synchronise with installed skills.
