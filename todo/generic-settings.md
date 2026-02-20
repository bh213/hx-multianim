# Generic Settings: Pass-through to Programmable Parameters

## Problem

Each UI element type (button, slider, dropdown, etc.) has **hardcoded setting names** in `UIScreen.hx`. Adding a new settable parameter requires:
1. Adding it to the programmable in `std.manim`
2. Adding it to the hardcoded whitelist in the `add*` method
3. Manually extracting and forwarding it

Instead, any setting not recognized as a **control setting** should be automatically forwarded to the underlying programmable as an extra parameter. The builder already validates params against the programmable's definition, so mismatches are caught at build time.

## Design

### Prefix-based Routing for Multi-Programmable Elements

Multi-programmable elements (dropdown, scrollableList) use multiple builders. Settings use a **dot prefix** to target a specific sub-builder:

```manim
settings {
    width: int => 300                    # unprefixed → goes to main builder
    item.fontColor: int => 0xff0000      # "item" prefix → forwarded to item builder
    panel.borderWidth: int => 2          # "panel" prefix → forwarded to panel builder
    scrollbar.thickness: int => 6        # "scrollbar" prefix → forwarded to scrollbar builder
}
```

Each `add*` method registers which prefixes it supports. Unprefixed settings go to the **main** builder (button for dropdown, panel for scrollableList) unless they are control settings.

### Setting Categories

Every setting is one of:

1. **Control settings** — consumed by UIScreen code, never forwarded to any builder. Hardcoded and validated.
2. **Behavioral settings** — set as properties on the created UI object (not programmable params). Hardcoded and validated.
3. **Prefixed pass-through** — `prefix.paramName` → forwarded to the builder registered for that prefix.
4. **Unprefixed pass-through** — forwarded to the main builder's `extraParams`.

### Per-Component Control & Behavioral Settings

These are the settings that remain hardcoded (NOT passed through). Everything else is pass-through.

| Component | Control Settings | Behavioral Settings | Registered Prefixes |
|-----------|-----------------|---------------------|---------------------|
| **button** | `buildName`, `text` | — | — |
| **slider** | `buildName` | `min`, `max`, `step` | — |
| **checkbox** | `buildName` | `initialValue` | — |
| **progressBar** | `buildName` | — | — |
| **radio** | `radioBuildName`, `radioButtonBuildName` | — | — |
| **checkboxWithText** | `buildName` | — | — |
| **scrollableList** | `panelBuildName`, `itemBuildName`, `scrollbarBuildName`, `scrollbarInPanelName`, `panelMode` | `scrollSpeed`, `doubleClickThreshold`, `wheelScrollMultiplier` | `item`, `scrollbar` (main = panel) |
| **dropdown** | `dropdownBuildName`, `panelBuildName`, `itemBuildName`, `scrollbarBuildName`, `scrollbarInPanelName`, `panelMode` | `autoOpen`, `autoCloseOnLeave`, `closeOnOutsideClick`, `transitionTimer`, `scrollSpeed`, `doubleClickThreshold`, `wheelScrollMultiplier` | `dropdown`, `item`, `scrollbar` (main = panel) |

**Notes on formerly-hardcoded settings that become pass-through:**
- `width`, `height`, `font`, `fontColor` on button → now pass-through (underlying `#button` programmable must declare them)
- `size` on slider → pass-through (rename to match programmable param name, or keep as alias)
- `width`, `height`, `topClearance` on scrollableList/dropdown → pass-through to panel builder (main)
- `font`, `fontColor` on scrollableList/dropdown → currently forwarded to both item AND dropdown builders. With prefix routing: `item.font`, `item.fontColor`, `dropdown.font`, `dropdown.fontColor`. For backwards compatibility, unprefixed `font`/`fontColor` could still forward to both item and dropdown. **Decision: keep font/fontColor as special-cased multi-forward for backwards compatibility, but also support prefixed versions.**
- `textColor`, `font` on checkboxWithText → pass-through

### Error Messages

| Scenario | Error Message |
|----------|--------------|
| Unknown control setting | `Unknown setting "xyz" for button. Valid control settings: buildName, text` |
| Prefixed setting with unknown prefix | `Unknown sub-component prefix "xyz" in setting "xyz.param" for dropdown. Valid prefixes: dropdown, item, panel, scrollbar` |
| Pass-through param not in programmable | `Setting "bugabuga" does not match any parameter of programmable "#button". Available parameters: status, disabled, buttonText, width, height, font` |
| Prefixed pass-through param not in sub-programmable | `Setting "item.bugabuga" does not match any parameter of sub-component "item" programmable "#list-item-120". Available parameters: ...` |

For the last two, the builder's `updateIndexedParamsFromDynamicMap()` currently throws a technical error. We need to wrap the builder call to catch and re-throw with a better message, or improve the builder error directly.

