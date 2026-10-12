# Parity ledger — <reference> → <target>

Frozen after round 0. Rows found later go to "Found later", never into the table.
Machine-readable copy: `Tasks/<slug>/parity/ledger.json` (array of rows below), which
`scripts/parity-diff.mjs` reads.

| id | type | what | probe | reference value | target value | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | copy | save button label | `document.querySelector('[data-testid=save]').textContent.trim()` | "Add stage" | | |

type: copy · state · interaction · layout · behaviour · visual. verdict comes from the
script: done · partial · missing · needs-human. A `visual` row is always needs-human.

## Found later
## Waived by the owner
