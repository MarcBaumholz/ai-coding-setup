# Interface sheet — <feature>

What the tests will touch, and nothing about why. The test author writes against this; the
implementer may not change it (a needed change is a dispute row). Approved with the plan.

| Kind | Name | Shape | Errors / states |
| --- | --- | --- | --- |
| function | `packages/x/src/y.ts` `fn(actorId: UserId, id: ProjectId): Promise<Z>` | returns `Z` | throws `NotFoundError` |
| route | `POST /api/projects/[id]/thing` | body `{…}` → 201 `{…}` | 403, 404, 422 |
| DOM | `data-testid="thing-save"`, role `button`, name "Save thing" | — | disabled while saving |
| i18n | `thing.save` (en + de) | — | — |
| table | `things(id, project_id, …)` | — | unique `(project_id, name)` |

Stubs: one per function or route the contract tests call, each marked `factory:stub`,
returning a wrong value of the right type. Never a throw.
