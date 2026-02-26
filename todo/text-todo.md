# Text Element Enhancements

## Current State

The manim `text()` element supports `html: true` which switches from `h2d.Text` to `h2d.HtmlText`.
`loadFont` callback is wired so `<font face="...">` tags work.
Several Heaps capabilities are not yet exposed.

## Heaps h2d.HtmlText Supported Tags

| Tag | What it does |
|-----|-------------|
| `<font color="#RGB" face="name" opacity="0.5">` | Inline color/font/opacity changes |
| `<b>` / `<i>` | Bold/italic via `loadFont("bold")`/`loadFont("italic")` |
| `<img src="...">` | Inline images |
| `<a href="...">` | Clickable hyperlinks |
| `<br/>` / `<p align="...">` | Line breaks, paragraph alignment |
| Custom tags via `defineHtmlTag("damage", 0xFF0000, "boldFont")` | Named style shortcuts |

Callbacks: `loadImage`, `formatText`, `onHyperlink`, `onOverHyperlink`, `onOutHyperlink`

## Heaps h2d.Text Color Segments

`setColorSegments([pos, color, pos, color, ...])` — position-based multi-color text without HTML.

---

## Design: Native Rich Text Markup

### Problem with `html: true`

`html: true` leaks Heaps implementation details into the DSL. The user must know they're
switching to `h2d.HtmlText` and then write raw HTML tags inside a manim string — two languages
mixed in one literal. This is inconsistent with how manim handles everything else declaratively.

### Solution: `{tag}...{/}` markup + `styles:` definitions

Replace HTML-in-strings with a lightweight manim-native markup:

```manim
text(dd, "Deal {damage}50{/} damage for {gold}100g{/}", white, left, 260,
    styles: [damage #FF0000, gold #FFD700 "boldFont", emphasis "italicFont"])
```

- `{styleName}...{/}` in the text string — lightweight, not HTML
- Each style entry: `name [color] ["fontName"]` — either or both, at least one required
- Parser auto-enables rich text mode when it sees `styles:` or `{...}` markers — no `html: true` needed

Inline one-off overrides (no style definition needed):
- `{c:#FF0000}red text{/}` — inline color
- `{f:boldFont}bold text{/}` — inline font switch
- `{c:red}named color{/}` — uses existing named color support from `parseColorOrReference()`

Analogous to: `colorStops:` in particles (inline structured data), `interactive()` metadata (`key => value`).

### Consistency comparison

| Feature | Current (HTML) | Proposed (native) |
|---------|---------------|-------------------|
| Color change | `<font color="#F00">` in string | `{c:#F00}` or `{styleName}` |
| Font change | `<font face="bold">` in string | `{f:bold}` or `{styleName}` |
| Inline image | `<img src="...">` (not wired) | `{img:name}` + `images:` param |
| Named styles | Not available | `styles:` named param |
| Hyperlink | `<a href="...">` (not wired) | `{link:id}` + callback |
| Enable rich mode | `html: true` | Auto-detected from markup |

---

## Layer 1 — Color & Font (priority)

### Named styles

```manim
text(dd, "Deal {damage}50{/} for {gold}100g{/}", white, left, 260,
    styles: [damage #FF0000, gold #FFD700 "boldFont"])
```

- [ ] Parse `styles:` named param — array of `name [color] ["fontName"]`
- [ ] Parse `{styleName}...{/}` markers in text strings
- [ ] Map to Heaps `defineHtmlTag()` at build time
- [ ] Auto-enable HtmlText when styles or markup detected (no `html: true` needed)
- [ ] Builder support with incremental update tracking
- [ ] Codegen support

### Inline color/font overrides

```manim
text(dd, "{c:#FF0000}red{/} and {f:bold}bold{/}", white, left, 260)
```

- [ ] Parse `{c:color}` — inline color (named or hex)
- [ ] Parse `{f:fontName}` — inline font switch
- [ ] Convert to `<font color="..." face="...">` internally for Heaps

### Drop `colorSegments` in favor of `{c:...}` markup

Position-based segments (`colorSegments: [0 #FF0000, 5 #00FF00]`) are fragile when
text content is dynamic (`$param`). The `{c:...}` markup solves the same problem more
robustly and avoids a second feature surface (segment position tracking, index
recalculation on text change).

If plain `h2d.Text` color segments are ever needed for performance, they can be added
later as an optimization under the same `{c:...}` syntax — just a different backend.

## Layer 2 — Inline Images

```manim
text(dd, "Costs {img:gold} 100", white, left, 260,
    images: [gold file("gold.png"), sword sheet("items", "sword_16")])
```

- [ ] Parse `images:` named param — array of `name tileSource [valign] [, spacing]`
- [ ] Image sources reuse existing `parseTileSource()` syntax (`file(...)`, `sheet(...)`, `generated(...)`)
- [ ] Parse `{img:name}` markers in text strings
- [ ] Wire `loadImage` callback in builder to resolve from `images:` definitions
- [ ] Optional per-image params: `gold file("gold.png") middle, 2.0` (valign + spacing)
- [ ] Fix tilegroup codegen path to respect rich text mode (currently always creates plain `h2d.Text`)

## Layer 3 — Alignment & Formatting

```manim
text(dd, "Left\n{align:center}Centered\n{align:right}Right", white, left, 260)
```

- [ ] Parse `{align:left|center|right}` markers — maps to `<p align="...">` internally
- [ ] Add `condenseWhite` named param (bool, default: `true`)

## Layer 4 — Hyperlinks / Interactive Integration

```manim
text(dd, "Click {link:shop}here{/} to open", white, left, 260)
```

- [ ] Parse `{link:id}` markers in text strings
- [ ] Wire `onHyperlink` to fire `callback("link", "shop")` — same pattern as `callback("name", $index)`
- [ ] Later: integration with `UIInteractiveEvent` for full UI support
- [ ] `onOverHyperlink` / `onOutHyperlink` for hover states

## Backward Compatibility

- `html: true` continues to work but is **deprecated** — parser emits a warning suggesting `styles:`
- Raw HTML in strings still renders (Heaps handles it), but new code should use `{...}` markup
- Both can coexist in the same text element during migration
