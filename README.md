# hx-multianim

A Haxe library for creating animations and pixel art UI elements using the [Heaps](https://heaps.io/) framework. This library provides custom languages for defining state animations and programmable UI components.

## Documentation

- **[.manim Format Reference](docs/manim.md)** - UI elements, programmables, layouts, graphics, particles, and data blocks
- **[Programmable Macros](docs/manim.md#programmable-macros-compile-time-code-generation)** - Compile-time code generation tutorial and reference
- **[Data Blocks](docs/manim.md#data)** - Static typed data definitions with macro codegen
- **[.anim Format Reference](docs/anim.md)** - State animations with playlists and extra points

## Interactive Playground

Playground is available at [gh-pages](https://bh213.github.io/hx-multianim/).

The playground provides:
- **Live Examples**: Interactive demonstrations of UI components, animations, and effects
- **Code Editor**: Real-time editing of `.manim` files with instant preview
- **Multiple Screens**: Various examples showcasing different features

### Running the Playground

```bash
cd playground
lix download
npm install
npm run dev
```

This will start the playground at `http://localhost:3000` with live reloading enabled.

For more details, see the [playground README](playground/README.md).

## Getting Started

### Prerequisites

#### Install Haxe
Download and install Haxe from [haxe.org](https://haxe.org/download/).

#### Install Lix (Recommended)
[Lix](https://www.npmjs.com/package/lix) is the modern package manager for Haxe projects:
```bash
npm install -g lix
```

### Quick Start

1. **Add to your project**:
   ```hxml
   -lib hx-multianim
   -lib heaps
   -lib hxparse
   ```

2. **Create a UI element** (`.manim`):
   ```
   version: 0.3

   #textDemo programmable() {
     text(dd, "Hello World", red, left, 200): 0, 0
     text(m3x6, "Centered text", blue, center, 200): 0, 20
   }
   ```

3. **Load and build in Haxe**:
   ```haxe
   import bh.multianim.MultiAnimBuilder;

   // Load the .manim file
   var fileContent = byte.ByteData.ofString(sys.io.File.getContent("ui.manim"));
   var builder = MultiAnimBuilder.load(fileContent, resourceLoader, "ui.manim");

   // Build a programmable element
   var result = builder.buildWithParameters("textDemo", new Map());
   scene.addChild(result.object);
   ```

4. **Create a state animation** (`.anim`):
   ```
   sheet: characters
   states: direction(l, r)

   animation {
       name: idle
       fps: 4
       playlist {
           sheet: "player_$$direction$$_idle"
       }
   }
   ```

5. **Load and use AnimationSM**:
   ```haxe
   import bh.stateanim.AnimParser;
   import bh.stateanim.AnimationSM;

   // Load and parse
   var parsed = resourceLoader.loadAnimParser("character.anim");

   // Create state selector
   var stateSelector:AnimationStateSelector = ["direction" => "l"];

   // Create animation state machine
   var animSM = parsed.createAnimSM(stateSelector);
   scene.addChild(animSM);

   // Control animations
   animSM.addCommand(SwitchState("idle"), ExecuteNow);
   ```

## UIScreen System

The library provides a screen management system for building complete UI applications.

### ScreenManager

`ScreenManager` handles screen lifecycle, resource loading, and hot-reloading:

```haxe
import bh.ui.screens.ScreenManager;

class Main extends hxd.App {
    var screenManager:ScreenManager;

    override function init() {
        screenManager = new ScreenManager(this);
        screenManager.showScreen(new MainMenuScreen(screenManager));
    }

    override function update(dt:Float) {
        screenManager.update(dt);
    }
}
```

### UIScreen

Extend `UIScreenBase` to create screens with UI elements:

```haxe
import bh.ui.screens.UIScreen;
import bh.ui.screens.ScreenManager;

class MainMenuScreen extends UIScreenBase {
    var builder:MultiAnimBuilder;

    public function new(screenManager:ScreenManager) {
        super(screenManager);
    }

    public override function load() {
        // Load .manim file with hot-reload support
        builder = screenManager.buildFromResourceName("ui/mainmenu.manim", true);

        // Build and add UI elements
        var panel = builder.buildWithParameters("mainPanel", []);
        addBuilderResult(panel);

        // Add interactive elements
        var button = addButton(builder.createElementBuilder("button"), "Start Game", null);
        addElementWithPos(button, 100, 200);
        button.onClick = () -> onStartGame();
    }

    public override function onScreenEvent(event:UIScreenEvent, source:UIElement) {
        // Handle UI events
    }
}
```

### Layers

Screens support multiple z-order layers for proper element stacking:

```haxe
// Built-in layers (lowest to highest)
BackgroundLayer  // Layer index 1
DefaultLayer     // Layer index 3
ModalLayer       // Layer index 5

// Add elements to specific layers
addElement(button, ModalLayer);
addObjectToLayer(sprite, BackgroundLayer);
```

### UI Elements

`UIScreenBase` provides helper methods for common UI components:

```haxe
// Buttons
var button = addButton(builder.createElementBuilder("button"), "Click Me", settings);
button.onClick = () -> doSomething();

// Checkboxes
var checkbox = addCheckbox(builder, settings, true);
checkbox.onChanged = (checked) -> handleChange(checked);

// Sliders
var slider = addSlider(builder, settings, 50);
slider.onValueChanged = (value) -> handleSlider(value);

// Dropdowns
var dropdown = addDropdown(dropdownBuilder, panelBuilder, itemBuilder,
    scrollbarBuilder, "scrollbar", items, settings);
dropdown.onSelectionChanged = (index) -> handleSelection(index);

// Scrollable lists
var list = addScrollableList(panelBuilder, itemBuilder, scrollbarBuilder,
    "scrollbar", items, settings, 0, 200, 300);
```

### Element Groups

Organize and manage related elements:

```haxe
// Create a group
createGroup("menuButtons");

// Add elements to group
addElementToGroup("menuButtons", button1);
addElementToGroup("menuButtons", button2);

// Remove all elements in group
removeGroupElements("menuButtons");
```

### Dialogs

Show modal dialogs over the current screen:

```haxe
// Show dialog
screenManager.showDialog(new ConfirmDialog(screenManager), this, "confirm");

// Handle dialog result in onScreenEvent
public override function onScreenEvent(event:UIScreenEvent, source:UIElement) {
    switch event {
        case UIOnControllerEvent(OnDialogResult(dialogName, result)):
            if (dialogName == "confirm") {
                // Handle dialog result
            }
        default:
    }
}
```

## License

See LICENSE file for details.
