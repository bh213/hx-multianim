---
name: precommit
description: Run pre-commit documentation and code hygiene checks before committing. Reviews changes since last commit, updates changelog/docs/todos, checks for missing items, and suggests a commit message.
---

# Pre-Commit Checks

Perform the following pre-commit workflow. Report findings concisely.

## 1. Review Changes

- Run `git log --oneline -5` to see recent commits
- Run `git diff --stat HEAD` to see changed files
- Run `git diff HEAD` to see the full diff
- Analyze all changes to understand what was added/changed/fixed

## 2. Update CHANGELOG.md

- Read `CHANGELOG.md` and check if any changes in the diff are NOT yet documented
- Add entries for new features, fixes, and breaking changes under the current dev version section
- Follow the existing format (bullet points with bold feature name and description)

## 3. Update Documentation

- Check if changes affect `.manim` syntax or builder/codegen API
- If so, update `docs/manim-reference.md` (quick-lookup reference)
- If substantial, also update `docs/manim.md` (detailed documentation)
- Update `CLAUDE.md` if architectural patterns or key instructions changed

## 4. Clean Up TODO Files

- Read `todo/TODO.md` and other `todo/*.md` files
- Remove items that have been completed (check against CHANGELOG and recent commits)
- Do NOT remove items that are still pending or in-progress

## 5. Check for Missing Items

Verify:
- No sensitive files (.env, credentials) in the diff
- All reference images updated if visual tests changed
- No inconsistencies between code changes and documentation
- MEMORY.md is up to date with any new patterns or pitfalls discovered. 
- Check if anything can be removed from MEMORY.md because it is no longer relevant. Ask user if unsure.

## 6. Suggest Commit Message

- Follow the project's commit message style (see recent commits)
- Format: `area: short description` on first line
- Add bullet points for significant changes in the body
- Keep the first line under 72 characters
- Do not include TODO file changes.

## 7. Report Summary

Present a summary table:
- Files changed (count)
- Changelog entries added
- Docs updated
- TODOs cleaned
- Any issues found
- Suggested commit message

Do NOT create the commit at all. Present the summary and user will commit.
