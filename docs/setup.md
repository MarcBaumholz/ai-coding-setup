# Tools and file locations

Paths use `~` for the home directory. This page describes the locations relevant to the selected coding workflow.

## Claude Code and CoachBot

```text
~/Documents/Coachbot_dev/
├── .claude/
│   ├── CLAUDE.md              Working rules and skill routing
│   ├── AGENT_OS.md            Review process and agent roles
│   ├── skills/                Shared project skills
│   └── agents/                Agent definitions
├── coachbot-monorepo/
│   ├── CLAUDE.md              Codebase context
│   ├── .claude/rules/         Rules for specific areas
│   ├── .claude/skills/        Project commands
│   └── docs/architecture/     Architecture decision records
└── Tasks/                     Requirements, plans and progress

~/.claude/skills/              Global skill entries and symlinks
~/.claude/agents/              Linked agent definitions
~/.claude/plugins/             Plugin installation metadata
```

The parent workspace holds much of the working process. Global symlinks make those skills available to Claude Code under the local loading rules. Looking only inside the Git checkout would miss them.

Keeping shared instructions outside the repository lets them survive checkout changes. Parallel implementation still needs separate worktrees or clear file ownership, and separate ports where required.

## Codex

| Location | Purpose |
| --- | --- |
| `~/.codex/AGENTS.md` | Global user instructions |
| `~/.codex/skills/` | Locally installed skills |
| `~/.codex/skills/.system/` | Platform system skills |
| `~/.codex/plugins/cache/` | Versioned plugin bundles |

The published folders under `skills/codex/` are selected copies. The rest of the installed collection is outside this repository.

## Project tools

The CoachBot instructions name pnpm/Turborepo, TypeScript, Svelte, database migrations and GitLab merge requests. They also refer to browser tools, code graphs and observability tools.

For another stack, I would replace the commands and review roles while keeping the basic steps: understand the task, make a suitable change and check the result.

## Using skills across tools

Claude-specific plugins, agent types and hooks need their matching runtime. Reading a Claude skill in Codex does not establish that its commands can run there.

The Codex skill `develop-things` provides a short process: understand the task, clarify larger decisions, make a small change and check it. Larger workflows depend on the project's instructions and tools. Private design-system files remain outside the public export.
