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

## 5. Test Review

The test suite covers **three categories**:

1. **Visual tests** (numbered 1–95) — screenshot comparison of `.manim` rendering (builder vs. macro). Located in `test/examples/<N>-<name>/` dirs with `.manim` files. Run via `ProgrammableCodeGenTest.hx` and other `*Test.hx` visual test classes.
2. **Unit tests** — pure logic tests for parsers, builders, expressions, types. Located in `test/src/bh/test/examples/` (e.g., `BuilderUnitTest.hx`, `ParserErrorTest.hx`, `BitFlagTest.hx`).
3. **Runtime/integration tests** — tests for UI components, helpers, and runtime systems that don't require rendering. Located alongside unit tests (e.g., `UIMultiAnimGridTest.hx`, `UIDraggableTest.hx`, `CardHandIntegrationTest.hx`, `CardHandTargetingTest.hx`, `TweenManagerTest.hx`, `UIComponentTest.hx`, `UIPanelHelperTest.hx`, `UITooltipHelperTest.hx`, `UIRichInteractiveHelperTest.hx`, `UIScrollableScreenTest.hx`).

**Runtime tests CAN and SHOULD test new Haxe API** — not just `.manim` features. Grid operations, drag-drop logic, card hand helpers, tween sequences, event callbacks, and state machines are all testable via:
- `BuilderTestBase` (extends `utest.Test`, provides `builderFromSource`, `buildFromSource`, scene graph helpers)
- `UITestHarness.UITestScreen` (mock screen for event recording)
- Inline `.manim` source strings (double-quoted to avoid Haxe `$` interpolation)
- `@:privateAccess` for internal state verification
- Event callbacks with assertion flags

Analyze the diff to determine test impact:

- **New tests needed?** If new features, new `.manim` elements, new runtime API, or new code paths were added, identify what tests should be written. For runtime features (grid, drag-drop, card hand, panels, tooltips, tweens), add unit tests to the appropriate existing `*Test.hx` file. For new `.manim` syntax, add visual tests in `test/examples/<N>-<name>/`.
- **Existing tests obsolete?** If features were removed or behavior fundamentally changed, check if any existing test `.manim` files or test methods reference removed/changed functionality. Flag obsolete tests for removal or update.
- **Reference images stale?** If rendering logic changed, existing visual test references may need regeneration.

Present test findings and **ask the user** before proceeding:
- List tests to add (with suggested names and what they cover)
- List tests that may be obsolete or need updating
- List reference images that may need regeneration
- Wait for user confirmation before making test changes

After user confirms, create any agreed-upon new tests following the project conventions (see `testing-and-debugging.md` rules).

**Test file reference** (add new test methods to the appropriate existing file):

| Test File | Covers |
|-----------|--------|
| `UIMultiAnimGridTest.hx` | Grid: cells, data, coordinates, hit-test, events, layers, drag-drop, card targets, DropContext |
| `UIDraggableTest.hx` | Draggable: swap mode, clear, payload, DragEvent variants |
| `CardHandIntegrationTest.hx` | Card hand: callbacks, state, draw/discard, config, arrow snap provider |
| `CardHandTargetingTest.hx` | Targeting: registration, hit-test, highlight, arrow snap, custom provider |
| `CardHandOrchestratorTest.hx` | Card hand: layout math (fan, linear, path-based) |
| `TweenManagerTest.hx` | Tweens: properties, sequences, groups, cancel, completion |
| `UIComponentTest.hx` | UI components: buttons, checkboxes, sliders, dropdowns |
| `UIPanelHelperTest.hx` | Panels: open, close, positioning, outside-click |
| `UITooltipHelperTest.hx` | Tooltips: delay, positioning, hover lifecycle |
| `UIRichInteractiveHelperTest.hx` | Interactive binding: status state machine |
| `UIScrollableScreenTest.hx` | Scrollable screen: scroll, content height |
| `BuilderUnitTest.hx` | Builder: expressions, data blocks, references |
| `ParserErrorTest.hx` | Parser: error messages, edge cases |
| `ProgrammableCodeGenTest.hx` | Visual: builder vs. macro screenshot comparison |

## 6. Run Tests

**Always run tests.** After any code or test changes:

- Run `test.bat run` (or `powershell.exe -ExecutionPolicy Bypass -File test.ps1 run`) and report the result
- If tests fail, investigate failures — do NOT blindly regenerate references
- If failures are expected (due to intentional visual changes), explain why and ask user before running `test.bat gen-refs`
- If new tests were added, run `test.bat gen-refs` to generate their reference images, then `test.bat run` again to verify they pass

Do not proceed to the summary until tests pass (or user explicitly accepts known failures).

## 7. VS Code Extension Sync

If changes affect the `.manim` parser (keywords, syntax, settings), LSP, or language tooling:

- Run `node vscode/sync-check.js` to detect keyword mismatches between the parser and the VS Code grammar (`vscode/syntaxes/multianim.tmLanguage.json`)
- If mismatches are found, update the grammar file to match the parser
- Check if LSP source files (`lsp/src/manim/lsp/`) need updating — e.g. `CompletionProvider.hx` for new keywords/completions, `HoverProvider.hx` for hover docs
- If LSP sources changed, rebuild: `haxe lsp/lsp-server.hxml` and verify `vscode/server/server.js` is updated
- Check if `vscode/package.json` version or configuration needs updating

## 8. Check for Missing Items

Verify:
- No sensitive files (.env, credentials) in the diff
- No inconsistencies between code changes and documentation
- MEMORY.md is up to date with any new patterns or pitfalls discovered.
- Check if anything can be removed from MEMORY.md because it is no longer relevant. Ask user if unsure.

## 9. Suggest Commit Message

- Follow the project's commit message style (see recent commits)
- Format: `area: short description` on first line
- Add bullet points for significant changes in the body
- Keep the first line under 72 characters
- Do not include TODO file changes.

## 10. Report Summary

Present a summary table:
- Files changed (count)
- Changelog entries added
- Docs updated
- TODOs cleaned
- Tests added / updated / removed
- Test run result (pass/fail)
- Any issues found
- Suggested commit message

Do NOT create the commit at all. Present the summary and user will commit.
