# Language Server Plan for .manim and .anim

## Architecture Overview

```
┌─────────────────────────────────────┐
│  VSCode Extension (TypeScript)      │
│  - Language client                  │
│  - TextMate grammar (syntax HL)     │
│  - Language configuration           │
│  - Extension activation on .manim   │
│    and .anim files                  │
└──────────┬──────────────────────────┘
           │ LSP (stdio)
┌──────────▼──────────────────────────┐
│  Language Server (TypeScript/Node)  │
│  - Parses .manim and .anim files   │
│  - Diagnostics (errors/warnings)   │
│  - Completions                     │
│  - Hover info                      │
│  - Go-to-definition               │
│  - Document symbols                │
│  - Bracket matching/folding        │
│  - Optional: MCP bridge to running │
│    app for live preview/inspect    │
└─────────────────────────────────────┘
```

## Components

### 1. VSCode Extension Package (`vscode-manim/`)

**Files:**
- `package.json` — Extension manifest, language contributions, activation events
- `syntaxes/manim.tmLanguage.json` — TextMate grammar for .manim
- `syntaxes/anim.tmLanguage.json` — TextMate grammar for .anim
- `language-configuration-manim.json` — Bracket pairs, auto-close, comments, folding
- `language-configuration-anim.json` — Same for .anim
- `src/extension.ts` — Extension entry point, starts LSP client
- `tsconfig.json`, `.vscodeignore`

### 2. Language Server (`vscode-manim/server/`)

**Technology choice: TypeScript + `vscode-languageserver`**

Rationale: The Haxe parser runs at compile-time (macros) and at runtime (HashLink VM). Neither is practical to run as a long-lived LSP server process. A TypeScript reimplementation of the parser subset needed for LSP is the pragmatic choice — it runs natively in Node.js, starts instantly, and integrates cleanly with the VSCode LSP ecosystem. We only need parsing for diagnostics/completions, not the full builder/renderer pipeline.

**Files:**
- `server/src/server.ts` — LSP server entry, document sync, capability registration
- `server/src/manim-parser.ts` — Simplified .manim parser (tokenizer + recursive descent)
- `server/src/anim-parser.ts` — Simplified .anim parser
- `server/src/diagnostics.ts` — Error → LSP Diagnostic conversion
- `server/src/completions.ts` — Context-aware completions
- `server/src/hover.ts` — Hover documentation provider
- `server/src/symbols.ts` — Document symbol provider (outline)
- `server/src/types.ts` — Shared types

### 3. MCP Tool (optional, phase 2)

Extend the existing DevBridge (or the npm MCP wrapper `@bh213/hx-multianim-mcp`) with LSP-adjacent tools:
- `manim_validate` — Send .manim source, get parse errors (already exists as `eval_manim`)
- `manim_completions` — Get completions at a cursor position
- `manim_hover` — Get hover info for a position

This bridges the running game with the editor for live validation against actual loaded resources (fonts, sprite sheets, etc.).

---

## Implementation Plan

### Phase 1: TextMate Grammar + Language Configuration (syntax highlighting only)

**Step 1.1: Create extension scaffold**
- `vscode-manim/package.json` with language contributions for `.manim` and `.anim`
- Register `manim` and `anim` language IDs
- Activation events: `onLanguage:manim`, `onLanguage:anim`

**Step 1.2: .manim TextMate grammar**