## Implementation Plan

### Step 1: Parser — Support Dotted Setting Keys

**File:** `MacroManimParser.hx` (settings parsing, ~line 3135)

Currently `expectIdentifierOrString()` returns a single identifier. After reading the key identifier, check for `TDot` and if present, read the second identifier and join with `.`:

```
key = expectIdentifierOrString()
if peek() == TDot:
    advance()
    suffix = expectIdentifierOrString()
    key = key + "." + suffix
```

No changes to `ResolvedSettings` type needed — the key is just a string, `"item.fontColor"` is a valid map key.

### Step 2: UIScreen — Add Helper Infrastructure

**File:** `UIScreen.hx`

Add these helper methods:

```haxe
// Convert SettingValue to Dynamic for passing to builder
function settingValueToDynamic(v:SettingValue):Dynamic

// Split settings into: control, behavioral, and pass-through (by prefix)
// Returns: {main: Map<String,Dynamic>, prefixed: Map<String, Map<String,Dynamic>>}
// Validates: control settings against whitelist, prefixes against registered list
function splitSettings(
    settings:ResolvedSettings,
    controlSettings:Array<String>,
    behavioralSettings:Array<String>,
    registeredPrefixes:Array<String>,
    elementName:String
):{ main:Null<Map<String,Dynamic>>, prefixed:Map<String, Map<String,Dynamic>> }

// Merge pass-through params into existing extraParams map
function mergeExtraParams(existing:Null<Map<String,Dynamic>>, additional:Null<Map<String,Dynamic>>):Null<Map<String,Dynamic>>
```

`splitSettings` logic:
1. For each setting key:
   - If key is in `controlSettings` or `behavioralSettings` → skip (handled explicitly by caller)
   - If key contains `.` → split into `prefix.paramName`, validate prefix against `registeredPrefixes`, put in `prefixed[prefix][paramName]`
   - Otherwise → put in `main[key]`
2. Throw on unknown prefixes with helpful error listing valid ones.

### Step 3: Refactor Each `add*` Method

#### `addButton`
- Control: `buildName`, `text`
- Behavioral: (none)
- Prefixes: (none)
- Pass-through main → `extraParams` on `UIStandardMultiAnimButton.create()`

#### `addSlider`
- Control: `buildName`
- Behavioral: `min`, `max`, `step`
- Prefixes: (none)
- Pass-through: `size` and anything else → forward to slider builder. Note: current `size` setting maps to `size` programmable param (enum `[100,200,300]`). This is already a pass-through candidate — remove the explicit extraction.

#### `addCheckbox`
- Control: `buildName`
- Behavioral: `initialValue`
- Prefixes: (none)
- Pass-through: anything else → forward to checkbox builder

#### `addProgressBar`
- Control: `buildName`
- Behavioral: (none)
- Prefixes: (none)
- Pass-through: anything else → forward to progressBar builder

#### `addRadio`
- Control: `radioBuildName`, `radioButtonBuildName`
- Behavioral: (none)
- Prefixes: (none)
- Pass-through: anything else → forward. Note: radio has two builders but they're accessed differently (outer layout + inner radio button). Pass-through goes to the outer radio programmable.

#### `addCheckboxWithText`
- Control: `buildName`
- Behavioral: (none)
- Prefixes: (none)
- Pass-through: `textColor`, `font`, `title` and anything else → forward via `buildWithParameters` params

#### `addScrollableList`
- Control: `panelBuildName`, `itemBuildName`, `scrollbarBuildName`, `scrollbarInPanelName`, `panelMode`
- Behavioral: `scrollSpeed`, `doubleClickThreshold`, `wheelScrollMultiplier`
- Prefixes: `item`, `scrollbar` (main = panel)
- Pass-through: unprefixed → panel builder params (`width`, `height`, `topClearance`, etc.)
- Prefixed: `item.*` → `itemBuilder.withExtraParams(...)`, `scrollbar.*` → `scrollbarBuilder.withExtraParams(...)`
- **Backwards compat**: unprefixed `font`, `fontColor` → forward to item builder (existing behavior). Also support `item.font`, `item.fontColor` for explicit routing.

#### `addDropdown`
- Control: `dropdownBuildName`, `panelBuildName`, `itemBuildName`, `scrollbarBuildName`, `scrollbarInPanelName`, `panelMode`
- Behavioral: `autoOpen`, `autoCloseOnLeave`, `closeOnOutsideClick`, `transitionTimer`, `scrollSpeed`, `doubleClickThreshold`, `wheelScrollMultiplier`
- Prefixes: `dropdown`, `item`, `scrollbar` (main = panel)
- Pass-through: unprefixed → panel builder
- Prefixed: `dropdown.*` → `dropdownBuilder.withExtraParams(...)`, `item.*` → `itemBuilder.withExtraParams(...)`, `scrollbar.*` → `scrollbarBuilder.withExtraParams(...)`
- **Backwards compat**: unprefixed `font`, `fontColor` → forward to BOTH item and dropdown builders (existing behavior). Also support `item.font`, `dropdown.font` for explicit routing.

