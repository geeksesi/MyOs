---
description: Analyze git changes and create well-organized commits.
---

Analyze the current git changes and create a clean series of logical commits. Follow these rules strictly:

1. Run `rtk git status`, inspect staged and unstaged diffs, and run `rtk git log --oneline -10` to learn the repository's commit style.
2. Review every modified, deleted, and untracked file before staging anything. Never add ignored files, secrets, generated junk, or unrelated files.
3. Build a commit plan based on purpose, not convenience:
   - Put files and changes that implement one purpose in the same commit.
   - Put unrelated features, fixes, refactors, tests, docs, configuration, and cleanup in separate commits.
   - Do not create one catch-all commit when the work contains multiple logical changes.
   - A file may belong to more than one commit. If it contains unrelated edits, split its hunks and stage only the hunks for the current commit.
   - Keep an implementation together with its directly related tests, types, migrations, or documentation when they form one atomic change.
   - Each commit must be independently understandable and should not knowingly leave the repository in a broken state.
4. For each planned commit:
   - Clear or adjust the index as needed without discarding working-tree changes.
   - Stage only that commit's files or hunks using `rtk git add <paths...>` or an appropriate non-interactive patch method.
   - Inspect the staged diff and confirm it contains the whole intended change and nothing unrelated.
   - Commit with a short, descriptive, single-line conventional message using one of: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `style:`, `test:`, `perf:`, `ci:`, `build:`.
   - Do not add a description body or `Co-Authored-By` line.
5. Repeat until every committable change is included in the correct logical commit. Multiple commits are welcome and preferred whenever there is more than one purpose.
6. Finish by running `rtk git status` and `rtk git log --oneline -10`. Report the commits created and clearly list anything intentionally left uncommitted.

Do not ask for confirmation. Analyze the changes, separate them by purpose, and commit them.