Scopes to highlight:
- **Comments**: `//` line comments → `comment.line.double-slash.manim`
- **Keywords**: `programmable`, `bitmap`, `text`, `richText`, `ninepatch`, `flow`, `layers`, `mask`, `tilegroup`, `interactive`, `repeatable`, `repeatable2d`, `slot`, `spacer`, `point`, `apply`, `graphics`, `pixels`, `particles`, `stateanim`, `staticRef`, `dynamicRef`, `placeholder`, `curves`, `paths`, `animatedPath`, `import`, `settings`, `transition`, `filter` → `keyword.control.manim`
- **Constants/directives**: `@final`, `@if`, `@ifstrict`, `@else`, `@default`, `version:` → `keyword.other.manim`
- **Conditionals**: `@(...)` blocks → `meta.conditional.manim`
- **Parameter types**: `int`, `uint`, `float`, `bool`, `string`, `color`, `tile` → `storage.type.manim`
- **Named elements**: `#name` → `entity.name.tag.manim`
- **References**: `$paramName` → `variable.other.reference.manim`
- **Numbers**: integers, floats, hex → `constant.numeric.manim`
- **Colors**: `#RGB`, `#RRGGBB`, `#RRGGBBAA` → `constant.other.color.manim`
- **Strings**: `"quoted strings"` → `string.quoted.double.manim`
- **Easing names**: `easeInQuad`, `easeOutCubic`, etc. → `support.function.easing.manim`
- **Operators**: `+`, `-`, `*`, `/`, `%`, `=>`, `!=`, `>=`, `<=` → `keyword.operator.manim`
- **Booleans**: `true`, `false`, `yes`, `no` → `constant.language.boolean.manim`
- **Blend modes**: `add`, `alpha`, `multiply`, `screen`, etc. → `support.constant.blend.manim`
- **Built-in functions**: `callback()`, `layout()`, `generated()`, `color()`, `file()` → `support.function.manim`

**Step 1.3: .anim TextMate grammar**

Scopes:
- **Block keywords**: `animation`, `playlist`, `filters`, `extrapoints`, `metadata`, `event` → `keyword.control.anim`
- **Top-level keywords**: `sheet:`, `states:`, `center:`, `fps:`, `loop:`, `allowedExtraPoints:`, `anim` → `keyword.other.anim`
- **State interpolation**: `${stateName}` in strings → `variable.other.interpolation.anim`
- **Conditionals**: `@(state=>value)`, `@else`, `@default` → `meta.conditional.anim`
- **Filter types**: `tint`, `brightness`, `saturate`, `grayscale`, `hue`, `outline`, `pixelOutline`, `replaceColor` → `support.function.filter.anim`
- **Constants**: `@final NAME = value` → `keyword.other.anim` + `constant.other.anim`
- **Colors, numbers, strings**: Same scopes as .manim

**Step 1.4: Language configuration files**
- Bracket pairs: `{}`, `()`, `[]`
- Auto-closing: `{}`, `()`, `[]`, `""`
- Comment toggling: `//`
- Folding markers: `{`/`}` blocks
- Word pattern: includes `$`, `#`, `@` characters

### Phase 2: Language Server (diagnostics + completions)

**Step 2.1: LSP server scaffold**
- `vscode-languageserver` + `vscode-languageclient` npm packages
- Full document sync (open/change/close)
- Wire diagnostics on document change (debounced)

**Step 2.2: .manim tokenizer (TypeScript port)**

Port the essential parts of `MacroManimParser`'s lexer:
- Token types: `Identifier`, `Reference` (`$name`), `Name` (`#name`), `QuotedString`, `Number`, `Color`, `OpenBrace`, `CloseBrace`, `OpenParen`, `CloseParen`, `Comma`, `Colon`, `At`, `Arrow` (`=>`), `Operator`, `EOF`
- Track line/column for every token
- Handle string interpolation markers

**Step 2.3: .manim parser (TypeScript port)**

Simplified recursive descent — enough to identify:
- Top-level definitions (programmable, data, curves, paths, animatedPath, import, @final)
- Parameter declarations with types
- Element types in body (bitmap, text, flow, etc.)
- Conditional blocks `@()`
- Nested `{}` block structure
- Settings blocks
- Transition blocks

We do NOT need to replicate the full builder/resolver pipeline. The parser needs to:
1. Produce a lightweight AST with positions
2. Detect and report syntax errors with line/column
3. Track which context we're in (for completions)

