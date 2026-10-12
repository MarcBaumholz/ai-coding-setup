# Test plan — <feature>

## Gates
All **Must** rows passing · new-code branch coverage ≥ <x>% · suite runtime ≤ <y>s.
Fail-closed: a check that could not run is a FAIL, never n/a.

## Case catalogue
Layer: U=unit · I=integration · E=browser E2E · V=offline eval.

| # | Case | Generator | Layer | Expected observable outcome | Must/Should/Could |
| --- | --- | --- | --- | --- | --- |
| T1 |  | happy path | E |  | Must |

Generators: happy path · equivalence classes · boundaries · error paths ·
permissions (allow AND deny) · idempotency/concurrency · state machine ·
persistence/restart · time & timezone · content (unicode, 10k chars, injection) ·
scale (0/1/1000, pagination) · failure injection · regression · adversarial.

## Coverage map — every DoD item has a Must case
| DoD | Cases |
| --- | --- |

## Not covered, deliberately
| What | Why | Risk accepted |
| --- | --- | --- |
