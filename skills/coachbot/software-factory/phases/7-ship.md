# Phase 7 · Ship — HITL push, AFK the rest

**Goal**: land the change, watch it land, and know it works where it matters.

## 7.1 Hand over the commit

The agent may never `git commit` or `git push` — a global hook denies it, and
that denial is the merge gate working as designed. Hand the user exact
copy-paste commands with a Conventional Commits message.

The MR title is squash-merged and feeds `git-cliff` release notes, so **the
title is the changelog**: `type(scope): lowercase description`, ~70 chars, no
period, scope matching the app or package directory. `feat` / `fix` / `perf`
appear in release notes; `chore` / `refactor` / `test` / `docs` do not.

Use `/create-mr` for the MR itself; it holds the full type and scope tables.

## 7.2 The MR body carries the evidence

A reviewer should not have to ask what was verified. Include:

- What changed and why, in two sentences. Run `/unslop` over the whole body.
- The DoD with the Phase 3 evidence per item. For a bug fix, the Before / After
  table from `/verify-loop` Step 6, with the before shot taken while reproducing.
- The QA verdict and the known-gaps list from Phase 6.
- Every crossed house-rule limit with its one-line justification.
- Rollback: the flag name, or the migration's down path, or "forward-fix only"
  with the reason.

## 7.3 Watch it

`/review-mr` triages CI failures and the bot comments (Greptile, CodeRabbit) and
presents the real ones for approval. Its `greptile-gate.sh` turns the Greptile
verdict into an exit code: 5/5, zero open Greptile threads, review newer than
HEAD. After each pushed fix it re-triggers the review and loops, three rounds at
most, the user approving every round. Then `/babysit-mr` watches and reports;
READY TO MERGE requires that gate at exit 0, and the merge command is Marc's.

Bot findings get the same treatment as human ones: verify before agreeing.
Implementing a wrong suggestion politely is worse than pushing back.

**Do not merge unilaterally.** Report the MR URL and pipeline status.

## 7.4 Production

`dev` auto-deploys to `app.example.test` and `app.example.test` on
merge. Production is a **manual pipeline trigger on `main`** — merging to `main`
does not ship it. Remind the user, then verify on production once triggered:
the DoD's primary item, the error rate, and the flag state.

If the change is behind a flag, state the rollout plan and who flips it.

## 7.5 Close the loop

Three things, none optional:

1. **`progress.md`** gets a final entry: what shipped, what is in the hardening
   backlog, what is flagged off.
2. **Harness correction.** Where this run deviated from a rule, fix the _rule_ —
   this skill, a `.claude/rules/` file, or `CONTEXT.md` via `mattpocock-skills:domain-modeling`.
   A run that slid through on thin evidence gets fixed in the evidence
   criterion, not in the prompt. Append to `MISTAKES.md` the moment a real
   mistake is found, with one checkable prevention rule.
3. **Automation candidates.** If a manual step happened for the third time, say
   so and propose the cheapest mechanism that fits (doc < rule < skill < agent <
   hook). Naming the pattern is part of the job.

## Exit

Merged, deployed, verified. The pipeline is done.
