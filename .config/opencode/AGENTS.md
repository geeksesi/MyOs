# Background subagents

Whenever any agent delegates work with the `task` tool, it MUST pass `background: true`. Never launch a subagent with `background: false`. Wait for the automatic completion notification, and never sleep or poll for task completion.
