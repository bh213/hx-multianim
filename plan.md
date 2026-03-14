# Language Server Plan for .manim and .anim

## Architecture Overview

Following the same pattern as the Haxe Language Server (hx-language-server): **write the server in Haxe, compile to JS, run as Node.js process**. This reuses the existing parsers directly — no TypeScript port, no parser drift.

```
┌─────────────────────────────────────┐
│  VSCode Extension (TypeScript)      │
│  - Language client (thin)           │
│  - TextMate grammar (syntax HL)     │
│  - Language configuration           │
└──────────┬──────────────────────────┘
           │ LSP (stdio)
┌──────────▼──────────────────────────┐
│  Language Server (Haxe → JS/Node)   │
│  - MacroManimParser (reused as-is)  │
│  - AnimParser (refactored parse-only│
│    layer, no Heaps deps)            │
│  - LSP handlers in Haxe             │
│  - Optional: MCP bridge to running  │
│    app for live resource completion  │
└─────────────────────────────────────┘
```

**Why Haxe→JS instead of TypeScript rewrite:**
- Single source of truth — `MacroManimParser.hx` is already the parser
- No maintenance burden from keeping two parsers in sync
- MacroManimParser is already macro-safe (no Heaps deps in parse path)
- Proven pattern: hx-language-server does exactly this
- Haxe's JS target produces clean, fast JavaScript

## JS Compilation Feasibility

### MacroManimParser (.manim) — READY
- Pure lexer + recursive descent parser + AST
- All Heaps imports are behind `#if !macro` guards
- Output is `MultiAnimResult` (pure data: `Map<String, Node>`)
- Dependencies are all JS-compatible: `ParsePosition`, `ParseError`, `ColorUtils`, `ParseUtils`, `CoordinateSystems`, `LayoutTypes`, `MacroCompatTypes`

### AnimParser (.anim) — NEEDS REFACTORING
- Has hard Heaps deps: `AnimationSM extends h2d.Object`, `h2d.filter.*`, `h3d.Matrix`, `h2d.col.IPoint`
- **Required refactoring**: Split into two layers:
  1. `AnimParserCore` — pure parsing → `AnimParseResult` (AST data only, no Heaps types)
  2. `AnimParser` — existing class, imports `AnimParserCore`, adds `createAnimSM()` and Heaps-dependent runtime
- The LSP only needs `AnimParserCore`
- Refactoring scope: ~200-300 lines of type extraction, rest stays unchanged

## Components

### 1. VSCode Extension Client (`vscode-manim/`)

Minimal TypeScript — just launches the Haxe-compiled LSP server.

**Files:**
- `package.json` — Extension manifest, language contributions, activation events
- `syntaxes/manim.tmLanguage.json` — TextMate grammar for .manim
- `syntaxes/anim.tmLanguage.json` — TextMate grammar for .anim
- `language-configuration-manim.json` — Bracket pairs, auto-close, comments, folding
- `language-configuration-anim.json` — Same for .anim
- `src/extension.ts` — Starts LSP client, points to `server/bin/server.js`

### 2. Language Server (`vscode-manim/server/`)

Written in Haxe, compiled to JS via `haxe -js bin/server.js`.

**Haxe source files:**
- `src/ManimLanguageServer.hx` — LSP server main: stdio transport, JSON-RPC, capability registration
- `src/ManimDiagnostics.hx` — Parse errors → LSP Diagnostics
- `src/ManimCompletions.hx` — Context-aware completions
- `src/ManimHover.hx` — Hover documentation
- `src/ManimSymbols.hx` — Document outline (symbols)
- `src/ManimDefinitions.hx` — Go-to-definition
- `src/LspTypes.hx` — LSP protocol types (Position, Range, Diagnostic, etc.)
- `src/LspTransport.hx` — stdio JSON-RPC transport layer
- `src/McpBridge.hx` — Optional DevBridge HTTP client for live resource queries

**Build:**
```hxml
# lsp-server.hxml
-cp server/src
-cp src                          # reuse existing parser source
-lib format
-main ManimLanguageServer
-js server/bin/server.js
-D lsp                          # conditional flag to exclude runtime-only code
```

### 3. MCP Integration (phase 2)

Extend the existing DevBridge / `@bh213/hx-multianim-mcp` with LSP-adjacent tools:
- `eval_manim` already exists for validation
- Add `manim_completions` — completions at cursor position (resource-aware)
- LSP server optionally connects to `localhost:9001` for live resource data

