# ★ Gate 1 · Scope — one screen in chat, before the plan

**Position**: after Phase 0, before Phase 1 spends its time on a plan. This is the cheap yes:
it exists so a full plan never gets built for the wrong thing, or for a thing that already
exists. chat-pwa-install approved a complete design for a feature already sitting on a branch
(`Tasks/chat-pwa-install/04-existing-branch.md`).

## Premise check — before presenting anything

Is this already built, half-built, or in flight? Run each, paste what came back:

```bash
python3 ~/project-workspace/.claude/scripts/ctx.py          # Tasks/ in flight
git branch -a --list '*<keyword>*'; git log --all --oneline -i --grep '<keyword>' | head
~/.claude/scripts/wt-files.sh <the main path you expect to touch>
```

Plus `semantic_search_nodes_tool` for the concept under two or three names (the PWA work sat
under a different name than the request used). A script cannot decide "already built"; you
decide, from this output, and say so in one line.

## What you present — one screen, in chat

1. **The job** — one paragraph in the owner's language. Who, doing what, why.
2. **What gets built** — 3-7 bullets. **What explicitly does not** — specific.
3. **Premise** — the one-line verdict and its evidence.
4. **The reference**, if this is "copy this from that": its path or URL. Without one there is
   no parity phase.
5. **Leverage** — is there a cheaper way to 80 % of the outcome?
6. **Blocking questions** — 0-3, each with your default.

## Pass criteria

- [ ] The premise check ran and its output is in `progress.md`.
- [ ] The out-of-scope list is non-empty and specific.
- [ ] The owner said yes in this conversation.

## After the gate

Record the yes and the date in `progress.md`. Create the Linear ticket via `/create-issue`.
A scope change later comes back here; it is a new gate, not a note.
