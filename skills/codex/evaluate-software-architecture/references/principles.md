# Source-grounded principles

## Coverage and source status

- Local source: `[local reading source]`
- Edition: second edition, March 2025; 981 physical PDF pages.
- Inspected: preface and PDF pp. 20-27 (definition/context); pp. 107-159 (architecture characteristics); pp. 169-183 (governance/fitness functions); pp. 185-210 (architecture quantum and components); representative architecture-style chapters; pp. 650-722 (teams/decisions and ADR material); and pp. 868-883 (trade-off analysis).
- Coverage claim: selective inspection of a large survey/reference work, not cover-to-cover verification. Style assessments are comparative heuristics, not universal scores.

## Durable models

### 1. Architecture has several interacting dimensions

- **Author claim:** architecture combines structure/style, architecture characteristics, logical components, and decisions (Ch. 1, PDF pp. 20-27).
- **Mechanism:** a topology only makes sense alongside behavior, desired qualities, and rationale.
- **Coding consequence:** trace one use case through components and deployment before evaluating a style.
- **Limitation:** the model is a lens, not an exhaustive definition of organizational or data reality.

### 2. Context determines architecture

- **Author claim:** architectures are products of technical, economic, and organizational context (Preface/Ch. 1).
- **Mechanism:** changed infrastructure and engineering capabilities alter viable trade-offs.
- **Coding consequence:** include platform, team, compliance, cost, and delivery constraints in every recommendation.
- **Limitation:** “it depends” is not a decision; context must narrow options and lead to evidence.

### 3. Architecture characteristics are differentiating requirements

- **Author claim:** identify qualities such as availability, security, scalability, testability, and deployability that influence structure (characteristics chapters, PDF pp. 107-159).
- **Mechanism:** explicit quality scenarios reveal why structural choices are needed.
- **Coding consequence:** define stimulus, environment, response, and measurable threshold for the few qualities that distinguish options.
- **Limitation:** characteristics conflict, and labels like “agility” may be composites too vague to test.

### 4. Govern with fitness functions

- **Author claim:** automated objective integrity checks protect architecture characteristics (PDF pp. 169-183).
- **Mechanism:** executable feedback catches drift earlier than review boards.
- **Coding consequence:** encode a critical constraint as a dependency test, SLO check, security policy, benchmark, or chaos/recovery check.
- **Limitation:** not every quality is fully automatable; proxy metrics can incentivize the wrong behavior.

### 5. Modularity is measurable change containment

- **Author claim:** cohesion and coupling help define components and maintain modularity.
- **Mechanism:** well-chosen boundaries localize change and reduce coordination.
- **Coding consequence:** inspect dependency cycles, shared data, change history, and ownership before decomposing.
- **Limitation:** low static coupling can hide runtime, semantic, or data coupling.

### 6. Architecture quantum defines independent change scope

- **Author claim:** an architecture quantum combines independent deployability, high functional cohesion, and synchronous connascence (PDF pp. 185-198).
- **Mechanism:** these forces reveal what must deploy and fail together.
- **Coding consequence:** map synchronous calls and shared transactions/data before claiming service independence.
- **Limitation:** independent deployment is not always a business goal; a modular monolith may optimize delivery better.

### 7. Style selection is a constraint match

- **Author claim:** layered, modular monolith, microkernel, service-based, event-driven, space-based, microservices, and other styles offer different characteristic profiles.
- **Mechanism:** topology enables some qualities while taxing others.
- **Coding consequence:** compare only viable styles against prioritized drivers, data, skills, and operations.
- **Limitation:** systems are often hybrids; generic ratings cannot replace domain scenarios or current platform evidence.

### 8. Data and team topology intersect structure

- **Author claim:** data ownership and team organization influence architectural boundaries and governance (second-edition additions).
- **Mechanism:** shared schemas and cross-team ownership create coupling even when code is separated.
- **Coding consequence:** put data stores, contracts, deployment ownership, and coordination paths on the architecture map.
- **Limitation:** Conway's Law describes pressure, not destiny; reorganizing teams can be more expensive than accepting coupling.

### 9. Record decisions and consequences

- **Author claim:** ADRs preserve context, decision, consequences, and rationale (decision chapters, PDF pp. 700-722).
- **Mechanism:** future teams can distinguish deliberate constraints from accidents.
- **Coding consequence:** make ADRs small, decision-specific, linked to evidence, and explicit about negative outcomes.
- **Limitation:** ADRs decay without ownership and revisit triggers; documentation is not enforcement.

### 10. The second law: why matters more than how

- **Author claim:** architects must understand why a decision exists; everything is a trade-off (trade-off material, PDF pp. 868-883).
- **Mechanism:** rationale permits adaptation when assumptions change.
- **Coding consequence:** lead recommendations with the decisive driver and rejected alternatives, not implementation mechanics.
- **Limitation:** rationale still needs delivery detail and an accountable owner.

## Synthesis and modern application

Architecture work should end in a falsifiable decision: a small set of prioritized qualities, a contextual option comparison, one piece of evidence, and an ADR/revisit trigger. Avoid turning a survey taxonomy into a checklist that every system must satisfy.

## Conflicts and pairings

- Pair with *Software Architecture: The Hard Parts* when coupling, transactions, data ownership, or distributed workflows dominate the choice.
- Pair with *Clean Architecture* for source dependency direction, but evaluate its extra mapping and abstraction as explicit trade-offs.
- Pair with *Designing Data-Intensive Applications* to test consistency, replication, partitioning, and stream-processing assumptions.
- Pair with *Team Topologies* when organizational cognitive load and ownership are primary constraints.