---

## Implementation Plan

### Phase 0: AnimParser Refactoring (prerequisite)

**Goal:** Split AnimParser so the pure parsing layer compiles to JS.

**Step 0.1: Extract `AnimParseResult` types**
- Create `AnimParserTypes.hx` with pure data types:
  - `AnimParseResult` — states, metadata, animation descriptors, constants (no `AnimationSM`)
  - `AnimationDef` — parsed animation data (fps, loop, playlist entries, filters, extrapoints)
  - `AnimFilterDef` — filter descriptors (enum, no `h2d.filter.*`)
  - `AnimConditionalSelector` — already pure, just needs separation
- Replace `h2d.col.IPoint` with `{x:Int, y:Int}` in parse output

**Step 0.2: Split AnimParser**
- `AnimParserCore.hx` — pure parsing, returns `AnimParseResult` (no Heaps imports)
- `AnimParser.hx` — extends/wraps core, adds `createAnimSM()`, filter construction, tile loading
- Existing callers unchanged — `AnimParser` API preserved

**Step 0.3: Verify JS compilation**
- Create `lsp-server.hxml` targeting JS
- Compile `MacroManimParser` + `AnimParserCore` → verify no Heaps deps leak through
- Run basic parse test in Node.js

### Phase 1: TextMate Grammar + Language Configuration

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

### Phase 2: Language Server Core (Haxe → JS)

**Step 2.1: LSP transport layer (Haxe)**
- Implement stdio JSON-RPC reader/writer in Haxe
- `Content-Length` header parsing
- JSON-RPC message dispatch (method → handler map)
- LSP lifecycle: `initialize` → `initialized` → `shutdown` → `exit`

**Step 2.2: Document sync**
- `textDocument/didOpen` — store document text in memory
- `textDocument/didChange` — update stored text (full sync mode initially)
- `textDocument/didClose` — remove from memory
- On change: debounced re-parse (300ms)

**Step 2.3: Diagnostics**
- On document change, call `MacroManimParser.parseFile()` or `AnimParserCore.parse()`
- Catch `InvalidSyntax` / `MultiAnimUnexpected` / `AnimUnexpected`
- Map `ParsePosition` (line, col, source) → LSP `Diagnostic` (range, severity, message)
- Push via `textDocument/publishDiagnostics`

**Step 2.4: Completions**

Context-aware completion based on cursor position. The server needs a lightweight "where am I?" analysis — walk the token stream up to cursor position and determine the enclosing context.

| Context | Completions |
|---------|------------|
| Top level | `#name programmable`, `#name data`, `#name curves`, `#name paths`, `#name animatedPath`, `import`, `@final`, `version:` |
| Inside programmable body | Element keywords: `bitmap`, `text`, `richText`, `ninepatch`, `flow`, `layers`, `mask`, `interactive`, `slot`, `spacer`, `point`, `apply`, `graphics`, `pixels`, `particles`, `repeatable`, `staticRef`, `dynamicRef`, `placeholder`, `tilegroup`, `stateanim`, `settings`, `transition` |
| After `filter:` | `outline`, `glow`, `blur`, `saturate`, `brightness`, `grayscale`, `hue`, `dropShadow`, `pixelOutline`, `replacePalette`, `replaceColor`, `group`, `none` |
| Parameter type position | `int`, `uint`, `float`, `bool`, `string`, `color`, `tile` |
| Inside `particles {}` | `count`, `emit`, `tiles`, `loop`, `maxLife`, `speed`, `gravity`, `size`, `blendMode`, `fadeIn`, `fadeOut`, `colorStops`, `forceFields`, `bounds`, etc. |
| Inside `paths {}` | `moveTo`, `lineTo`, `bezier`, `quadratic`, `arc`, `close` |
| Inside `curves {}` | `easing`, `points`, `multiply`, `apply`, `invert`, `scale` |
| Inside `animatedPath {}` | `path`, `type`, `duration`, `speed`, `loop`, `pingPong`, `easing` + curve slots |
| After `@(` | Parameter names from enclosing programmable |
| After `$` | Parameter refs + `$grid`, `$hex`, `$ctx` |
| Easing position | All easing function names |
| Inside `transition {}` | `none`, `fade`, `crossfade`, `flipX`, `flipY`, `slide` |

