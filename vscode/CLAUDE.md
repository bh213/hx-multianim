# vscode/ — VS Code Extension

VS Code extension providing syntax highlighting and language server for `.manim` and `.anim` files. Moved from the standalone `vs-multianim` repo into `hx-multianim/vscode/`.

## Structure

```
vscode/
├── src/extension.ts                # Extension entry point (LSP client)
├── server/server.js                # Compiled LSP server (from lsp/bin/)
├── syntaxes/
│   ├── multianim.tmLanguage.json   # TextMate grammar for .manim
│   └── anim.tmLanguage.json        # TextMate grammar for .anim
├── language-configuration.json     # Comments, brackets, auto-close
├── package.json                    # Extension metadata (v2.0.0, VS Code ^1.87.0)
├── sync-check.js                   # Validates keywords match parser
└── install-local.bat               # Build + install locally
```

## Install

```batch
:: From dotabota/ root:
install-hx-multianim-to-vscode.bat

:: Or from this directory:
install-local.bat
```

Reload VS Code after installing.

## Build LSP Server

```bash
npm run build-server   # compiles Haxe LSP and copies to server/
```

## Keyword Sync

```bash
node sync-check.js
# Compares keywords in ../src/bh/multianim/MacroManimParser.hx
# against syntaxes/multianim.tmLanguage.json
```

## Grammar Coverage

The `.manim` grammar highlights: keywords (100+), variables (`$var`, `$$interpolated$$`), tags (`#tagname`), conditional directives (`@if`, `@else`, `@default`), color values, numbers (hex/float/int), operators, type names, easing functions, blend modes, and filter functions.
