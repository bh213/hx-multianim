# .manim Language Server — TODO

## Current State

Working LSP server in `lsp/` (Haxe compiled to JS, `-D noheaps`).
VS Code extension in `../vs-multianim` (TypeScript client, esbuild bundle, v2.0.0).

**Working features:**
- Diagnostics (parse errors with positions)
- Document symbols (outline: programmables, data, curves, paths, animatedPath, @final, named children)
- Hover documentation (all keywords, parameter types, coordinate systems, filters)
- Completions (context-aware: top-level, element body, particles, curves, paths, filters, param types, $refs, @conditionals, easings)
- Go-to-definition ($param references, #named elements — within same file)

**Build & deploy:**
```
haxe lsp/lsp-server.hxml                    # build server
npm run build-server                         # (from vs-multianim) build + copy
npm run package                              # package .vsix
code --install-extension multianim-2.0.0.vsix --force
```

## Code Improvements

### Diagnostics
- [ ] Show multiple diagnostics (currently stops at first parse error)
- [ ] Add warnings for unused parameters
- [ ] Add warnings for unknown references ($nonexistent)
- [ ] Validate parameter types match usage (e.g. color used where int expected)
- [ ] Validate `staticRef`/`dynamicRef` targets exist in same file
- [ ] `.anim` file diagnostics (currently `.manim` only)

### Completions
- [ ] Parameter value completions (e.g. after `param=>` suggest enum values)
- [ ] Cross-reference completions (#name references, $ref targets from parsed AST)
- [ ] Easing completions in more contexts (transition blocks, animatedPath curve slots)
- [ ] Color name completions (white, red, transparent, etc.)
- [ ] Blend mode completions (add, alpha, multiply, etc.)
- [ ] Sheet/tile name completions from available atlas files
- [ ] Trigger re-completion after snippet insertion

### Hover
- [ ] Show full parameter signature on programmable name hover
- [ ] Show resolved values for @final constants
- [ ] Show element position (x, y) on named element hover
- [ ] Preview colors (VS Code color decorator integration)

### Document Symbols
- [ ] Show `@final` constants as children of their containing programmable
- [ ] Show data fields as children of data blocks
- [ ] Show curve/path names as children of curves{}/paths{} blocks
- [ ] Breadcrumb-friendly ranges (currently uses first text match, not AST position)

### Go-to-Definition
- [ ] Cross-file go-to-definition (follow `import` statements)
- [ ] Go-to-definition for staticRef/dynamicRef targets
- [ ] Go-to-definition for curve/path references in animatedPath
- [ ] Go-to-definition for sheet names → .atlas2 files

### New Features
- [ ] Rename symbol (parameters, #named elements)
- [ ] Find all references
- [ ] Code actions (quick fixes for common errors)
- [ ] Folding ranges (collapse programmable bodies, particle blocks, etc.)
- [ ] Semantic tokens (richer syntax highlighting than TextMate grammar)
- [ ] Workspace-wide symbol search
- [ ] `.anim` file support (separate parser: AnimParser.hx)
- [ ] Formatting/indentation support
- [ ] Signature help for element parameters (e.g. `bitmap(|)` shows expected args)
- [ ] Code lens (show parameter count, usage count)
- [ ] Color picker integration for #RRGGBB values

## Infrastructure

### Testing
- [ ] Add LSP integration tests (send JSON-RPC, verify responses)
- [ ] Test with real .manim files from test/examples/
- [ ] Test error recovery (completions/hover should work in broken files)
- [ ] CI: run `haxe lsp/lsp-server.hxml` as part of build validation

### Robustness
- [ ] Error boundary in each handler (one crash shouldn't kill the server)
- [ ] Incremental document sync (currently full sync — change: 1)
- [ ] Debounce validation on rapid typing
- [ ] Cache parse results (don't re-parse for symbols + diagnostics on same version)

### Extension Client
- [ ] Add output channel for server logs (currently only stderr)
- [ ] Add status bar item showing server state
- [ ] Add "Restart Language Server" command
- [ ] Support `.anim` files in documentSelector
- [ ] Extension settings (enable/disable features, log level)

## Publishing

### Before Publishing to VS Code Marketplace
- [ ] Set a real publisher ID in package.json (currently `undefined_publisher`)
- [ ] Add extension icon (128x128 PNG)
- [ ] Write proper README.md with feature screenshots
- [ ] Add CHANGELOG.md entry for 2.0.0
- [ ] Bump version to 2.0.0 or appropriate semver
- [ ] Test on clean VS Code install (no other Haxe extensions)
- [ ] Verify activation events are correct (currently empty — activates on .manim file open)
- [ ] Decide: bundle server.js in extension or require separate install?
- [ ] Create GitHub release with .vsix artifact
- [ ] `npx @vscode/vsce publish` with PAT token

### Repository Hygiene
- [ ] Add server.js to vs-multianim .gitignore (generated artifact)
- [ ] Add build instructions to vs-multianim README
- [ ] Document the `-D noheaps` conditional compilation approach
- [ ] Consider: should LSP source live in hx-multianim or vs-multianim?
