# VSCode Extension for .manim Language Support

This document describes what the VSCode extension needs to do. The extension lives in a separate repository.

## Overview

The extension provides:
1. **Syntax highlighting** via TextMate grammars for `.manim` files
2. **Language Server client** that launches the Haxe-compiled LSP server from hx-multianim
3. **Language configuration** for bracket matching, comment toggling, folding

The LSP server is compiled from Haxe source in the `hx-multianim` repo (`lsp/` directory) and produces a single `lsp/bin/server.js` file that runs under Node.js.

## Extension Package Structure

```
vscode-manim/
├── package.json
├── tsconfig.json
├── .vscodeignore
├── language-configuration.json
├── syntaxes/
│   └── manim.tmLanguage.json
├── src/
│   └── extension.ts
├── server/
│   └── server.js                  # Copied from hx-multianim/lsp/bin/server.js
└── README.md
```

## package.json

The extension manifest must declare:

### Language contribution

```json
{
  "contributes": {
    "languages": [
      {
        "id": "manim",
        "aliases": ["Manim", "Multi Animation"],
        "extensions": [".manim"],
        "configuration": "./language-configuration.json"
      }
    ],
    "grammars": [
      {
        "language": "manim",
        "scopeName": "source.manim",
        "path": "./syntaxes/manim.tmLanguage.json"
      }
    ]
  }
}
```

### Activation events

```json
{
  "activationEvents": [
    "onLanguage:manim"
  ]
}
```

### Dependencies

```json
{
  "dependencies": {
    "vscode-languageclient": "^9.0.0"
  },
  "devDependencies": {
    "@types/vscode": "^1.85.0",
    "typescript": "^5.3.0",
    "esbuild": "^0.19.0"
  }
}
```

## extension.ts — LSP Client

The extension entry point starts the language server as a child process:

```typescript
import * as path from 'path';
import { workspace, ExtensionContext } from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: ExtensionContext) {
  // Path to the compiled Haxe LSP server
  const serverModule = context.asAbsolutePath(
    path.join('server', 'server.js')
  );

  const serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.stdio },
    debug: { module: serverModule, transport: TransportKind.stdio },
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'manim' }],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher('**/*.manim'),
    },
  };

  client = new LanguageClient(
    'manimLanguageServer',
    'Manim Language Server',
    serverOptions,
    clientOptions
  );

  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) return undefined;
  return client.stop();
}
```

## language-configuration.json

```json
{
  "comments": {
    "lineComment": "//"
  },
  "brackets": [
    ["{", "}"],
    ["(", ")"],
    ["[", "]"]
  ],
  "autoClosingPairs": [
    { "open": "{", "close": "}" },
    { "open": "(", "close": ")" },
    { "open": "[", "close": "]" },
    { "open": "\"", "close": "\"", "notIn": ["string"] }
  ],
  "surroundingPairs": [
    ["{", "}"],
    ["(", ")"],
    ["[", "]"],
    ["\"", "\""]
  ],
  "folding": {
    "markers": {
      "start": "\\{",
      "end": "\\}"
    }
  },
  "wordPattern": "(-?\\d*\\.\\d\\w*)|([^\\`\\~\\!\\%\\^\\&\\*\\(\\)\\-\\=\\+\\[\\{\\]\\}\\\\\\|\\;\\:\\'\\\"\\,\\.\\<\\>\\/\\?\\s]+)",
  "indentationRules": {
    "increaseIndentPattern": ".*\\{[^}]*$",
    "decreaseIndentPattern": "^\\s*\\}"
  }
}
```

## TextMate Grammar (syntaxes/manim.tmLanguage.json)

The grammar must define scopes for the following .manim constructs:

### Scope assignments

| Construct | Scope | Examples |
|-----------|-------|---------|
| Line comments | `comment.line.double-slash.manim` | `// comment` |
| Block comments | `comment.block.manim` | `/* ... */` |
| Element keywords | `keyword.control.manim` | `programmable`, `bitmap`, `text`, `richText`, `ninepatch`, `flow`, `layers`, `mask`, `tilegroup`, `interactive`, `repeatable`, `repeatable2d`, `slot`, `spacer`, `point`, `apply`, `graphics`, `pixels`, `particles`, `stateanim`, `staticRef`, `dynamicRef`, `placeholder`, `curves`, `paths`, `animatedPath`, `import`, `settings`, `transition` |
| Directives | `keyword.other.directive.manim` | `@final`, `@if`, `@any`, `@all`, `@else`, `@default`, `version:` |
| Conditional blocks | `meta.conditional.manim` | `@(param=>value)` |
| Parameter types | `storage.type.manim` | `int`, `uint`, `float`, `bool`, `string`, `color`, `tile` |
| Named elements | `entity.name.tag.manim` | `#name` |
| Parameter references | `variable.other.reference.manim` | `$paramName` |
| Integer literals | `constant.numeric.integer.manim` | `42`, `0xFF` |
| Float literals | `constant.numeric.float.manim` | `3.14` |
| Color literals | `constant.other.color.manim` | `#FF0000`, `#RGB`, `#RRGGBBAA` |
| Strings | `string.quoted.double.manim` | `"hello"` |
| Booleans | `constant.language.boolean.manim` | `true`, `false`, `yes`, `no` |
| Operators | `keyword.operator.manim` | `+`, `-`, `*`, `/`, `%`, `=>`, `!=`, `>=`, `<=` |
| Easing names | `support.function.easing.manim` | `easeInQuad`, `easeOutCubic`, etc. |
| Blend modes | `support.constant.blend.manim` | `add`, `alpha`, `multiply`, `screen` |
| Built-in functions | `support.function.builtin.manim` | `callback()`, `layout()`, `generated()`, `color()`, `file()` |
| Filter names | `support.function.filter.manim` | `outline`, `glow`, `blur`, `saturate`, `brightness`, `grayscale`, `hue`, `dropShadow`, `pixelOutline`, `replaceColor` |
| Properties | `variable.other.property.manim` | `scale:`, `alpha:`, `rotation:`, `tint:`, `layer:`, `filter:`, `blendMode:` |

