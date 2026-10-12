# Codebase playbook

## Invoke when

- A simple change touches many files or callers.
- Callers repeat ordering, retries, validation, conversion, or cleanup.
- A class mostly forwards methods or exposes configuration for internal decisions.
- An API emits many special-case errors.
- Names and comments do not reveal invariants or ownership of knowledge.

## Questions

### Before coding

- What change path demonstrates the current complexity?
- Which facts are stable domain concepts, and which are implementation choices?
- Who must know each decision today?
- What two materially different boundaries could solve this?

### During implementation

- Did the interface get smaller or merely more indirect?
- Is recurring complexity handled once at the lowest sensible layer?
- Are errors actionable at this boundary?
- Is configuration enabling a real user choice or exporting indecision?

### Code review

- Can a caller use the module without learning its internals?
- Does every layer add an abstraction?
- Are names precise and comments explaining contract, invariant, or why?
- Did general-purpose mechanism become contaminated with one caller's policy?

### After deployment

- Did the next representative change touch fewer places?
- Did callers add escape hatches or bypass the module?
- Are errors and operational controls still observable?

## Step-by-step workflow

1. Search definitions, callers, tests, configuration, errors, and relevant changes.
2. Write a complexity ledger for one change: touched sites, concepts required, surprises, leaked decisions.
3. Sketch two interfaces and sample caller code before implementation.
4. Compare hidden complexity, interface surface, policy/mechanism split, failures, performance, and migration.
5. Implement the smallest vertical slice; retain compatibility if needed.
6. Add interface-level tests and a precise contract comment.
7. Re-run the representative caller/change and report what complexity remains.

## Compact example

Before, every endpoint calls `validate`, `begin`, `write`, `commit`, catches three exceptions, and conditionally retries.

Alternative A adds a helper that forwards all six operations. Alternative B exposes `store.save(record, idempotency_key)` and owns validation, transaction lifecycle, safe retry, and error translation.

Select B only if the policy is shared. Test atomicity, duplicate keys, validation, and translated failures. The caller now expresses intent rather than protocol. Keep low-level diagnostics in logs/causes so complexity is hidden from callers, not erased from operators.

## Anti-patterns and counterexamples

- Do not equate more classes with better decomposition.
- Do not wrap an interface without adding meaning.
- Do not create a generic framework for hypothetical callers.
- Do not catch every exception and return success.
- Counterexample: an explicit timeout or durability setting is appropriate when callers genuinely own different SLO/cost decisions.

## Selected now implementation node

- Learning: measure module depth by how much recurring knowledge the interface hides.
- Coding impact: reduces change amplification and caller cognitive load.
- Package: direct code/refactor plus boundary tests.
- Trigger: repeated multi-step caller choreography in at least two real call sites.
- Artifact: two interface sketches, one bounded deep-module refactor, and caller before/after.
- First step: trace one representative change and list decisions every caller currently repeats.
- Evidence: fewer required caller concepts and touched sites, with boundary tests preserving behavior.
- Priority: now.

## Ready-to-copy project instruction

> For consequential module or API changes, trace a representative caller and sketch two boundaries. Prefer the design that hides recurring decisions behind a small, testable interface while retaining necessary observability; do not add abstraction without demonstrated reduction in change amplification or cognitive load.
