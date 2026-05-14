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

### 5a. Warn on Reference Image & Existing Test Changes

Before analyzing impact, scan the diff for modifications to existing tests and reference images. These are high-risk changes that can silently mask regressions.

Run each check and list every hit:

- **Reference images changed:** `git diff --stat HEAD -- 'test/examples/*/reference*.png' 'test/examples/*/ref*.png' 'test/examples/*/*.png'` — any modified (not added) `.png` under `test/examples/`
- **Existing visual test `.manim` files changed:** `git diff --stat HEAD -- 'test/examples/*/*.manim'` filtered to files present before this change (not newly added directories)
- **Existing test methods changed:** `git diff HEAD -- 'test/src/**/*.hx'` — flag any modifications to existing `@Test`/`test*` methods (vs. pure additions of new methods)

For every hit, report:
- **File link:** `[path/to/file.ext:LINE](path/to/file.ext#LLINE)` pointing to the changed region (use the first changed hunk's line number)
- **Reason (if known):** derive from diff context + git history + recent conversation. If the reason is not obvious, say "reason unclear — verify with user".

Format:

```
⚠ Visual test reference images changed (N):
- [test/examples/42-foo/reference.png:1](test/examples/42-foo/reference.png#L1) — reason: <why>
...

⚠ Existing visual tests modified (N):
- [test/examples/42-foo/foo.manim:15](test/examples/42-foo/foo.manim#L15) — reason: <why>
...

⚠ Existing test methods modified (N):
- [test/src/bh/test/examples/BuilderUnitTest.hx:123](test/src/bh/test/examples/BuilderUnitTest.hx#L123) — reason: <why>
...
```

**Never hide these warnings in the summary** — they belong in both section 5 output and the final summary (section 10). Do not regenerate reference images to "fix" a failing test without confirming with the user that the visual change is intentional (see section 6).

### 5b. Test Impact Analysis

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

### 8a. Identify Temporary Files

Scan both tracked and untracked files for scratch/debug/temp artifacts that should not be committed. Do not rely on a fixed extension or filename list — judge each file in context at the time precommit is running.

**Gather the candidate set:**

```sh
# Tracked changes in this commit
git diff --name-only HEAD
# Untracked files (excluding gitignored)
git ls-files --others --exclude-standard
```

**For each candidate, judge whether it looks temporary** using all of the following signals together (not any one in isolation):

- **Name shape:** does the filename or path *read* as scratch/debug/dump/diff/output/wip/backup output rather than a deliberately named source artifact? Look at prefixes, suffixes, and middle tokens.
- **Location:** is it under a directory that exists for transient work, sitting at repo root with no obvious owner, or otherwise outside the project's normal source/test/docs layout?
- **Content:** open the file if its purpose is not clear from the name. A short scratch dump, a captured diff, a one-off log, or pasted command output is suspicious; a deliberately authored source/asset/config is not.
- **History:** brand-new untracked files with no companion changes are more suspicious than files that fit into a coherent diff.
- **Hardcoded transient paths inside committed source:** scan the diff itself for absolute paths into OS temp/scratch locations (Windows `tmp` roots, Unix tmp roots, per-user temp dirs). These are portability hazards even when the containing file is legitimate.

**Do not flag** files that are clearly part of the change being committed, tracked test fixtures, gitignored generated output, or items in `todo/`. When unsure, ask the user instead of guessing.

**Report format:**

```
⚠ Temporary files detected (N):
- [path/to/file](path/to/file) — tracked|untracked — reason: <why this looks temporary in this repo, right now>
- [src/Bar.hx:42](src/Bar.hx#L42) — hardcoded transient path inside committed source
...

Suggested action: `rm <files>` (or `git rm --cached <files>` if tracked). Confirm with user before deleting.
```

- Do NOT delete files automatically — list them and ask the user. A "tmp-looking" file may be an in-progress experiment the user wants to keep locally.
- If a tmp file is *tracked* (showed up in `git diff --name-only HEAD`), flag it with extra emphasis — committing it would persist scratch state. Suggest `git rm` (or `git rm --cached` if it should stay on disk).

### 8b. Allocation Watchdog Hygiene

The hot-path allocation counters (`creationCount`) and their increments must be gated behind `#if MULTIANIM_ALLOC_TRACK` so production builds carry zero overhead. Commit `ab7e4f2` shows what happens when the gate is forgotten — every constructor call paid for a static int increment in production.

Run this check from the repo root and report any hits:

```sh
# Find every `creationCount` reference in src/ and verify each one is inside an
# MULTIANIM_ALLOC_TRACK gate. The grep returns file:line for visual inspection.
grep -rn "creationCount" src/ --include="*.hx"
```

For each hit, open the file and confirm the surrounding code looks like:

```haxe
#if MULTIANIM_ALLOC_TRACK
public static var creationCount:Int = 0;
#end

// ... constructor ...
#if MULTIANIM_ALLOC_TRACK
creationCount++;
#end
```

If a `creationCount` declaration or `creationCount++` line appears outside an `#if MULTIANIM_ALLOC_TRACK ... #end` block, it must be gated before commit. Test files (`test/src/`) are exempt — they read counters directly under the test build's `-D MULTIANIM_ALLOC_TRACK` flag.

A failing `testAllocationTrackingFlagIsDefinedInTestBuilds` test indicates the flag was dropped from `test-common.hxml`; restore it.

### 8c. Shared Mutable Scratch State

The codebase uses static/instance scratch objects (`_scratchPt`, `_pool`, scratch arrays) to dodge per-frame allocations — see `UIInteractiveWrapper._scratchPt`, `UICardHandTargeting._scratchPt`, `TweenManager._pool`, `UICardHandLayout` sample buffers. The codebase is single-threaded (Heaps main loop), so the hazard is **re-entrancy**, not concurrency: same scratch reached twice on the same callstack silently corrupts state.

Scan the diff for these patterns and flag any hit:

```sh
# New or modified scratch / pool declarations
git diff HEAD -- 'src/**/*.hx' | grep -E '^\+\s*(static\s+)?(var|final)\s+_?(scratch|pool|tmp|shared|buffer)'
# New uses of existing scratch instances
git diff HEAD -- 'src/**/*.hx' | grep -E '^\+.*_scratch|_pool\.(pop|push)'
```

**1. Re-entrancy.** A function holding a scratch must not dispatch events, run user callbacks, fire tween `onComplete`, or call into helpers that themselves use the same scratch, between the point it writes and the point it reads. Flag any new code that grabs a scratch *and* in the same scope: emits a `UI*Event`, invokes a callback field (`onCardEvent`, `onGridEvent`, `onComplete`, etc.), iterates a user-supplied collection with a transform, or calls into a sibling helper known to use the same scratch.

**2. Escape.** A scratch reference must never outlive the function call that owns it. Flag new occurrences of: `return _scratch…`, `this.x = _scratch…`, `array.push(_scratch…)`, `map.set(_, _scratch…)`, or any closure capturing a scratch that's stored as a field, returned, or queued (tween, deferred, listener).

**3. Aliasing with mutating Heaps APIs.** `h2d` methods like `globalToLocal` / `localToGlobal` / `Matrix.transform` mutate their argument and return it. If the same scratch is passed *and* still expected to hold its pre-call value afterward, you have a silent bug. Flag new call sites where a scratch is passed to a known-mutating API while the same scratch is read on a later line in the same function.

**4. Justification comment on new static scratch.** Any *new* `static var _scratch…` declaration must carry a one-line comment explaining why a single shared instance is safe (the existing `UIInteractiveWrapper._scratchPt` is the model: identifies the call path as single-threaded and non-re-entrant). Flag new static scratch without this comment.

**Report format:**

```
⚠ Shared scratch hazards (N):
- [src/bh/ui/Foo.hx:120](src/bh/ui/Foo.hx#L120) — re-entrancy: fires onGridEvent while holding _scratchPt
- [src/bh/ui/Bar.hx:42](src/bh/ui/Bar.hx#L42) — escape: returns _scratchPt to caller
- [src/bh/ui/Baz.hx:88](src/bh/ui/Baz.hx#L88) — aliasing: globalToLocal(_scratchPt) then reads _scratchPt.x
- [src/bh/ui/Quux.hx:15](src/bh/ui/Quux.hx#L15) — new static scratch without single-threaded/non-reentrant comment
```

Do NOT auto-fix. List hits and ask the user — some are intentional (a scratch deliberately handed to a mutating API where the caller wants the mutated value).

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
- **Reference images changed** (count + links from 5a — do not omit)
- **Existing tests modified** (count + links from 5a — do not omit)
- **Temporary files detected** (count + links from 8a — do not omit; flag tracked vs untracked)
- **Shared scratch hazards** (count + links from 8c — do not omit)
- Test run result (pass/fail)
- Any issues found
- Suggested commit message

Do NOT create the commit at all. Present the summary and user will commit.
