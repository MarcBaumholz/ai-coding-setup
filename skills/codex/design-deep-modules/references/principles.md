# Source-grounded principles

## Coverage and source

- Exact local source: `~/reading-sources/[local reading source]`
- Local file: 210 PDF pages; TOC includes Chapters 1-21, "Summary of Design Principles," and "Summary of Red Flags."
- TOC inspected at PDF 5-12: complexity; tactical/strategic programming; deep modules; information hiding; generality; layered abstractions; pulling complexity downward; grouping; error design; design twice; comments; names; existing code; consistency; obviousness; trends; performance.
- Representative direct inspection: Chapters 2-5, PDF 19-55; Chapters 8-9, 71-82; Chapters 10-12, 91-115; names/comments/existing-code material, 137-159; performance/conclusion, 185-199.
- Selective inspection, not cover-to-cover. The author explicitly describes the book as opinionated and advises rejecting techniques that do not reduce complexity.

## Durable models

| Model | Status | Mechanism | Coding consequence | Limitation / anchor |
|---|---|---|---|---|
| Complexity symptoms | Author claim | Complexity appears as change amplification, cognitive load, and unknown unknowns. | Review how many places, concepts, and surprises a representative change touches. | Metrics are qualitative and context-dependent; Ch. 2, PDF 19-26. |
| Dependencies plus obscurity | Author claim | Complexity grows when dependencies are numerous/unclear and important knowledge is hidden accidentally. | Make dependencies explicit or eliminate them; expose intent while hiding mechanism. | Some dependencies are essential domain facts; Ch. 2. |
| Strategic programming | Author claim | Small continuous design investment prevents tactical patches from compounding. | Improve the local boundary while delivering, within scope. | Deadlines can justify deliberate debt with a repayment trigger; Ch. 3. |
| Deep modules | Author claim | A small interface hides substantial useful functionality. | Judge abstraction value by hidden complexity relative to interface cost. | A small function can still be appropriate; Ch. 4, PDF 34-43. |
| Information hiding | Author claim | Keep design decisions inside one module so changes do not ripple. | Co-locate knowledge and test behavior at the boundary. | Hiding does not mean undocumented magic; Ch. 5, PDF 44-55. |
| Pull complexity downward | Author claim | A module implementer absorbs recurring complexity so many callers stay simple. | Prefer good defaults and internal policy over repeated caller choreography. | Operators may need controls; avoid burying observability or safety; Ch. 8, PDF 71-78. |
| Different layer, different abstraction | Author claim | Adjacent layers should add meaning rather than forward calls unchanged. | Challenge pass-through methods, wrappers, and duplicated interfaces. | Adapters for compatibility, security, or observability may be legitimate. |
| Define errors out of existence | Author claim | Redesign semantics so normal cases do not require exceptional handling; aggregate where appropriate. | Reduce caller branches and cleanup paths. | Do not mask corruption, security, or actionable failure; Ch. 10, PDF 91-107. |
| Design it twice | Author claim | Comparing alternatives exposes assumptions and better boundaries. | Require two sketches before committing to consequential APIs. | Timebox for low-risk changes; Ch. 11, PDF 108-111. |
| Comments and names carry non-obvious design | Author claim | Precise names and comments describe abstraction, invariants, and why—not code syntax. | Document interface contract and cross-module decisions near code. | Executable tests remain necessary; Chs. 13-18, PDF 112-184. |

## Pairings and tensions

- Pair with *The Mythical Man-Month*: deep modules preserve conceptual integrity locally; a shared architecture keeps those modules coherent system-wide.
- Pair with *Designing Data-Intensive Applications*: DDIA provides unavoidable distribution and storage complexity that modules must represent honestly, not hide away.
- Pair with *The Effective Software Engineer*: invest in depth where change frequency and impact justify it; avoid elegant abstraction for low-value work.
- Tension with interview optimization: the shortest puzzle solution is rarely the deepest long-lived production interface.
