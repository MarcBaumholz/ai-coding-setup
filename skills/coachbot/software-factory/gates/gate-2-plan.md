# ★ Gate 2 · The plan doc — approved as one unit, before code

**Position**: after Phase 1, before the first contract commit. The owner approves the plan
doc: mock, assumptions, design, interface sheet, test catalogue, slices. A design you cannot
state the tests for has not been understood, and a test plan without a design tests whatever
got built. Structural mistakes found in review are expensive; found here they cost a comment.

## What you present

The link to the plan doc, and one line per open Decision-needed question with your default.
The doc carries everything else (`templates/plan-doc.md`). Do not repeat it in chat.

## Pass criteria

- [ ] The doc opens with a mock of the end result (UI: clickable mock + screenshot; no UI:
      end-state drawing + sample output).
- [ ] The assumptions-challenged table is non-empty, and every row has a challenger and a
      verdict. Open rows are Decision-needed questions.
- [ ] The blind challenger, two critics and both second-opinion engines ran on the plan (or
      each is listed `skip: <reason>`); the last round added no blocking finding, or the open
      block is a Decision-needed question.
- [ ] Every new module's interface is smaller than what it hides; dependencies point inward.
- [ ] Every index has its query; every multi-row invariant has a transaction boundary.
- [ ] Every write path is idempotent or documented as deliberately not.
- [ ] Tenant scoping is in the query, not only in a permission check.
- [ ] The threat table has no empty trust boundary.
- [ ] The interface sheet covers every symbol, route, test id and i18n key the tests touch.
- [ ] Every DoD item maps to at least one Must test case; every new permission has an allow
      and a deny case.
- [ ] Holdouts exist in `sealed/holdouts.md` and appear in the doc only as a count.
- [ ] At least two alternatives rejected in writing; hard-to-reverse decisions have an ADR.
- [ ] The owner approved; the doc revision is in `progress.md`.

## Automatic block

- A migration with no down path and no expand/contract plan.
- A UI gate with no server-side twin in the design.
- New PII or user-content columns with no masking plan.
- An interface with one implementation, no test double, and no stated reason.
- A design whose critic panel returned only "looks good" — that means the panel
  did not run properly. Re-run it with the requirement to state what was checked.

## After the gate

Any change to the design during Build that alters an answer above comes back
here. Discovering mid-build that the design is wrong is a normal, healthy
outcome — quietly deviating from it is not.
