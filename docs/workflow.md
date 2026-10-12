# Working through a change

## Small fixes

For a clear fix with limited risk, I read the affected code and its callers, describe the expected behaviour and change the smallest useful part. Then I run suitable checks and review the diff.

The Ponytail approach helps keep the change small: check whether it is needed, look for an existing solution, try the standard library or a native feature, then consider dependencies or custom code. Necessary error handling and security checks remain part of the solution.

## Larger changes

For a new feature or a change that is hard to undo, I write down the scope, acceptance criteria and exclusions. I check assumptions about users, data, permissions, load and failure cases. A mock or realistic output example helps make the expected result concrete.

The CoachBot instructions include brainstorming and a `council` for open product questions. The council uses simulated user and specialist roles to question an idea. Their responses are hypotheses; real user research is still needed to test demand.

The plan describes interfaces and alternatives. Reviewers get enough context to assess it without inheriting the main conversation. After plan approval, a test author and a different implementer work on small slices. See the [factory guide](software-factory.md).

## Splitting work between agents

Each task brief names:

- the goal and expected result;
- the source files and current base;
- paths the agent may edit and paths it may only read;
- required checks and stopping conditions.

One agent owns each file. Overlapping changes run in sequence or in separate worktrees. The coordinating agent handles shared and generated files after the other work rejoins.

I use scripts for repeatable mechanical work. Separate agents are useful for independent reviews or tasks with clear boundaries.

## Review and QA

Compiler, lint, test and build checks come first. Reviewers then examine the risks in the affected areas: data, permissions, frontend, infrastructure, RAG or user flows. They report concrete failure cases and include `Checked` and `Not checked` sections.

For a second opinion, the reviewer starts from the original request and forms an expectation before reading the implementation. Using another model adds a different perspective, though it can still make mistakes.

Browser checks cover both acceptance criteria and exploratory testing. The report should name the environment, actions and observed results. A screenshot records a visible state; an interaction needs its own checks.

## CoachBot example

**Illustrative example:** closing a dialog should restore the previous view. This is not a report of a delivered feature.

1. Read the navigation and state handling. Define the views and return cases.
2. Choose a small fix if the change is contained. Use the longer process if persistence, permissions or multiple clients are involved.
3. Check the normal return path, loading failures, reloads and the relevant mobile flow.
4. Review the code and callers. Attach the results to the merge request.
5. Check merge, deployment and behaviour in the target environment as separate steps.

CoachBot uses GitLab for this work. This GitHub repository documents the setup.

## Applying it to MyAgent

The original request mentioned “MyAgent”, but the inspection could not match that name to a local project. This section is a proposal for applying the workflow elsewhere.

I would start by reading that project's instructions, runtime, interfaces and tests. For a request such as “add a tool to the agent”, I would define its schema, permissions, side effects, timeout, retry and cancellation behaviour. Then I would choose the checks and review effort for those risks.

Project-specific skills, CI and deployment details need an inspection of the actual repository.

## Improving the setup

The CoachBot instructions refer to an indexed mistakes log and focused searches of prior working notes. I use those notes to identify repeated problems in the workflow.

For repeated work, I choose the smallest useful change: a note, rule, skill, agent, hook or tool integration. An unattended run needs clear inputs, permitted actions, a time or round limit, and conditions for stopping or asking for help.

Instructions for recurring work describe the intended setup. Checking whether a scheduler is active is a separate task.
