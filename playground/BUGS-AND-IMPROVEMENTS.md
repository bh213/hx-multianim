# Playground Bugs and Improvements

This document lists identified bugs and suggested improvements for the hx-multianim playground.

---

## Bugs

### BUG-001: Language Not Switching for .anim Files
**Severity:** Medium
**Location:** [CodeEditor.tsx:178-187](react_src/CodeEditor.tsx#L178-L187)

**Description:**
The `CodeEditor` component uses `defaultLanguage` which is set once on mount. When switching from a `.manim` file to an `.anim` file, the syntax highlighting doesn't update because Monaco's `defaultLanguage` is not reactive.

**Current Code:**
```tsx
<Editor
  defaultLanguage={getLanguage()}
  // ...
/>
```

**Fix:**
Use the `language` prop instead of `defaultLanguage` to make it reactive:
```tsx
<Editor
  language={language.endsWith('.anim') ? 'haxe-anim' : 'haxe-manim'}
  // ...
/>
```

Also update `App.tsx` to pass the correct language based on filename:
```tsx
<CodeEditor
  language={selectedManimFile?.endsWith('.anim') ? 'haxe-anim' : 'haxe-manim'}
/>
```

---

### BUG-002: updateContent Does Not Update animFiles
**Severity:** Medium
**Location:** [PlaygroundLoader.ts:464-471](react_src/PlaygroundLoader.ts#L464-L471)

**Description:**
The `updateContent` method only updates `manimFiles` but not `animFiles`. When editing `.anim` files, changes are saved to `fileMap` but not to the `animFiles` array, causing inconsistency.

**Current Code:**
```typescript
updateContent(filename: string, content: string): void {
    const manimFile = this.manimFiles.find(file => file.filename === filename);
    if (manimFile) {
        manimFile.content = content;
        updateFileContent(filename, content);
    }
    // Missing: animFiles update
}
```

**Fix:**
```typescript
updateContent(filename: string, content: string): void {
    const manimFile = this.manimFiles.find(file => file.filename === filename);
    if (manimFile) {
        manimFile.content = content;
    }

    const animFile = this.animFiles.find(file => file.filename === filename);
    if (animFile) {
        animFile.content = content;
    }

    updateFileContent(filename, content);
}
```

---

### BUG-003: Stale Closure in saveHandler useCallback
**Severity:** Low
**Location:** [App.tsx:573-575](react_src/App.tsx#L573-L575)

**Description:**
The `saveHandler` callback has dependencies listed in `useCallback` but doesn't include all dependencies it actually uses. `handleApplyChanges` is called but not listed as a dependency.

**Current Code:**
```tsx
const saveHandler = React.useCallback(() => {
    handleApplyChanges();
}, [selectedManimFile, manimContent, selectedScreen, loader]);
```

**Issue:**
`handleApplyChanges` is not a stable reference and is recreated on each render, but it's not in the dependency array.

**Fix:**
Either memoize `handleApplyChanges` with `useCallback` or include the actual dependencies:
```tsx
const handleApplyChanges = React.useCallback(() => {
    // ... existing logic
}, [selectedManimFile, manimContent, selectedScreen, loader]);

const saveHandler = handleApplyChanges;
```

---

### BUG-004: validateManimContent Called with Missing Dependencies
**Severity:** Low
**Location:** [App.tsx:342](react_src/App.tsx#L342), [App.tsx:363](react_src/App.tsx#L363)

**Description:**
`validateManimContent()` is called inside `useEffect` hooks but is defined as a regular function. This means it captures stale closures. The function depends on `selectedScreen`, `loader`, and `manimContent` but these aren't tracked.

**Fix:**
Convert `validateManimContent` to a `useCallback` with proper dependencies, or inline the logic in the effect.

---

### BUG-005: isManimOrAnim Logic Is Inverted in Main.hx
**Severity:** High
**Location:** [Main.hx:179-181](src/Main.hx#L179-L181)

**Description:**
The `isManimOrAnim` function checks if a filename ends with `.manim` or `.anim`, but it's used to decide loading priority for **all resources**, not just the actual `.manim`/`.anim` files. For atlas, tiles, and other resources loaded during screen rendering, this function returns `false`, so JS loader is tried second (Haxe first). However, when the screen's `.manim` content was edited in the playground, the related resources might also need to be reloaded from JS.

**Current Behavior:**
- For `.manim`/`.anim` files: JS first, Haxe second (correct)
- For `.atlas2`, `.png`, etc.: Haxe first, JS second

This is actually **correct behavior** since asset files are not edited. However, the function name is misleading.

**Suggested Improvement:**
Rename the function to `shouldLoadFromJSFirst` for clarity, or add a comment explaining the logic.

---

### BUG-006: Error Position Calculation May Be Off by One
**Severity:** Low
**Location:** [App.tsx:584-597](react_src/App.tsx#L584-L597)

**Description:**
The error line calculation uses `pmin` as a 0-based character offset but Monaco uses 1-based line numbers. The current calculation starts `line = 1` and increments on newlines, which is correct. However, if `pmin` points to a newline character itself, the line number might be off.

**Current Code:**
```tsx
for (let i = 0; i < pmin && i < content.length; i++) {
    if (content[i] === '\n') {
        line++;
        column = 1;
    } else {
        column++;
    }
}
```

**Potential Issue:**
If `pmin` equals the position right after a newline, `column` will be 1, but if it's on the newline itself, the calculation may point to the previous line.

**Fix:**
Verify edge cases where `pmin` lands on `\n` or at the start of content.

---

### BUG-007: Console Capture Memory Leak
**Severity:** Low
**Location:** [App.tsx:71-126](react_src/App.tsx#L71-L126)

**Description:**
Console entries accumulate indefinitely in state. Long editing sessions can cause memory issues as every console.log is captured and stored.

**Fix:**
Add a maximum entry limit:
```tsx
const MAX_CONSOLE_ENTRIES = 1000;

const addConsoleEntry = (type, ...args) => {
    setConsoleEntries(prev => {
        const newEntries = [...prev, { type, message, timestamp: new Date() }];
        return newEntries.slice(-MAX_CONSOLE_ENTRIES);
    });
};
```

---

### BUG-008: Screen Selector ID Mismatch
**Severity:** Low
**Location:** [PlaygroundLoader.ts:416-417](react_src/PlaygroundLoader.ts#L416-L417)

**Description:**
`reloadPlayground` tries to get screen from `#screen-selector` but React UI doesn't have an element with this ID. The `<select>` in `App.tsx` doesn't have an ID attribute.

**Current Code:**
```typescript
const screenCombo = document.getElementById('screen-selector') as HTMLSelectElement;
selectedScreen = screenCombo ? screenCombo.value : 'particles';
```

**Impact:**
When `screenName` is not provided, fallback to 'particles' always happens instead of getting current selection.

**Fix:**
Add `id="screen-selector"` to the select element in `App.tsx:703`:
```tsx
<select
    id="screen-selector"
    className="..."
>
```

---

## Improvements

### IMP-001: Add Auto-Save with Debounce
**Priority:** Medium

**Description:**
Currently users must manually click "Apply Changes" or press Ctrl+S. Adding auto-save with debounce would improve the live editing experience.

**Implementation:**
```tsx
// In App.tsx
const debouncedSave = useMemo(() =>
    debounce((content: string) => {
        if (autoSave && selectedManimFile) {
            handleApplyChanges();
        }
    }, 1500),
    [autoSave, selectedManimFile]
);

useEffect(() => {
    if (hasUnsavedChanges && autoSave) {
        debouncedSave(manimContent);
    }
}, [manimContent, hasUnsavedChanges, autoSave]);
```

---

### IMP-002: Persist Editor State in LocalStorage
**Priority:** Medium

**Description:**
Currently, all edits are lost on page refresh. Persisting to localStorage would preserve work between sessions.

**Implementation:**
```tsx
// On content change
useEffect(() => {
    if (selectedManimFile && manimContent) {
        localStorage.setItem(`playground_${selectedManimFile}`, manimContent);
    }
}, [selectedManimFile, manimContent]);

// On file select, check localStorage first
const loadFileContent = (filename: string) => {
    const saved = localStorage.getItem(`playground_${filename}`);
    if (saved) {
        return saved;
    }
    return getFileContent(filename);
};
```

---

### IMP-003: Add Undo/Redo Stack Beyond Monaco
**Priority:** Low

**Description:**
Monaco has built-in undo/redo, but there's no way to undo a reload that broke the screen. A "Revert to Last Working" button would help users recover from errors.

---

### IMP-004: Improve Error Messages with Suggestions
**Priority:** Medium

**Description:**
Parser errors show raw Haxe exception messages. Adding common error patterns with suggestions would help users:

```typescript
const ERROR_SUGGESTIONS: Record<string, string> = {
    'unexpected MP': 'Check for missing closing brackets or parentheses',
    'Unexpected token': 'Verify syntax near the error position',
    'Unknown element': 'Check element name spelling (e.g., bitmap, text, ninepatch)',
};
```

---

### IMP-005: Add Keyboard Shortcuts Panel
**Priority:** Low

**Description:**
Add a keyboard shortcuts reference. Currently only Ctrl+S is documented.

Suggested shortcuts:
- `Ctrl+S` - Apply changes
- `Ctrl+/` - Toggle comment
- `Ctrl+D` - Duplicate line
- `F5` - Force reload screen

---

### IMP-006: Unify Haxe Versions in CI
**Priority:** High

**Description:**
`build.yml` uses Haxe 4.3.6, `deploy-playground-to-gh-pages.yml` uses 4.3.2. This inconsistency could cause different behavior between PR validation and deployment.

**Fix:**
Use the same version (4.3.6) in both workflows.

---

### IMP-007: Add Visual Tests to CI
**Priority:** High

**Description:**
The repository has a test suite (`test.bat`) but it's not run in CI. Adding visual regression tests would catch rendering issues.

**Implementation in `.github/workflows/build.yml`:**
```yaml
- name: Run visual tests
  run: |
    cd playground
    npm ci
    npm run build
    # Run headless browser tests
```

---

### IMP-008: Add Loading State Indicator
**Priority:** Medium

**Description:**
When reloading the playground, there's no visual feedback. A loading spinner would improve UX.

---

### IMP-009: Support Multiple Open Files (Tabs)
**Priority:** Low

**Description:**
Currently only one file can be edited at a time. Tab-based editing would allow comparing/referencing multiple files.

---

### IMP-010: Add Fullscreen Mode for Playground Panel
**Priority:** Low

**Description:**
Allow the WebGL canvas to be expanded to fullscreen for better viewing of animations.

---

### IMP-011: Export/Download Modified Files
**Priority:** Medium

**Description:**
Allow users to download their modified `.manim`/`.anim` files for use in their own projects.

**Implementation:**
```tsx
const downloadFile = () => {
    const blob = new Blob([manimContent], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = selectedManimFile;
    a.click();
};
```

---

### IMP-012: Add Code Snippets/Templates
**Priority:** Medium

**Description:**
Provide common code snippets for the `.manim` language:
- Basic programmable template
- Common UI patterns (button, checkbox, slider)
- Animation patterns

---

## GitHub Actions Improvements

### CI-001: Cache Lix Dependencies
Add caching for Lix dependencies to speed up builds:
```yaml
- name: Cache Lix
  uses: actions/cache@v3
  with:
    path: ~/.lix
    key: ${{ runner.os }}-lix-${{ hashFiles('**/haxe_libraries/*.hxml') }}
```

### CI-002: Add Build Artifact Verification
Verify that output files exist after build:
```yaml
- name: Verify build output
  run: |
    test -f playground/public/playground.js || exit 1
    test -d playground/dist || exit 1
```

### CI-003: Add Deployment Preview for PRs
Use a service like Vercel or Netlify for PR preview deployments.

---

## Summary

| Category | Count | High Priority |
|----------|-------|---------------|
| Bugs | 8 | 1 (BUG-005 is actually not a bug, just misleading) |
| Improvements | 12 | 2 (IMP-006, IMP-007) |
| CI Improvements | 3 | 0 |

### Recommended Priority Order

1. **BUG-002**: Fix `updateContent` for animFiles (breaks .anim editing)
2. **BUG-001**: Fix language switching in editor (UX issue)
3. **IMP-006**: Unify Haxe versions in CI (consistency)
4. **IMP-007**: Add visual tests to CI (quality)
5. **BUG-008**: Add screen-selector ID (reliability)
6. **IMP-001**: Auto-save with debounce (UX)
7. **IMP-002**: LocalStorage persistence (UX)
8. **BUG-007**: Console memory limit (stability)
