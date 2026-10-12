# Evidence and limits

The original inspection took place on **12 October 2026**. It read local project instructions, selected skill files, installation metadata and a sample of session logs. The repository now focuses on the user-approved core skills. The private design-system skill is excluded.

## Workflow sources

The main sources were the CoachBot parent `CLAUDE.md`, `AGENT_OS.md`, factory phases and role briefs, review instructions, and the selected Codex skill files. The [manifest](../skills/manifest.json) records the exported files, source hashes and publication edits.

The factory documentation describes an intended process. Version 2 was edited on the inspection date; a completed run of that version has not been verified.

## Limited usage sample

The sample covered the 40 most recently modified CoachBot Claude session files, selected by filesystem modification time. Log entries ranged from 30 September to 12 October 2026 UTC. The selection was neither a date filter nor a random sample. The parser reported no JSON errors.

Among the included skills, the sample contained 9 explicit calls to `full-review` and 3 to `verification-loop`. It contained no direct `software-factory` tool call. Skills may also be read from files or used in sessions outside the sample.

These counts do not measure unique tasks or successful delivery. Retries and forks were not deduplicated by meaning, subagent logs were not enumerated separately, and Codex/Hermes histories were outside the sample. Raw conversations and tool results remain local.

## Export checks

The export contains 14 skills in 15 folders, with separate Ponytail variants. The remaining files match their recorded export hashes. All 15 entrypoints parse as YAML, and syntax checks pass for 7 shell and 2 Node scripts.

The factory's guard tests passed 18 cases, its comparison tests passed 9 cases, and the review router passed 15 cases. The later selection and privacy cleanup leave those script contents unchanged. These are script tests, not proof of a complete workflow in another environment.

The publication checker verifies hashes, counts, links, file types and common sensitive-content patterns. It also rejects the private design folder and broad catalogue files. It supplements a content review and does not guarantee detection of every sensitive value.

## Open issues

- The factory has conflicting commit rules: build requires contract commits, while another phase prohibits agent commits. Runtime permissions and exceptions need clarification.
- Some local skill files have no recorded author or licence. The manifest identifies those gaps.
- The skills require their project helpers, plugins and agent definitions. The export does not configure those dependencies.
- “MyAgent” has not been matched to a local project, so its workflow remains a proposed transfer of the approach.

## Publication boundary

Private application files, design-system contents, customer personas, incident history, account configuration and session transcripts are outside the public repository. The installed skills remain separate from these exported copies.

The public repository begins with a clean snapshot of the selected files. Earlier repository history is retained privately.