### Step 4: Improve Error Messages

**File:** `MultiAnimBuilder.hx` — `updateIndexedParamsFromDynamicMap()` (~line 4737)

Currently throws: `$key=>$value does not have matching ParametersDefinitions`

Improve to include:
- The programmable name
- The list of available parameter names

Alternatively, wrap builder calls in `add*` methods with try-catch to add context about which component/sub-component failed.

**Approach:** Wrap in try-catch in `splitSettings` or at the builder call site:
```haxe
try {
    builder.buildWithComboParameters(name, params, combos);
} catch (e:String) {
    if (e.indexOf("does not have matching ParametersDefinitions") != -1) {
        throw 'Setting pass-through failed for "$elementName": $e';
    }
    throw e;
}
```

For prefixed settings, add sub-component context:
```
Setting "item.bugabuga" — sub-component "item" error: bugabuga does not have matching ParametersDefinitions ...
```

### Step 5: Update std.manim Files

The playground std.manim already has most params. The hx-easy-game std.manim needs updates:

#### `#button` — add `width:uint=200`, `height:uint=30`, `font="dd"`
Currently hardcodes `200, 30` in ninepatch sizes and `dd` in text. Change to use `$width`, `$height`, `$font`.

#### `#dropdown` — add `font="m6x11"`, `fontColor:int=0xffffff12` (already in playground version, missing in hx-easy-game)

#### `#list-item-120` — add `font="m6x11"`, `fontColor:int=0xffffff12` (already in playground version, missing in hx-easy-game)

#### `#slider` — `size` is already a param (enum). No changes needed.

#### `#list-panel` — `width`, `height`, `topClearance` already params. No changes needed.

#### `#scrollbar` — no pass-through params needed currently.

### Step 6: Tests

#### Test A: Basic Pass-through (button)
- `.manim` with `#testButton programmable(status:[hover,normal], disabled:[true,false], buttonText="X", myColor:int=0xff0000)`
- Screen uses `settings { myColor: int => 0x00ff00 }`
- Verify the button builds without error and `myColor` reaches the programmable

#### Test B: Prefixed Pass-through (dropdown/scrollableList)
- Use existing std.manim dropdown/list-item with `font`/`fontColor` params
- Screen uses `settings { item.fontColor: int => 0xff0000 }`
- Verify `fontColor` reaches the item builder, not the panel builder

#### Test C: Error — Unknown Setting (no matching param)
- Settings has `bugabuga: int => 12` but programmable lacks `bugabuga`
- Verify error message mentions the programmable name and available params

#### Test D: Error — Unknown Prefix
- Settings has `xyz.param: int => 1` but component has no `xyz` prefix
- Verify error message lists valid prefixes

#### Test E: Error — Prefixed Setting with No Matching Param
- Settings has `item.nonexistent: int => 1` but item programmable lacks `nonexistent`
- Verify error message mentions "sub-component item" and available params

#### Test F: Backwards Compat — Unprefixed font/fontColor on Dropdown
- Settings has unprefixed `font: string => "dd"` and `fontColor: int => 0xff0000` on dropdown
- Verify both item builder and dropdown builder receive them (existing behavior preserved)

#### Test G: Mixed Control + Pass-through
- Settings has both `buildName: string => "customBtn"` and `width: int => 300` on button
- Verify `buildName` changes the builder name, `width` passes through as param

#### Implementation approach for tests:
- Tests A, B, F, G: Visual tests using `simpleTest` or `simpleMacroTest` pattern — create a `.manim` with the component, build it, screenshot-compare
- Tests C, D, E: Unit tests that assert specific exceptions are thrown. Add to `BuilderUnitTest` or create a `SettingsUnitTest`

## File Change Summary

| File | Changes |
|------|---------|
| `MacroManimParser.hx` | Support dotted keys (`item.fontColor`) in settings parsing (~5 lines) |
| `UIScreen.hx` | Add `settingValueToDynamic`, `splitSettings`, `mergeExtraParams` helpers. Refactor 8 `add*` methods to use split-and-forward pattern instead of whitelist validation. |
| `MultiAnimBuilder.hx` | Improve error message in `updateIndexedParamsFromDynamicMap` to include programmable name + available params |
| `hx-easy-game std.manim` | Add `width`, `height`, `font` params to `#button`; add `font`, `fontColor` to `#dropdown` and `#list-item-120` |
| Test files | 3-4 visual tests + 3 unit tests for error cases |
