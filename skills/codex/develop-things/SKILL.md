---
name: develop-things
description: Use for any software development task. Routes work through doc-first review, minimal implementation, and verification before completion.
---

> Published copy of a local skill. See [export notes](../../README.md) and the manifest for sources, edits and dependencies. Project helpers, plugins and agent definitions may be required.


# Develop Things

Use this skill for feature work, bug fixes, refactors, and implementation planning.

## Workflow

1. Understand the request and the existing code or docs that matter.
2. If the decision is architectural, cross-cutting, or ambiguous, use a docs-first grilling step before coding.
3. Implement the smallest correct change.
4. Prefer existing code, stdlib, native platform features, and deletion over new abstractions.
5. Verify with a focused test or runnable check before claiming done.
6. Update docs or ADRs when the change affects a documented contract.

## Defaults

- Use the `ponytail` mindset for implementation: shortest safe diff, no unnecessary scaffolding.
- Use `grill-with-docs` for plan and design pressure before code when needed.
- Use `superpowers` verification habits before completion.
- Keep explanations short unless the user explicitly asks for detail.
