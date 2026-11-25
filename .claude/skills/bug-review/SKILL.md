---
name: bug-review
description: Review a bug report against the hx-multianim codebase. Verifies whether the report is valid, and if so, drives a strict TDD workflow — writes failing tests first, runs test.bat, waits for user confirmation, and only then fixes. By default all writes happen in a fresh git worktree branched from the current HEAD or origin/dev, so the main checkout is never touched. Detects concurrent-agent interference (unrelated test failures, foreign compilation errors) and pauses accordingly. Triggers: "review this bug report", "bug report:", "/bug-review", "/review" (when the content is a bug report, not a PR).
---

# Bug Report Review (TDD)

You are reviewing a bug report supplied by the user (either inline in the args, in a linked file, or in the preceding message). Follow this workflow strictly. Do not skip steps. Do not fix code before tests exist and the user has confirmed.

## Inputs

The bug report may arrive as:
- Freeform text in the skill args
- A path to a file (`.md`, `.txt`) — read it
- A quoted block or paste in the most recent user message

If the report is ambiguous or missing obvious details (expected vs actual, repro steps, affected file/feature), ask the user one focused clarifying question before proceeding. Do not guess.

## Step 1 — Verify the Report

Before writing anything, establish whether the reported bug is real. This step is read-only, so it runs in the current checkout.

1. Identify the affected subsystem (parser, builder, codegen, a specific UI helper, a specific `.manim` element). Use `CLAUDE.md` and `.claude/rules/` to orient.
2. Read the actual code paths the report blames. Confirm the described behavior by reading — not by guessing from the report's wording. Reports are often imprecise about file names, symbol names, or direction of the bug.
3. Check `git status --short` for the blamed files. If any have uncommitted edits, the worktree in Step 2 will not contain them (it branches from a commit — `HEAD` or `origin/dev`). Compare against `git show HEAD:<file>` and note whether the bug lives in `HEAD` or only in the uncommitted edits — Step 2 needs this.
4. Decide one of:
   - **Valid** — behavior matches the report, or the report describes a real code path defect even if the phrasing is off. Proceed to Step 2.
   - **Already fixed** — current code on `HEAD` does not exhibit the bug. Say so, cite the commit or lines, and stop. Do not write tests for a non-bug.
   - **Misunderstanding / not a bug** — the described behavior is actually intended, or the report misreads the API. Explain concisely with file:line citations. Do not proceed to fix anything. Stop.
   - **Insufficient info** — you cannot tell without more input. Ask one targeted question. Stop.

