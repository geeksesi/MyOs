Analyze the current git changes and create well-organized commits. Follow these rules strictly:

1. Run `git status` and `git diff` to understand all changes (staged and unstaged).
2. Only stage files that are already tracked by git (modified/deleted). Never add untracked or gitignored files unless explicitly requested.
3. Group related changes together into logical commits. Multiple commits are allowed and encouraged when changes are unrelated.
4. For each group:
   - Stage only the relevant files using `git add <file1> <file2> ...`
   - Commit with a single-line message using conventional commit prefixes: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `style:`, `test:`, `perf:`, `ci:`, `build:`
   - Keep the commit message short and descriptive of what changed
   - Do NOT add `Co-Authored-By` line
   - Do NOT add a description body, only a single line
5. After all commits, run `git log --oneline -10` to show the results.

Do NOT ask for confirmation. Just analyze, group, and commit.