**Step 2.4: Diagnostics**
- Parse on every document change (debounced 300ms)
- Map parser errors to LSP `Diagnostic` objects with severity, range, message
- Report: missing braces, unknown element types, type mismatches in parameters, missing required fields

**Step 2.5: Completions**

Context-aware completion based on cursor position:

| Context | Completions |
|---------|------------|
| Top level | `#name programmable`, `#name data`, `#name curves`, `#name paths`, `#name animatedPath`, `import`, `@final`, `version:` |
| Inside programmable body | Element keywords: `bitmap`, `text`, `richText`, `ninepatch`, `flow`, `layers`, `mask`, `interactive`, `slot`, `spacer`, `point`, `apply`, `graphics`, `pixels`, `particles`, `repeatable`, `staticRef`, `dynamicRef`, `placeholder`, `tilegroup`, `stateanim`, `settings`, `transition` |
| After `filter:` | Filter types: `outline`, `glow`, `blur`, `saturate`, `brightness`, `grayscale`, `hue`, `dropShadow`, `pixelOutline`, `replacePalette`, `replaceColor`, `group`, `none` |
| Parameter type position | `int`, `uint`, `float`, `bool`, `string`, `color`, `tile` |
| Inside `particles {}` | Particle properties: `count`, `emit`, `tiles`, `loop`, `maxLife`, `speed`, `gravity`, `size`, `blendMode`, `fadeIn`, `fadeOut`, `colorStops`, `forceFields`, etc. |
| Inside `paths {}` | Path commands: `moveTo`, `lineTo`, `bezier`, `quadratic`, `arc`, `close` |
| Inside `curves {}` | Curve properties: `easing`, `points`, `multiply`, `apply`, `invert`, `scale` |
| Inside `animatedPath {}` | Properties: `path`, `type`, `duration`, `speed`, `loop`, `pingPong`, `easing` + curve slots |
| After `@(` | Available parameter names from enclosing programmable |
| After `$` | Parameter references from enclosing programmable + `$grid`, `$hex`, `$ctx` |
| After easing position | All easing function names |
| Inside `transition {}` | Transition types: `none`, `fade`, `crossfade`, `flipX`, `flipY`, `slide` |
| Inside `settings {}` | Setting keys based on context |

**Step 2.6: Hover information**
- Element keywords → brief description + syntax
- Parameter types → description + valid values
- Filter types → parameter list
- Easing names → description
- `$references` → parameter definition (type, default)
- Color values → color preview swatch (via markdown)
- `#names` → definition location

**Step 2.7: Document symbols (outline)**
- Top-level `#name programmable(...)` → Symbol kind: Class
- `#name data {...}` → Symbol kind: Struct
- `#name curves {...}` → Symbol kind: Namespace
- `#name paths {...}` → Symbol kind: Namespace
- `#name animatedPath {...}` → Symbol kind: Function
- `@final name = ...` → Symbol kind: Constant
- Named elements `#name` inside body → Symbol kind: Field
- `import` statements → Symbol kind: Module

**Step 2.8: Go-to-definition**
- `$paramName` → jump to parameter declaration in `programmable()` header
- `staticRef($ref)` / `dynamicRef($ref)` → jump to referenced programmable definition
- `#name` references → jump to named element definition
- `import "file"` → open imported file
- `path: pathName` in animatedPath → jump to path definition in `paths {}`
- Curve references → jump to curve definition in `curves {}`

### Phase 3: .anim Language Server Support

**Step 3.1: .anim tokenizer + parser (TypeScript)**
- Similar approach to .manim but simpler grammar
- Track: `sheet:`, `states:`, `animation {}`, `playlist {}`, `filters {}`, `extrapoints {}`, `metadata {}`
- Validate state variable references `${stateName}` against `states:` declarations
- Validate `@final` constant usage