Report the verdict to the user in 2–4 sentences with specific [file.hx:line](path#Lline) citations before moving on. If you identified additional bugs in the code that is not part of this bug report, report in to the user in separate line and short summary. User might decide to include it in the fix.

## Step 2 — Create a Worktree (default)

All writes — tests, the fix, test runs — happen in a fresh git worktree, so the main checkout (which may hold the user's or another agent's uncommitted edits) stays untouched.

**Skip this step** and work in place only when:
- The user asked for it ("no worktree", "in place", "work here").
- The session is already inside a worktree (the current directory is under `.claude/worktrees/`, or `git rev-parse --git-dir` contains `/worktrees/`). Reuse it.
- The bug exists only in uncommitted edits in the main checkout (see Step 1.3). Ask the user whether to work in place or have them commit first — do not guess.

Otherwise:

1. Pick a short kebab-case slug describing the bug's behavior (e.g. `tween-cancel-fires-oncomplete`). Never use the report's ordinal label (see Guardrails).
2. Choose the base: **`origin/dev` or local `HEAD`** (never `main`). If the session is on a branch other than `dev`, ask whether to compare against that branch's upstream instead.
   - Refresh the remote ref with `git fetch origin dev` (it only updates `origin/dev`, never your branch). If the fetch fails (e.g. offline), use the existing `origin/dev` and tell the user it may be stale.
   - Compare them: `git rev-list --left-right --count origin/dev...HEAD` prints `<behind> <ahead>`.
   - **`0 0`** — same commit. Use it without asking.
   - **Anything else — they have diverged. Stop and ask the user which base to use.** Show the behind/ahead counts and `git log --oneline` for the commits on each side (up to ~10 per side), plus a recommendation:
     - only ahead → `HEAD` has unpushed local commits; recommend `HEAD`.
     - only behind → the local branch is stale; recommend `origin/dev`.
     - both → truly diverged; no default, the user decides.
3. Create the worktree from the chosen base:
   ```
   git worktree add -b bugfix/<slug> .claude/worktrees/bugfix-<slug> <HEAD|origin/dev>
   ```
   If the branch or directory already exists, append `-2`, `-3`, … Never reuse or overwrite an existing worktree or branch.
4. Switch the session into it with the `EnterWorktree` tool, passing `path` = the absolute path of `.claude/worktrees/bugfix-<slug>`. Do **not** pass `name`: that creates a separate worktree from `origin/<default-branch>` (per the `worktree.baseRef` setting), which is the wrong base.
5. Tell the user in one line: worktree path, branch, and base commit (`git log -1 --oneline`).
6. If the base is not the `HEAD` that Step 1 verified against, re-check the blamed lines inside the worktree. If the bug is gone there, report **Already fixed** (citing the commit that fixed it) and stop.

From here on, every read, edit, and `test.bat` run happens inside the worktree. `.haxerc` and `haxe_libraries/` are tracked and the lix cache is global, so builds work unchanged. `build/` starts empty, so the first `test.bat run` does a full compile.

## Step 3 — Propose the Fix (Design, Not Code)

Once valid:

1. Name the **root cause** in one sentence. Not the symptom — the underlying cause.
2. List the minimal code change to fix it (file paths + what changes). No code yet.
3. Note any ripple: docs to update (`docs/manim-reference.md`, `docs/anim-reference.md`, `docs/manim.md`), `CHANGELOG.md` entries, related subsystems.
4. **Performance & allocation impact.** Evaluate the proposed fix against the code it replaces:
   - **Performance** — does the fix add work on a hot path (per-frame `update`, builder re-evaluation, parser, tween tick, interactive hit test)? Call out loss (e.g. extra `globalToLocal` per frame, added iteration over all cells, redundant rebuild) or improvement (e.g. removed redundant work, cached lookup, early-out added).
   - **Allocations** — does the fix introduce new per-call/per-frame allocations (`new Array`, `new Map`, closures captured inside a loop, `StringTools.format`, anonymous structs inside `update`, boxing of enum params)? Call out additions (bad) or removals (good). Builder/codegen paths that fire on every rebuild or every `setParameter` are especially sensitive.
   - If the fix is neutral on both axes, say so explicitly (one line). Do not skip this section.
   - If the fix **worsens** either axis, propose a mitigation or flag the tradeoff for the user before writing tests.
5. Identify which existing test file new tests belong in (see the test-file reference in `.claude/skills/precommit/SKILL.md` step 5 for the authoritative mapping). New `.manim` syntax → visual test under `test/examples/<N>-<name>/`. Everything else → a method on an existing `*Test.hx`.

Present this plan to the user and proceed to Step 4 on the same turn — do not wait for a separate "go ahead" before writing the failing test. The user's confirmation gate is **after** the test fails, not before you write it.

## Step 4 — Write the Failing Test (TDD Red)

1. Write focused tests that fail **because of the reported bug**, not because of unrelated setup issues. The tests names should describe the expected correct behavior. If one test covers the behaviour completely, just write one test.
2. Prefer unit/integration tests over visual tests unless the bug is inherently visual. Visual test failures are harder to triage.
3. Follow project conventions from `.claude/rules/testing-and-debugging.md`:
   - utest 2.0-alpha: method name MUST start with `test` prefix
   - At least one `Assert.*` per method (otherwise "warning" → FAILED)
   - Test strings with `$` use double quotes to avoid Haxe string interpolation
   - `version: 1.0` header in test `.manim` strings where a parser reads them
4. If adding a visual test:
   - Create `test/examples/<N>-<name>/<name>.manim` with the next unused N
   - Register it in `test/src/bh/test/MultiProgrammable.hx`
   - Add a `test<N>_<Name>` method in `ProgrammableCodeGenTest.hx`
   - Do **not** run `test.bat gen-refs` yet — the test is supposed to fail

## Step 5 — Run the Tests

Run `test.bat run` (or `powershell.exe -ExecutionPolicy Bypass -File test.ps1 run`) from the worktree root. Read the structured output.

### Triage the output

Three possible non-success states:

**(a) Your new test fails for the expected reason.** This is the goal — TDD "red". Capture the failure message and the full test-run summary, present both to the user, and ask for explicit confirmation to proceed to the fix. Do NOT start fixing.

**(b) Your new test fails, but for a setup/wiring reason unrelated to the bug.** Fix the test itself and re-run. Do not proceed until the failure is for the right reason.

**(c) Your new test passes unexpectedly.** Either the bug is already fixed on `HEAD`, or the test does not actually exercise the bug. Re-read the code and the report, adjust the test, and re-run. Do not fix anything yet.

### Concurrent-agent interference

The worktree shields you from edits in the main checkout, but not from a broken `HEAD` or another agent working in the same tree (mainly a risk when Step 2 was skipped). Watch for these and handle specifically:

- **Unrelated test failures**: tests that were failing before your changes, or that fail in files you did not touch. Explicitly list them in your report as "pre-existing / concurrent failures — not touched by this review" and **ignore them** when judging whether your new test behaves correctly. Do not try to fix them in this skill run.
- **Compilation errors in files you did not touch**: in a fresh worktree this means `HEAD` itself is broken; when working in place it may also be another agent's half-finished edit. STOP. Do not attempt to work around the compile error. Warn the user clearly:
  > ⚠ Compilation failed in files I did not modify: `<file1.hx>`, `<file2.hx>`. This is either a broken `HEAD` or a concurrent edit by another agent. I will not proceed until the tree compiles. Please resolve, then say `continue`.
  Then wait. Do not rerun until the user confirms.
- **Compilation errors you caused** (in files you just wrote/edited): fix them yourself and re-run. Do not blame concurrency for your own mistakes.

## Step 6 — Wait for User Confirmation

After reporting a clean "red" (new test fails for the right reason, no foreign compile errors), **stop and wait**. Do not write the fix. The user will either:
- Approve the test → proceed to Step 7
- Ask for changes to the test → revise, re-run Step 5
- Ask you to stop → stop

If the user's response is ambiguous, ask. Do not infer approval from silence or from a generic "ok".

## Step 7 — Implement the Fix (TDD Green)

Only after explicit user approval:

1. Apply the minimal fix identified in Step 3. Do not refactor surrounding code, do not add unrequested features, do not rename things.
2. Run `test.bat run` again.
3. Expected outcome: the new test now passes. Pre-existing failures noted in Step 5 should be unchanged (same count, same names) — if new unrelated failures appeared, your fix had a ripple effect; investigate before claiming green.
4. If this was a visual test, regenerate its reference image ONLY now: `test.bat gen-refs`, then `test.bat run` once more to verify. Never gen-refs before a human has approved the expected visual.

## Step 8 — Report & Hand Off

Concise summary:
- **Verdict from Step 1** (valid bug / already fixed / not a bug)
- **Worktree**: path and branch (or "worked in place" and why)
- **Root cause** (one sentence)
- **Files changed** (bullet list)
- **New test(s)** (file + method name)
- **Test run result**: new test now passes; pre-existing failures = N (unchanged)
- **Performance & allocation impact** (one line): improvement / neutral / regression + a short reason. Call out removed or added per-frame work and allocations.
- **Foreign compilation issues encountered**, if any
- **Docs/changelog touched**, if any (usually defer this to `/precommit`)

Do **not** commit. Leave the changes uncommitted in the worktree and leave the worktree in place: do not call `ExitWorktree` with `remove`, and do not run `git worktree remove` or delete the branch. The user commits (or runs `/precommit` inside the worktree), merges `bugfix/<slug>`, and cleans up.

## Guardrails

- Never run `git stash`, `git reset`, `git restore`, or `git clean`. Do not run any destructive `git` command. You can examine git history. (See MEMORY.) The only git writes this skill makes are `git fetch origin dev` and `git worktree add -b` in Step 2.
- Never remove the worktree or delete its branch — cleanup is the user's call.
- Never skip `test.bat run`. "Looks right" is not a substitute for a green test.
- Never fix more than the bug. Cleanup, drive-by renames, and "while I'm here" refactors belong in a separate task.
- Never regenerate visual reference images to "make the test pass" — that defeats the point of TDD. References are regenerated only after a human has approved the new expected visual.
- Never proceed past a foreign compilation error. Waiting is cheaper than stepping on another agent's toes.
- Never include the bug's identifier from the report (e.g. `L1`, `h2`, `#3`) in code comments, test names, branch/worktree names, or commit messages. These labels are only ordinal within a single report — they are not stable, not unique across reports, and meaningless to anyone reading the code later. Describe the bug by its behavior instead.