**Step 2.5: Hover information**
- Element keywords → brief description + syntax
- Parameter types → description + valid values
- Filter types → parameter list
- Easing names → description
- `$references` → parameter definition (type, default)
- Color values → color preview swatch (via markdown)
- `#names` → definition location

**Step 2.6: Document symbols (outline)**
- `#name programmable(...)` → Class
- `#name data {...}` → Struct
- `#name curves {...}` → Namespace
- `#name paths {...}` → Namespace
- `#name animatedPath {...}` → Function
- `@final name = ...` → Constant
- Named `#name` elements → Field
- `import` → Module

**Step 2.7: Go-to-definition**
- `$paramName` → parameter declaration in `programmable()` header
- `staticRef($ref)` / `dynamicRef($ref)` → referenced programmable
- `import "file"` → open imported file
- `path: pathName` → path definition in `paths {}`
- Curve references → curve definition in `curves {}`

### Phase 3: MCP Integration

**Step 3.1: Live resource validation via DevBridge**
- LSP optionally connects to `localhost:9001` (DevBridge HTTP)
- Use `eval_manim` for validation against actual loaded resources
- Show warnings for missing fonts, unknown sprite sheets

**Step 3.2: Resource completions from running app**
- `list_fonts` → complete font names in `text()` calls
- `list_atlases` → complete sprite sheet + tile names in `bitmap()`
- `list_builders` → complete `staticRef`/`dynamicRef` targets
- `list_resources` → complete file references

**Step 3.3: Live preview**
- On save, trigger `reload` for hot-reload
- Show `screenshot` in hover/sidebar

---

## File Structure

```
vscode-manim/
├── package.json                         # Extension manifest
├── tsconfig.json                        # For extension client only
├── .vscodeignore
├── language-configuration-manim.json
├── language-configuration-anim.json
├── syntaxes/
│   ├── manim.tmLanguage.json
│   └── anim.tmLanguage.json
├── src/
│   └── extension.ts                     # LSP client (thin, just starts server)
├── server/
│   ├── lsp-server.hxml                  # Haxe → JS build config
│   ├── src/
│   │   ├── ManimLanguageServer.hx       # LSP main: init, dispatch, shutdown
│   │   ├── LspTransport.hx             # stdio JSON-RPC transport
│   │   ├── LspTypes.hx                 # LSP protocol types
│   │   ├── DocumentStore.hx            # Open document text storage
│   │   ├── ManimDiagnostics.hx         # Parse errors → Diagnostics
│   │   ├── ManimCompletions.hx         # Context completions
│   │   ├── ManimHover.hx              # Hover docs
│   │   ├── ManimSymbols.hx            # Document outline
│   │   ├── ManimDefinitions.hx        # Go-to-definition
│   │   └── McpBridge.hx               # Optional DevBridge client
│   └── bin/
│       └── server.js                    # Compiled output (git-tracked or built)
└── README.md
```

**Changes to existing hx-multianim source:**
```
src/bh/stateanim/
├── AnimParserTypes.hx                   # NEW: Pure parse result types
├── AnimParserCore.hx                    # NEW: Pure parsing (no Heaps)
└── AnimParser.hx                        # MODIFIED: wraps AnimParserCore
```

## Implementation Priority

1. **Phase 0: AnimParser refactoring** (unblocks .anim LSP, small scope)
2. **Phase 1: TextMate grammars** (highest value/effort — instant syntax highlighting)
3. **Phase 2: LSP core** (diagnostics first, then completions, then the rest)
4. **Phase 3: MCP bridge** (nice-to-have, requires running game)

## Build & Distribution

- Extension published to VS Code Marketplace as `vscode-manim`
- Server JS bundled inside extension (no separate install)
- `vsce package` to create `.vsix`
- CI: compile Haxe server → build extension → package

## Risks & Mitigations

- **LSP in Haxe**: Haxe's JS output is clean but we need to implement JSON-RPC transport from scratch (or use a minimal npm package via Haxe externs). The Haxe language server itself does this, so there's prior art.
- **Completions need error recovery**: The parser currently throws on first error. For completions, we need to parse partial/incomplete files. Mitigation: wrap parse in try/catch, use token-level context analysis for completions (don't need full AST for "where am I?").
- **AnimParser refactoring**: Moderate risk — need to ensure no behavioral change for existing callers. Mitigation: existing tests cover parser output thoroughly.