**Step 3.2: .anim diagnostics**
- Undefined state variable in `${...}` interpolation
- Invalid filter names
- Missing required fields (`sheet:`)
- Duplicate animation names

**Step 3.3: .anim completions**
- Top level: `sheet:`, `states:`, `center:`, `fps:`, `loop:`, `animation`, `anim`, `@final`, `metadata`, `allowedExtraPoints:`
- Inside `animation {}`: `fps:`, `loop:`, `playlist {}`, `filters {}`, `extrapoints {}`
- Inside `filters {}`: filter type names
- Inside `playlist {}`: `sheet:`, `event`, `filter`
- Conditional triggers: `@(`, `@else`, `@default`

### Phase 4: MCP Integration (optional)

**Step 4.1: Live validation via DevBridge**
- When the game is running with DevBridge, the LSP can optionally connect to `localhost:9001`
- Use `eval_manim` tool to validate against actual loaded resources (real font names, sprite sheet tiles)
- Show warnings for resources that exist syntactically but aren't loaded in the running app

**Step 4.2: Resource completions from running app**
- Query `list_resources` → complete `bitmap()` tile names, font names
- Query `list_fonts` → complete font references in `text()` calls
- Query `list_atlases` → complete sprite sheet + tile names
- Query `list_builders` → complete `staticRef`/`dynamicRef` targets

**Step 4.3: Live preview**
- On save, trigger `reload` to hot-reload changed .manim in running app
- Show `screenshot` thumbnail in hover/sidebar

---

## File Structure

```
vscode-manim/
├── package.json                         # Extension manifest
├── tsconfig.json
├── .vscodeignore
├── language-configuration-manim.json
├── language-configuration-anim.json
├── syntaxes/
│   ├── manim.tmLanguage.json
│   └── anim.tmLanguage.json
├── src/
│   └── extension.ts                     # LSP client startup
├── server/
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── server.ts                    # LSP server main
│       ├── manim-parser.ts              # .manim tokenizer + parser
│       ├── anim-parser.ts               # .anim tokenizer + parser
│       ├── diagnostics.ts               # Error → Diagnostic mapping
│       ├── completions.ts               # Context completions
│       ├── hover.ts                     # Hover docs
│       ├── symbols.ts                   # Document outline
│       ├── definitions.ts               # Go-to-definition
│       ├── mcp-bridge.ts               # Optional DevBridge connection
│       └── types.ts                     # Shared types
└── README.md
```

## Implementation Priority

1. **TextMate grammars** (highest value per effort — instant syntax highlighting)
2. **Diagnostics** (catch errors without compiling)
3. **Completions** (productivity boost — language has many keywords)
4. **Document symbols** (navigate large .manim files)
5. **Hover** (inline documentation)
6. **Go-to-definition** (cross-reference navigation)
7. **MCP bridge** (live resource validation — nice-to-have)

## Dependencies

```json
{
  "devDependencies": {
    "@types/vscode": "^1.85.0",
    "@types/node": "^20.0.0",
    "typescript": "^5.3.0",
    "esbuild": "^0.19.0"
  },
  "dependencies": {
    "vscode-languageclient": "^9.0.0",
    "vscode-languageserver": "^9.0.0",
    "vscode-languageserver-textdocument": "^1.0.0"
  }
}
```

## Risk / Notes

- **Parser fidelity**: The TypeScript parser does NOT need to be 100% compatible with the Haxe parser. It needs to handle ~95% of valid syntax for completions/diagnostics. Edge cases in expressions and macro codegen paths can be skipped.
- **Maintenance burden**: As the .manim language evolves, the TypeScript parser needs updating. Mitigate by keeping it simple and documenting which Haxe parser features map to which TS code.
- **Alternative**: Could use the existing `eval_manim` MCP tool for validation instead of a local parser, but this requires a running game instance and adds latency. The local parser is better for the core editing loop; MCP is a supplement.
