# Software factory

This page describes the local CoachBot `software-factory` skill, version 2.0.0, read on 12 October 2026. It documents the intended workflow. A completed run of this version has not been verified.

## Scope

The skill is intended for new features, risky refactors, changes to data or authentication, and copying a reference implementation or design. Known small changes use a shorter process. Open design questions start with brainstorming.

## Phases

| Phase | Work | Result |
| --- | --- | --- |
| 0 · Understand | Read the request, code, context and any reference | Scope and assumptions; human scope approval |
| 1 · Plan | Prepare a mock, design, interfaces and test cases; get independent reviews | Revised plan; human plan approval |
| 2 · Build | One agent writes contract tests and inert stubs; another implements | Tests and implementation pass the guard |
| 3 · Verify | Run mechanical checks, acceptance checks and held-back cases | Evidence for the acceptance criteria and a list of gaps |
| 4 · Compare | Record reference values, freeze the checklist and measure the target | Missing or partial behaviour goes back to implementation |
| 5 · Review | Select code reviewers for the affected areas | Confirmed findings and unchecked areas |
| 6 · QA | Test user flows, reproduce failures and fix them | Human quality decision: BLOCK, FIX-FIRST or SHIP |
| 7 · Ship | Check the MR, merge, deployment and running app | Human merge decision and target-environment results |

A scope change returns to scope approval. A design problem returns to plan approval. Skipped steps retain a written reason. The progress file records where to resume after a context change.

## Roles and access to information

| Role | Receives | Context left out |
| --- | --- | --- |
| Coordinator | Full request and results | None; handles shared files and approvals |
| Assumption reviewer | Original request and repository | The coordinator's plan and assumptions |
| Mock builder | Request and current behaviour | The draft design |
| Plan reviewers | Exported plan and repository | Main conversation and other reviews |
| Test author | Scope, acceptance criteria, interfaces and test cases | Design rationale and rejected alternatives |
| Implementer | Specification, design and visible contract tests | Held-back test scenarios; contract tests remain unchanged |
| Verifier | Running app and held-back cases | Implementation diff |
| Reference inspector | Running reference | Target implementation |
| Target inspector | Fixed comparison checklist and running target | Reference source code |

The held-back cases, called holdouts in the skill, are a process boundary. Agents share the filesystem, so omitting a path from a brief does not prevent access. Enforced separation would require permissions or separate environments.

## The scripts

`factory-guard.sh` checks a test contract and the implementation against it. Its self-tests cover assertions failing against stubs, tests that pass without meaningful behaviour, throwing stubs, changes to contract tests or fixtures, writes outside assigned paths, and added `.skip` markers. Missing runners and unsuitable Git state cause a failed check.

`parity-diff.mjs` compares values recorded for the reference and target. It reports complete, partial, missing, waived and regressed items. Numeric values can have a tolerance. Visual items also require a human assessment.

During the snapshot inspection, the scripts passed **18 guard self-tests** and **9 comparison self-tests**. Those results cover the tested cases. They do not establish the quality of every acceptance test or compliance by a complete agent run.

## Round limits and stopping rules

| Loop | Limit or completion rule in the local skill |
| --- | --- |
| Contract, implementation and refactor | 5 rounds per slice |
| Mechanical checks | 3 rounds |
| Review fixes | 3 rounds |
| QA fixes | 4 rounds; two consecutive rounds with no new P0/P1 findings |
| Reference comparison | 4 rounds; a passing checklist plus two rounds closing no new gaps |
| Disputed tests | Three disputes per slice; then revisit the plan or interfaces |

The instructions also call for stopping on a repeated failure, regression, unavailable evidence or a decision that requires the owner. A check that could not run stays unverified.

## Working files

Requirements, plans, interfaces, test cases, progress, disputes, comparison results and QA reports go under `Tasks/<slug>/`, outside the Git checkout. Long-term architecture decisions go in the repository. The coordinator keeps holdout scenarios out of the implementer's brief.

## Conflicting commit instructions

The build role asks the test author to make a contract commit. The ship phase says agents may never commit or push. Other instructions limit that prohibition to unattended runs. The inspection did not resolve the exceptions or verify the claimed global hook.

The setup needs a clear rule for each role and execution mode. This documentation records the conflict and leaves the installed setup unchanged.

The instructions also ask reviewers to question a clean report. A review can find no defects. The useful follow-up is to check its scope and evidence, without inventing findings.

## Completion checks

Local tests, builds, remote CI, current bot reviews, merge, deployment and user behaviour each need their own evidence. A passing pipeline for an earlier commit does not cover a later change. A comparison result covers the properties included in its checklist.
