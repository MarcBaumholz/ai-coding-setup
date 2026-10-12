# Lane catalogue

Reusable lanes. They are **feature-agnostic shells** — the charter fills each one with the
concrete steps for whatever is shipping. Pick the lanes that apply; running all seven on a
small change is waste, and running only L1 is theatre.

Each lane is one `qa-explorer`, fresh context, ~40 actions, running in parallel with the
others. Lanes must not depend on each other's state.

---

## L1 · Job to be done

Can the persona finish the job the feature exists for, start to finish, without a
workaround? Not "does the button work" — **does the outcome arrive**.

Ends at the _user's_ definition of done, which is usually one surface further than
engineering's. For knowledge: not "the document uploaded" but "a coachee got an answer
grounded in it".

State the job as a sentence in the charter and make the lane prove or disprove that
sentence.

## L2 · Boundary and volume

The values nobody demoed with:

- **Nothing** — zero documents, empty summary, empty query, whitespace only.
- **One** — off-by-one lives here; plural strings say "1 coaches".
- **The documented cap, and one past it** — 400 chunks, the char limits, `maxlength`.
- **Absurd** — a 10 MB file, a 50k-character paste, a 300-character filename.
- **Hostile encodings** — emoji, RTL text, `<script>`, `../../etc/passwd`, a filename
  containing the app's own delimiters.

For each: does it fail _closed and legibly_, or silently truncate and lie? A cap enforced
without being named is the same bug as no cap.

## L3 · Cross-surface consistency

**CoachBot's signature bug class.** Take one object and ask every surface that describes it
the same question, then diff the answers.

For a knowledge document that is: a list row, a detail header, a Usage row, a chunk count,
a coach's attachment panel, and a coachee's source citation — six places, and they are
computed by different code with different predicates.

Report any disagreement, and say **which one is right**, because the fix is to make the
wrong one agree, not to average them.

## L4 · Lifecycle and staleness

Objects here have versions and the UI usually shows the wrong one:

- Change a draft → does the coachee-facing side still show the old value? _Should_ it?
- Publish → does everything catch up, including things mirrored at publish time?
- Replace a document version → do the old chunks stop being reachable?
- Re-index, delete, detach, restore → does each one fully take effect, or leave residue on
  the published version?

The question is always: **is the stale state visible and explained, or just stale?**

## L5 · Permissions and tenancy

- Put another tenant's org / project / resource id in the URL. Expect a refusal, not data.
- Reach the same route as a lower-privileged user. UI gating hides; the server must refuse.
- Find a read that uses the wide permission where the narrow one belongs (`chat_view` vs
  `view`) — an authoring surface a coachee can read is a finding.

Read-only probes. Never attempt privilege escalation against anything non-local.

## L6 · Resilience and honest degradation

Break a dependency and watch what the user is told:

- Flag off → the whole surface should vanish coherently, not half-render.
- Kill Redis or SpiceDB → does the page degrade or explode?
- A dependency that fails soft: is the failure **distinguishable from an empty result**?
  "No passages found" for an outage and for an off-topic question is the bug.

Restore whatever you stopped. Note in the report that you did.

## L7 · Adversarial content

The system ingests untrusted documents and shows them to a model:

- A document containing "Ignore your previous instructions…" — does it change coach
  behaviour?
- A document containing the app's own fence delimiters — can it escape the quoted region?
- The same payload in the **filename**, which is interpolated into the same prompt.
- Content that renders as markup in the UI — stored XSS in a chunk preview or a summary.

Report the _observable_ — what the coach said, what the DOM contained — not a theory.

---

## Severity

|              |                                                                                              |
| ------------ | -------------------------------------------------------------------------------------------- |
| **P0**       | Data loss, a tenancy or auth hole, or a **silent wrong answer to a coachee**. Ship-blocking. |
| **P1**       | The feature's main job fails, or a surface actively misleads the person configuring it.      |
| **P2**       | Rough edge, cosmetic, awkward copy.                                                          |
| **question** | Cannot tell whether it is intended. Say so; do not inflate it to P1 to be safe.              |

A silent wrong answer outranks a crash. A crash is honest.
