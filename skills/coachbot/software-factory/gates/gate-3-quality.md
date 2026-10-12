# ★ Gate 3 · Quality — the verdict before it leaves the machine

**Position**: after Phases 5 (verify), 6 (review) and 7 (QA stress), before the
MR is handed to the user to push.

By here the machine has spent its whole budget. This gate asks one question:
**would you defend this in production, and what is the worst thing that can
still happen?**

## What you present

One report, in this order — worst news first.

1. **Verdict**: BLOCK · FIX-FIRST · SHIP, with the single sentence that decides it.
2. **Open risks** — what could still break, ranked, each with its blast radius.
3. **Mechanical evidence** — `pnpm run ci` result, the conditional sync checks
   by touched area, the must-pass test-plan rows and their status.
4. **DoD evidence** — per item: the command output, screenshot, or computed
   value. Items marked `not-verified` appear here, not hidden.
5. **Review findings** — Critical/High/Medium counts, each Critical and High
   with its resolution or the user's pending decision. Reviewer disagreements
   shown unresolved where they were not resolved.
6. **Security** — the checklist result by surface, plus the allow/deny test
   evidence for every new permission.
7. **QA** — the stress-test verdict, lanes run, P0/P1 findings and their
   regression tests, **and what nobody looked at**.
8. **Separation evidence** — every `factory-guard.sh` line (contract and check, per slice),
   every dispute row with its outcome, every `REVIEW` spec, the holdout results, and the final
   `parity-diff` summary with its needs-human screenshot pairs. A slice that skipped the
   contract split is named here with its reason.
9. **House-rule exceptions** — every crossed limit with its justification.
10. **Rollback plan** — flag, migration down path, or forward-fix-only with the
   reason.

## Severity mapping

The doctrine files use three severity vocabularies. They map onto the verdict as:

| house-rules | DDIA / doctrine tables | Verdict input |
| --- | --- | --- |
| `block` | Blocker | **Critical** |
| `fix` | Major | **High** |
| `note` | Minor | Backlog ticket |

QA findings use `/stress-test`'s P0/P1/P2/question scale: P0 → Critical,
P1 → High, P2 → backlog.

## The verdict rules

**BLOCK** on any of:

- A Critical correctness or security finding.
- A missing server-side gate, unmasked PII, or a cross-tenant read that is
  possible in a query.
- An unreproducible-but-real P0 from QA.
- A must-pass test-plan row with no passing test.
- A check that could not run. **Fail closed** — a check that did not run has
  proven nothing, and reporting it as n/a is the most expensive lie available.

**FIX-FIRST** on:

- Any High finding.
- A broken guardrail: a breaking change with no coexistence path, a migration
  with no tested rollback, a flag left ON by default.
- A P1 QA finding with no regression test.

**SHIP** otherwise. Quality and structure findings below High are optional and
go to the hardening backlog with tickets.

## Honesty requirements

- **A clean report is a suspicious report.** If nothing was found anywhere,
  either the environment was broken or the checks were too timid. Say which.
  Do not present emptiness as quality.
- **Report skipped work as skipped**, explicitly, in section 3 or 4 — never
  omitted, never softened into "not applicable".
- **State confidence.** Where you are unsure a finding is real or a fix is
  right, say so and let the user decide. Self-approving past uncertainty is the
  failure this gate exists to prevent.
- No "should work". Evidence or `not-verified`; there is no third state.

## Pass criteria

- [ ] Verdict stated, with its deciding sentence.
- [ ] Every DoD item has evidence or is listed as not-verified.
- [ ] Zero Critical; zero High, or the user has explicitly accepted each one.
- [ ] QA converged (two rounds with no new P0/P1) or the non-convergence is reported with
      the stop rule that fired.
- [ ] The gaps section names what was not looked at.
- [ ] The user has read it and released the MR.

## After the gate

→ Phase 7. Anything accepted rather than fixed becomes a backlog ticket before
the MR is opened, not after.
