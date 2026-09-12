---
description: Set up AI dev tools (speckit, Matt Pocock skills, ponytail) for this project.
agent: orchestrator
---

Set up the following AI development tools in this project. Work through each step in order. If a tool is already set up, skip it. Do NOT commit anything.

## 1. Check and install CLI prerequisites

Run these checks and install what's missing:

```bash
# uv (Python package manager — required by speckit)
command -v uv || echo "MISSING: uv"

# specify-cli (speckit)
command -v specify || echo "MISSING: specify-cli"
```

Install missing tools:
- **uv**: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **specify-cli**: `uv tool install specify-cli`

After installing, verify each `command -v` succeeds before continuing.

## 2. Spec Kit (github/spec-kit)

Initialize speckit in the current project for both agents:

1. Run `specify integration list` to see available integrations and find the exact IDs for opencode and claude.
2. Run `specify init . --integration opencode` to create the `.specify/` config and OpenCode command files. If `specify init .` is not valid for existing projects, check `specify --help` for the correct command.
3. Run `specify integration install claude` (or the correct command) to add Claude command files alongside the OpenCode ones. If no sub-command exists, manually check what files `specify init` created under `.opencode/command/` or `.claude/commands/` and ensure both agent directories have the speckit command files.

## 3. Matt Pocock skills (github.com/mattpocock/skills)

Set up the Matt Pocock engineering skills at project level. Install via ONE of the two methods below — installing both leaves you with every skill twice.

**OpenCode (and other non-Claude agents):**
- Run `npx skills@latest add mattpocock/skills`.
- Pick the skills you want and select the `opencode` coding agent when prompted. Make sure `setup-matt-pocock-skills` is one of the skills you take.
- This writes editable skill files into the repo as ordinary files you own; pull updates on demand with `npx skills update`.

**Claude Code:**
- Install the plugin from the official marketplace: `claude plugins install mattpocock-skills` (or `/plugin install mattpocock-skills` from inside a session). Updates arrive automatically.
- Alternatively, for editable files use the same installer as above: `npx skills@latest add mattpocock/skills` and select `claude`.

After install, run `/setup-matt-pocock-skills` once per repo to configure the issue tracker, triage labels, and doc layout.

## 4. Ponytail

Set up ponytail for Claude Code:

- In `.claude/settings.json`, add ponytail to enabledPlugins:
  ```json
  "ponytail@ponytail": true
  ```
  Merge into the existing `enabledPlugins` object.

## 5. Language Server (LSP)

Set up LSP configuration for OpenCode conditionally:
1. Check if the project uses TypeScript/JavaScript (e.g., look for `tsconfig.json`, `package.json` with TS dependencies, or `.ts`/`.js` files).
2. If TypeScript/JavaScript is detected, merge the following `lsp` configuration into the project's `opencode.json`:
   ```json
   "lsp": {
     "typescript": {
       "command": [
         "typescript-language-server",
         "--stdio"
       ],
       "extensions": [
         ".ts",
         ".tsx",
         ".js",
         ".jsx",
         ".mjs",
         ".cjs",
         ".mts",
         ".cts"
       ]
     }
   }
   ```
3. If not detected, do not add any LSP configuration.

## 6. Update .gitignore

Create or update `.gitignore` in the project root. Append the following entries (do not remove existing entries):

```gitignore
# Spec Kit
.specify/
specs/

# AI agent configs and tooling
.claude/
.opencode/
```

## 7. Report

After completing all steps, print a summary:
- Which tools were newly installed vs already present
- Which files were created or modified
- Any errors encountered and how they were resolved
- Remind the user to restart both OpenCode and Claude Code for project-level config to take effect
