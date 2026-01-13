# AI Agent Guidelines

## Project Overview
This is an hx-multianim project - a Haxe-based animation and UI framework.

## Key Technologies
- **Language**: Haxe
- **Parser**: hxparse (stream-based lexer/parser)
- **Main Files**:
  - `src/bh/multianim/MultiAnimParser.hx` - Parser for .manim animation files
  - `src/bh/multianim/MultiAnimBuilder.hx` - Builder for resolving parsed structures
  - `playground/` - Web-based playground for testing

## Important Notes

### Parser Pattern Matching
- hxparse pattern matching only matches on the **first element** of a case pattern
- Use nested `switch` statements for multi-token matching
- Example: For `[Token1, Token2, Token3]`, create separate switches for each token
- Check https://github.com/Simn/hxparse for more details

### Workflow
1. **Parsing**: Converts .manim file text to AST with `Node` structures
2. **Building**: Resolves references, expressions, and type conversions

## Guidelines for Modifications

1. **Always compile after changes**: Run `haxe hx-multianim.hxml`
2. **Test with manim files**: Verify changes work with files in `playground/public/assets/`
3. **Keep types consistent**: Use the established enum/typedef pattern
4. **Document complex parsing**: Add comments explaining stream patterns
5. **Update related files**: If changing parser, check builder and UI layer compatibility

## Build & Test
```bash
# Compile
haxe ./hx-multianim.hxml

# Run playground (requires Node.js)
cd playground
npm run dev
```

