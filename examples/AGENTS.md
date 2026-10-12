# Example project instructions

This is a generic template based on the documented workflow. It summarises the approach; enforcing the rules requires suitable tools and permissions.

## Goal and context

Solve the requested problem with the smallest correct change. Read the project instructions, affected callers and relevant tests. Identify assumptions that still need checking.

## Working process

- Define observable acceptance criteria and exclusions.
- Plan before changes to architecture, data or permissions.
- Check existing solutions before adding abstractions or dependencies.
- Work in reviewable increments and preserve unrelated changes.
- With multiple agents, assign explicit write paths and one writer per file. Handle shared files after the work rejoins.
- For higher-risk work, separate test writing, implementation and verification. Review from the original request.

## Checks and reporting

Run appropriate tests and runtime checks. Report the command, code revision or environment, and result. Keep unavailable checks marked as unverified.

Report local checks, CI, merge, deployment and user behaviour separately. Reviews include concrete failure cases and `Checked` / `Not checked` sections. A clean review is acceptable if its scope and evidence support it.

## Permissions

Before a run, define which local and external actions are authorised. Bring scope changes, design decisions and hard-to-undo actions to the owner. Keep secrets and private data out of published material.

Unattended work needs a budget, stopping rules and a way to ask for help.
