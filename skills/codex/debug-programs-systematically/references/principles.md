# Source-grounded principles

## Coverage and limits

- Source: `[local reading source]` by Andreas Zeller, 2006 edition.
- Inspected directly: contents/preface, PDF pp. 11-28; failure model, pp. 31-55; reproduction, pp. 116-145; simplification and scientific debugging, pp. 147-196; observation, origin tracking, assertions, and anomalies, pp. 229-346; cause isolation and fixing, pp. 347-431.
- This is selected whole-method coverage, not cover-to-cover verification. Specific tools and language examples are dated; the causal method remains useful. Modern distributed, async, and cloud failures need trace IDs, replayable events, feature/config snapshots, and concurrency-aware experiments.

## Durable models

### 1. Defect -> infection -> propagation -> failure

- **Author claim:** A defect creates an incorrect internal state that propagates until externally observable (ch. 1, PDF pp. 31-55).
- **Synthesis:** The failing line is often downstream from the causal transition.
- **Coding consequence:** Identify the earliest wrong value/state, then trace its origins.
- **Limitation:** Races and distributed interactions may have multiple jointly sufficient causes.

### 2. Reproduction is controlled causality

- **Author claim:** Adopt and vary failure circumstances systematically until the problem is reproducible (ch. 4, pp. 116-145).
- **Synthesis:** A reproducer is an executable statement of the failure, not merely steps in prose.
- **Coding consequence:** Freeze version, input, environment, time, randomness, dependencies, and schedule where possible.
- **Limitation:** Instrumentation and replay can perturb timing-sensitive faults.

### 3. Simplify while preserving the failure

- **Author claim:** Reduce input and circumstances using automated tests such as delta debugging (ch. 5, pp. 147-174).
- **Synthesis:** Every removed irrelevant factor increases explanatory power.
- **Coding consequence:** Build a binary oracle, then minimize payload, configuration, commit set, or event trace.
- **Limitation:** A flaky oracle makes automated reduction misleading.

### 4. Debug with falsifiable hypotheses

- **Author claim:** Observe, hypothesize, predict, experiment, conclude (ch. 6, pp. 175-196).
- **Synthesis:** "Maybe caching" is not a hypothesis until it predicts a discriminating observation.
- **Coding consequence:** Keep a short hypothesis log and change one variable per experiment.
- **Limitation:** Urgent containment may require a reversible mitigation before causal proof.

### 5. Observe facts, not stories

- **Author claim:** Debuggers, logs, traces, and visualization expose program facts (ch. 8, pp. 229-242).
- **Synthesis:** Add the smallest observation that separates hypotheses; more logging can add noise.
- **Coding consequence:** Capture identifiers, boundaries, inputs/outputs, timestamps, and state transitions with privacy and cost controls.
- **Limitation:** Absence from logs is not proof of absence if coverage is incomplete.

### 6. Track origins backward

- **Author claim:** Follow dependencies from the infected value toward its origins using slices or equivalent reasoning (ch. 9, pp. 243-286).
- **Synthesis:** Backward dataflow sharply narrows the search surface.
- **Coding consequence:** Trace definitions, callers, serialization, transformations, and writes that can influence the bad state.
- **Limitation:** Reflection, shared state, external services, and concurrency weaken static dependency models.

### 7. Turn expectations into executable invariants

- **Author claim:** Preconditions, postconditions, and invariants detect infections closer to their origin (ch. 10, pp. 287-324).
- **Synthesis:** Earlier detection shortens propagation distance.
- **Coding consequence:** Add boundary validation and assertions for states that must never occur; retain high-value checks in production when safe.
- **Limitation:** Assertions cannot replace recovery and must not expose secrets or cause unsafe outages.

### 8. Correlation ranks suspects; experiments establish cause

- **Author claim:** Passing/failing-run differences and anomalies can localize suspicious code, while cause isolation requires controlled change (ch. 11-14, pp. 325-413).
- **Synthesis:** Suspiciousness is a prioritization signal, not a verdict.
- **Coding consequence:** Use coverage/change/anomaly comparisons to choose the next experiment, then reproduce the effect by intervention.
- **Limitation:** Confounding changes can make a correlated line innocent.

### 9. Fix and verify at the causal boundary

- **Author claim:** Repair the defect, verify it, and preserve the failure as a test (ch. 15, pp. 414-431).
- **Synthesis:** A fix is incomplete without a once-failing oracle and adjacent regression checks.
- **Coding consequence:** Make the smallest causal patch; document why the test would fail before it.
- **Limitation:** Some defects expose a missing architectural invariant that deserves a broader follow-up, not a larger emergency patch.

## Pairing and tension

- Pair with *A Philosophy of Software Design*: deep modules and reduced complexity prevent infection propagation and make causal boundaries observable.
- Tension: refactoring for design quality during diagnosis changes multiple variables. First isolate and verify the defect; then schedule structural improvement separately.
