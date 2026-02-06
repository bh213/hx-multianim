Technical docs
--------------

This document is intended to provide a high-level overview of the technical aspects of the project. 



## UIElements

## Dropdown
dropdown control consists of closed-like button and scrollable panel (called panel). dropdown control moves panel to different layer and keeps position in sync with PositionLinkObject.

## Elements handling by UIScreen
If elements are not showing or reacting to events check if they have been added to UIScreen's elements.



## Macros
```haxe
		var res = MacroUtils.macroBuildWithParameters(componentsBuilder, "ui", [], [
				checkbox1=>addCheckbox(builder,  true),
				checkbox2=>addCheckbox(builder,  true),
				checkbox3=>addCheckbox(builder,  true),
				checkbox4=>addCheckbox(builder,  true),
				checkbox5=>addCheckbox(builder,  true),
				scroll1=>addScrollableList(builder, 100, 120, list4, -1),
				scroll2=>addScrollableList(builder, 100, 120, list100, 10),
				scroll3=>addScrollableList(builder, 100, 120, list20, 3),
				scroll4=>addScrollableList(builder, 100, 120, list20disabled, 3),
				checkboxWithLabel=>addCheckboxWithText(builder, "my label", true),
				//function addDropdown(providedBuilder, items, settings:ResolvedSettings, initialIndex = 0) {
				dropdown1 => addDropdown(builder, list100, 0)
			]);
```

`macroBuildWithParameters` macro calls MultiAnimBuilder createWithParameters, allows settings to override control properties and adds objects and UIElements to s2d graphc and UIScreen elements.


## Autotile

Autotile is a root-level manim element for procedural terrain generation. It defines a tileset that can be automatically placed based on neighbor relationships.

### Supported Formats

- **cross**: Cross layout for standard terrain (13 tiles). Tile indices: 0=N, 1=W, 2=C, 3=E, 4=S, 5-8=outer corners, 9-12=inner corners
- **blob47**: Full 47-tile autotile with all edge/corner combinations using 8-direction neighbor detection

### DSL Syntax

```
#myTerrain autotile {
    format: cross             // cross | blob47
    sheet: "terrain"          // atlas name
    prefix: "grass_"          // tile prefix (tiles named grass_0 to grass_12)
    tileSize: 16              // tile size in pixels
}

// Or with image file instead of atlas:
#myTerrain autotile {
    format: cross
    file: "terrain.png"       // image file with tiles in grid layout
    tileSize: 16
    depth: 8                  // optional: isometric depth for elevation
    mapping: [0, 1, 2, ...]   // optional: custom index mapping
}
```

### Usage

```haxe
var builder = MultiAnimBuilder.load(content, resourceLoader, "terrain.manim");

// Binary grid: 1 = terrain present, 0 = empty
var grid = [
    [0, 1, 1, 0],
    [1, 1, 1, 1],
    [0, 1, 1, 0]
];

// Build terrain TileGroup
var terrain = builder.buildAutotile("myTerrain", grid);
scene.addChild(terrain);

// For elevation with depth:
var elevation = builder.buildAutotileElevation("elevation", grid, 0);
```

### Tile Index Calculation

The `bh.base.Autotile` utility class provides:
- `getNeighborMask8(grid, x, y)` - 8-direction neighbor bitmask (N=1, NE=2, E=4, SE=8, S=16, SW=32, W=64, NW=128)
- `getCrossIndex(mask)` - Map neighbor mask to cross format tile index
- `getBlob47Index(mask)` - Map neighbor mask to blob47 tile index
