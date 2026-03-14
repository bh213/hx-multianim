# Language Server Plan for .manim

## Status

**Implemented (hx-multianim side):**
- `noheaps` conditional compilation flag — guards Heaps imports so parser compiles to JS
- LSP server in Haxe (`lsp/src/manim/lsp/`) — transport, diagnostics, completions, hover, symbols, go-to-def
- Build config (`lsp/lsp-server.hxml`) — compiles to `lsp/bin/server.js`
- VSCode extension spec (`docs/vscode-extension.md`) — everything the extension repo needs

**To do (separate VSCode extension repo):**
- TextMate grammar (`manim.tmLanguage.json`)
- Language configuration (brackets, comments, folding)
- Extension client (thin TypeScript — just starts the server)
- Package and publish to VS Marketplace

**Future:**
- .anim language support (requires AnimParser refactoring)
- MCP bridge for live resource validation/completion from running app

## Architecture

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

## Changes to hx-multianim

### `-D noheaps` flag

A new conditional compilation flag that excludes Heaps-dependent code. Used alongside `#if macro` guards that already existed:

- `#if (!macro && !noheaps)` — replaces `#if !macro` in files that reference Heaps types
- Affected files:
  - `src/bh/base/GridDirection.hx` — `hxd.Math` import guarded, `Math.iabs` replaced with inline abs
  - `src/bh/base/Hex.hx` — `h2d.col.Point` import guarded, macro-safe Point substitute reused
  - `src/bh/base/FPoint.hx` — `h2d.col.Point` conversion methods guarded
  - `src/bh/base/Point.hx` — `h2d.col.IPoint` conversion methods guarded
  - `src/bh/multianim/MultiAnimParser.hx` — runtime types (`BuiltHeapsComponent`, `NamedBuildResult`, `MultiAnimParser` class, `TSTile` enum variant) guarded

### LSP server source (`lsp/`)

```
lsp/
├── lsp-server.hxml                      # Build: haxe lsp/lsp-server.hxml
├── bin/
│   └── server.js                        # Compiled output
└── src/manim/lsp/
    ├── ManimLanguageServer.hx           # Main: stdio transport, JSON-RPC dispatch, lifecycle
    ├── LspTransport.hx                  # Content-Length framed stdin/stdout via Node.js APIs
    ├── LspTypes.hx                      # LSP protocol types (Position, Range, Diagnostic, etc.)
    ├── DocumentManager.hx               # Open document text storage
    ├── ManimAnalyzer.hx                 # Parse → diagnostics, symbols, hover, go-to-def
    ├── ContextAnalyzer.hx               # Cursor context detection for completions
    ├── CompletionProvider.hx            # Context-aware completion items
    └── HoverProvider.hx                 # Hover documentation for keywords/types
```

### Build

```bash
haxe lsp/lsp-server.hxml
# → lsp/bin/server.js (single file, runs with Node.js)
```

## LSP Features

| Feature | Method | Description |
|---------|--------|-------------|
| Diagnostics | `textDocument/publishDiagnostics` | Parse errors from MacroManimParser |
| Completions | `textDocument/completion` | Context-aware: elements, filters, params, easings, etc. |
| Hover | `textDocument/hover` | Docs for keywords, types, filters, $references |
| Symbols | `textDocument/documentSymbol` | Outline: programmables, data, curves, paths, constants |
| Go-to-def | `textDocument/definition` | $param → declaration, #name → definition |

## Completion Contexts

| Cursor location | Offered completions |
|-----------------|-------------------|
| Top level | `programmable`, `data`, `curves`, `paths`, `animatedPath`, `import`, `@final` |
| Programmable body | All element keywords + properties |
| `particles {}` | Particle properties (count, emit, speed, etc.) |
| `curves {}` | Curve definitions |
| `paths {}` | Path commands (lineTo, bezier, etc.) |
| `animatedPath {}` | Path properties + curve slots |
| `transition {}` | Transition types (fade, crossfade, slide, etc.) |
| After `filter:` | Filter types (outline, glow, blur, etc.) |
| After `$` | Parameter names in scope + $grid, $hex, $ctx |
| After `@(` | Parameter names for conditionals |
