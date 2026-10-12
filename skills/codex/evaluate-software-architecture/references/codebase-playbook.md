# Codebase playbook

## Invoke when

- choosing between monolith, modular monolith, services, events, or another style;
- a nonfunctional requirement is vague or unmeasured;
- component cycles or shared schemas undermine autonomy;
- an ADR lacks alternatives, consequences, or evidence;
- architecture drift needs an automated check;
- a proposal claims a style is “best practice.”

## Questions

### Before coding

- What decision must be made now, and what can remain reversible?
- Which 2-4 architecture characteristics actually differentiate options?
- What deployment, data, team, cost, compliance, and skill constraints exist?
- What current runtime evidence is available?

### During implementation

- Is the selected quality measurable by a scenario or threshold?
- Did I include the current design as an option?
- What static, dynamic, semantic, and data coupling does each option create?
- What is the cheapest spike or fitness function that reduces uncertainty?

### In code review

- Does the code preserve the ADR's dependency/data/operational constraint?
- Is a local design choice accidentally creating a new architecture quantum?
- Are failure, versioning, migration, and rollback consequences explicit?
- Is a fitness function testing the quality rather than a convenient proxy?

### After deployment

- Did the measured quality move toward its threshold?
- Which negative consequence appeared?
- Have assumptions, scale, team shape, or platform economics changed enough to revisit?

## Step-by-step codebase workflow

1. Trace representative use cases across code, data, processes, and teams.
2. Write a decision statement and list hard constraints.
3. Rank a small set of architecture characteristics with measurable scenarios.
4. Build an option matrix for current design plus credible alternatives.
5. Map static, dynamic, semantic, data, and operational coupling for the leading options.
6. Run one discriminating experiment or query.
7. Choose the option with the best contextual trade-off, not the highest generic score.
8. Record an ADR and add a fitness function only for a critical enforceable constraint.

## Compact example

Decision: keep checkout in a modular monolith or extract a service.

| Driver | Modular monolith | Service |
|---|---|---|
| atomic order/payment update | simple local transaction | saga/coordination required |
| independent deployment | limited | strong |
| team ownership | one team today | useful only after ownership split |
| operational complexity | low | higher |

Evidence: inspect deploy frequency and incident coupling; prototype the payment contract and measure failure behavior. With one team and critical atomicity, keep a module now and define a revisit trigger for independent ownership/deploy demand.

## Anti-patterns and counterexamples

- Selecting microservices from a generic scalability rating.
- Listing every quality as “high priority.”
- Ignoring shared data while claiming service autonomy.
- Writing an ADR with only the chosen option.
- Adding dashboards or dependency tools without a decision they govern.
- Treating modularity as folder names rather than contained change.

## Selected now implementation node

- **Learning:** architecture decisions become useful when drivers are measurable and trade-offs contextual.
- **Coding impact:** teams can choose and enforce the smallest structure that satisfies the real qualities.
- **Package:** skill plus direct decision artifact.
- **Trigger:** a structural choice with long-lived or cross-team consequences.
- **Artifact:** one option matrix, one evidence result, and one concise ADR.
- **First step:** write the decision and rank the 2-4 differentiating characteristics.
- **Evidence:** a code/runtime query or spike discriminates between leading options; ADR records negative consequences and revisit trigger.
- **Priority:** now for consequential decisions.

## Ready-to-copy project instruction

> For consequential architecture decisions, rank no more than four differentiating quality drivers, compare the current design with credible alternatives, gather one discriminating piece of code or runtime evidence, and record consequences plus a revisit trigger in an ADR.
