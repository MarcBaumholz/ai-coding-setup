# Source-grounded principles

## Coverage and source status

- Local source: `[local reading source]`
- Edition: first edition, 1999; 337 physical PDF pages.
- Inspected: contents and preface; PDF pp. 13-45 (first example); pp. 46-62 (principles); pp. 63-72 (smells); pp. 73-84 (tests); pp. 85-105 (catalog framing and composing methods); and representative catalog entries.
- Coverage claim: selective inspection of the method and core catalog, not cover-to-cover verification. Examples predate modern IDEs, languages, and distributed systems.

## Durable models

### 1. Preserve observable behavior

- **Author claim:** refactoring changes internal structure without altering external behavior (Preface; Ch. 2, PDF pp. 46-62).
- **Mechanism:** a fixed behavioral contract lets structure evolve independently.
- **Coding consequence:** name the invariant before editing and distinguish structural from semantic changes.
- **Limitation:** “observable” includes timing, queries, events, logs, errors, and compatibility where consumers rely on them.

### 2. Improve design continuously

- **Author claim:** design can improve after code is written through repeated small transformations (Chs. 1-2).
- **Mechanism:** local feedback turns design from a one-time prediction into an evolutionary activity.
- **Coding consequence:** refactor near an active change rather than scheduling speculative redesigns.
- **Limitation:** widespread architectural constraints may need an explicit migration, not an endless sequence of local edits.

### 3. Use two hats

- **Author claim:** alternate between adding behavior and restructuring, but do not do both simultaneously (Ch. 2).
- **Mechanism:** a single change dimension makes failures diagnosable.
- **Coding consequence:** create separate steps or commits for behavior and structure where practical.
- **Limitation:** tiny preparatory refactors inside a feature branch are normal; the important boundary is conceptual and testable.

### 4. Small steps are a risk-control system

- **Author claim:** apply mechanics in small steps and test frequently (Chs. 1-2; catalog).
- **Mechanism:** small deltas reduce the search space when behavior changes.
- **Coding consequence:** use IDE/compiler-assisted moves, then run the narrow test after each conceptual transformation.
- **Limitation:** mechanical safety does not verify reflection, serialization, dynamic lookup, deployment contracts, or concurrency.

### 5. Smells are prompts, not verdicts

- **Author claim:** duplicated code, long methods, large classes, divergent change, shotgun surgery, feature envy, and other smells suggest refactoring (Ch. 3, PDF pp. 63-72).
- **Mechanism:** smells point to friction between code structure and change patterns.
- **Coding consequence:** connect a smell to a real change cost before acting.
- **Limitation:** generated code, parsers, performance kernels, declarative tables, and cohesive domain algorithms can resemble smells without being problems.

### 6. Tests enable structural freedom

- **Author claim:** solid, self-checking tests are a precondition for refactoring (Ch. 4, PDF pp. 73-84).
- **Mechanism:** rapid regression feedback makes incremental change affordable.
- **Coding consequence:** test the behavior at the narrowest stable boundary that still sees the risk.
- **Limitation:** a passing unit suite may miss persistence, network, concurrency, and deployment behavior.

### 7. Compose methods around intent

- **Author claim:** extraction, inlining, explaining variables, and related moves make methods communicate purpose (Ch. 6, PDF pp. 89-105).
- **Mechanism:** intention-revealing units separate policy from detail.
- **Coding consequence:** extract when the new name removes a concept a reader otherwise reconstructs.
- **Limitation:** indirection can make simple logic harder to follow; inline abstractions that no longer carry meaning.

### 8. Refactoring catalog entries are recipes

- **Author claim:** each refactoring has a motivation and mechanics, and larger changes compose from them (Chs. 5-12).
- **Mechanism:** named transformations provide shared vocabulary and repeatability.
- **Coding consequence:** describe actual moves such as Rename, Extract Function, Move Function, or Replace Conditional rather than “clean up.”
- **Limitation:** use current language/IDE recipes; the first-edition catalog is not exhaustive or concurrency-aware.

## Synthesis and modern application

Safe refactoring is an evidence loop: invariant -> one transformation -> check -> inspect. The quality signal is not fewer lines or more patterns; it is lower cost for the next relevant change without a behavioral regression.

## Conflicts and pairings

- Pair with *Working Effectively with Legacy Code* when tests are absent or dependencies prevent isolation.
- Pair with *Clean Code* for candidate readability problems, but let change friction and evidence overrule prescriptive size rules.
- Pair with *A Philosophy of Software Design* when deciding whether to extract or deepen a module; not every long method benefits from more interfaces.
- Pair with architecture books only after identifying a cross-component constraint; refactoring alone cannot safely redefine distributed contracts.
