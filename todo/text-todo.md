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

## Layer 1 — Wire What's Already There

- [ ] Wire `loadImage` callback in `createHtmlText()` to `resourceLoader.loadTile()`
- [ ] Add `imageVerticalAlign` named param (`top`, `bottom`, `middle`; default: `bottom`)
- [ ] Add `imageSpacing` named param (float, default: `1.0`)
- [ ] Fix tilegroup codegen path to respect `isHtml` (currently always creates plain `h2d.Text`)

## Layer 2 — Color Segments for Plain Text

- [ ] Add `colorSegments` named param for position-based multi-color without HTML
- [ ] Syntax idea: `colorSegments: [0 #FF0000, 5 #00FF00]`
- [ ] Builder support with incremental update tracking
- [ ] Codegen support

## Layer 3 — HTML Text Configuration

- [ ] Add `condenseWhite` named param (bool, default: `true`)
- [ ] Custom HTML tag definitions, e.g.: `tags: [damage #FF0000 "boldFont", gold #FFD700]`

## Layer 4 — Hyperlink / Interactive Support

- [ ] Wire `onHyperlink` to manim event/callback system
- [ ] Integration with `UIInteractiveEvent` or new callback type