### Grammar structure tips

1. **Named elements** (`#name`): Match `#` followed by identifier chars. Be careful not to conflict with color literals (`#RRGGBB`) — colors are hex digits only, names contain letters.

   ```json
   {
     "match": "#[a-zA-Z_][a-zA-Z0-9_]*",
     "name": "entity.name.tag.manim"
   }
   ```

2. **Color literals**: Match `#` followed by 3, 6, or 8 hex digits only.

   ```json
   {
     "match": "#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3}(?:[0-9a-fA-F]{2})?)?\\b",
     "name": "constant.other.color.manim"
   }
   ```

   **Important**: Color patterns must be checked BEFORE named element patterns.

3. **References** (`$name`): Match `$` followed by identifier.

   ```json
   {
     "match": "\\$[a-zA-Z_][a-zA-Z0-9_]*",
     "name": "variable.other.reference.manim"
   }
   ```

4. **Conditionals** (`@(...)`): Use begin/end for the `@(` ... `)` block.

5. **Strings**: Handle escape sequences (`\"`, `\\`, etc.).

6. **Easing functions**: Enumerate all valid names as alternation:
   ```
   linear|easeIn(Quad|Cubic|Quart|Quint|Sine|Expo|Circ|Back|Elastic|Bounce)?|easeOut(Quad|...)|easeInOut(Quad|...)
   ```

### Full list of easing names

`linear`, `easeIn`, `easeOut`, `easeInOut`, `easeInQuad`, `easeOutQuad`, `easeInOutQuad`, `easeInCubic`, `easeOutCubic`, `easeInOutCubic`, `easeInQuart`, `easeOutQuart`, `easeInOutQuart`, `easeInQuint`, `easeOutQuint`, `easeInOutQuint`, `easeInSine`, `easeOutSine`, `easeInOutSine`, `easeInExpo`, `easeOutExpo`, `easeInOutExpo`, `easeInCirc`, `easeOutCirc`, `easeInOutCirc`, `easeInBack`, `easeOutBack`, `easeInOutBack`, `easeInElastic`, `easeOutElastic`, `easeInOutElastic`, `easeInBounce`, `easeOutBounce`, `easeInOutBounce`

### Full list of element keywords

`programmable`, `bitmap`, `text`, `richText`, `ninepatch`, `flow`, `layers`, `mask`, `tilegroup`, `interactive`, `repeatable`, `repeatable2d`, `slot`, `spacer`, `point`, `apply`, `graphics`, `pixels`, `particles`, `stateanim`, `staticRef`, `dynamicRef`, `placeholder`, `curves`, `paths`, `animatedPath`, `import`, `settings`, `transition`, `data`, `atlas2`, `palette`, `autotile`

## LSP Server Features

The server (compiled from `hx-multianim/lsp/`) provides these capabilities:

### Diagnostics
- Parses `.manim` files using MacroManimParser
- Reports syntax errors with line/column positions
- Published automatically on document open, change, and save

### Completions
- **Context-aware**: Different completions based on cursor location:
  - Top level: `programmable`, `data`, `curves`, `paths`, `import`, `@final`, etc.
  - Inside programmable body: all element types
  - Inside `particles {}`: particle properties
  - Inside `curves {}`: curve definitions
  - Inside `paths {}`: path commands
  - Inside `animatedPath {}`: path properties
  - Inside `transition {}`: transition types
  - After `filter:`: filter types
  - After `$`: parameter references in scope
  - After `@(`: parameter names for conditionals
- Trigger characters: `$`, `#`, `@`, `:`, `(`
- Supports snippet format for structured elements

### Hover
- Documentation for all element keywords, filter types, parameter types
- Parameter type info for `$references`
- Color preview for color literals

### Document Symbols (Outline)
- Top-level programmables, data blocks, curves, paths, animatedPaths, @final constants
- Named child elements (#name) nested under their parent

### Go to Definition
- `$paramName` → parameter declaration in programmable header
- `#name` → named element definition
- `import "file"` → imported file (future)

## Building the Server

The server is built from the hx-multianim repo:

```bash
# In hx-multianim/
haxe lsp/lsp-server.hxml

# Output: lsp/bin/server.js
```

Copy `lsp/bin/server.js` into the VSCode extension's `server/` directory.

The build uses `-D noheaps` to exclude Heaps framework dependencies. The parser runs in pure-data mode (parsing only, no rendering).

## Future: MCP Integration

The server can optionally connect to a running hx-multianim application's DevBridge (port 9001) for:
- **Live resource validation**: Check font/sprite names against loaded assets
- **Resource completions**: Complete `bitmap()` tiles, `text()` fonts from live data
- **Hot reload on save**: Trigger `.manim` reload in the running app
- **Screenshot preview**: Show rendered output in hover/panel

This requires the game to be running with `-D MULTIANIM_DEV`. The MCP bridge is optional — the LSP works fully offline for syntax/structure features.
