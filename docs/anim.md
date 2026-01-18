# .anim Format Reference

State animation is an animation that can be in different states and have different animations running based on those states.

For example, an animation can have an animation named `running` with state `direction(l,r)`. When `l` is set, animation displays running to the left; when `r` is set, animation is running to the right.

## Basic Structure

```anim
sheet: sheetName
states: stateName(value1, value2)
center: x,y
allowedExtraPoints: [point1, point2]

metadata {
    key: value
    @(state=>value) conditionalKey: value
}

animation {
    name: animationName
    fps: 20
    loop: untilCommand | yes | <number>
    playlist {
        sheet: "sprite_$$state$$_name"
        loop <count> { ... }
        event <name> trigger | random x,y,radius | x,y
        command
        goto <animName>
    }
    extrapoints {
        @(state=>value) pointName: x,y
    }
}
```

## Example

```anim
sheet: crew2
allowedExtraPoints: [fire, targeting]
states: direction(l, r)
center: 32,48

metadata {
    spriteWidth: 64
    spriteHeight: 48
    @(direction=>l) fireOffsetX: -5
    @(direction=>r) fireOffsetX: 5
}

animation {
    name: idle
    fps: 4
    playlist {
        loop untilCommand {
            sheet "marine_$$direction$$_idle"
        }
    }
    extrapoints {
        @(direction=>l) targeting: -1, -12
        @(direction=>r) targeting: 5, -12
    }
}
```

---

## Top-Level Declarations

### sheet
Specifies the sprite sheet name. Must be defined before animations. The sheet is loaded via `ResourceLoader.loadSheet2()` which looks for an `.atlas2` file.

```anim
sheet: crew2
```

The `ResourceLoader` will load `crew2.atlas2` which references the actual PNG file(s) containing the sprites. The atlas2 format (compatible with TexturePacker) defines sprite regions within the image:

```
crew2-0.png
size: 256, 1847
format: RGBA8888

marine_l_idle
  xy: 1, 100
  size: 64, 48
  orig: 64, 48
  offset: 0, 0
  index: 0
marine_l_idle
  xy: 65, 100
  size: 64, 48
  orig: 64, 48
  offset: 0, 0
  index: 1
```

When you reference `sheet: "marine_l_idle"` in a playlist, the library looks up all sprites with that name in the atlas and creates animation frames from them, ordered by their `index` value.

### states
Defines state variables and their allowed values. Must be defined before animations.

```anim
states: direction(l, r)
states: direction(l, r), color(red, blue, green)
```

### center
Optional center point for the animation.

```anim
center: 32,48
```

### allowedExtraPoints
Declares valid extra point names that can be used in animations.

```anim
allowedExtraPoints: [fire, targeting, impact]
```

### metadata
Key-value pairs for storing animation metadata such as sprite dimensions, frame indices, etc. Supports conditional values based on state.

```anim
metadata {
    spriteWidth: 64
    spriteHeight: 48
    fireFrame: 3
    @(direction=>l) fireOffsetX: -5
    @(direction=>r) fireOffsetX: 5
    description: "Marine unit"
}
```

**Value types:**
* Integers: `spriteWidth: 64`
* Strings: `description: "Marine unit"` (quoted)

**Conditional metadata:**
Use `@(state=>value)` to define state-specific values:
```anim
@(direction=>l) fireOffsetX: -5
@(direction=>r) fireOffsetX: 5
```

**Accessing metadata in code:**
```haxe
var loadedAnim:LoadedAnimation = AnimParser.parseFile(...);
var stateSelector:AnimationStateSelector = ["direction" => "l"];

// With state selector
var fireX = loadedAnim.metadata.getIntOrDefault("fireOffsetX", 0, stateSelector);

// Without state selector (matches first/unconditional entry)
var width = loadedAnim.metadata.getIntOrDefault("spriteWidth", 32);
var desc = loadedAnim.metadata.getStringOrDefault("description", "Unknown");
```

---

## Animation Block

Each animation block defines a named animation with its properties.

```anim
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { ... }
    extrapoints { ... }
}
```

### Fields

* `name` - Unique animation name (required)
* `fps` - Default frames per second for playlist
* `loop` - Looping behavior for the whole playlist
* `playlist` - List of frames and commands
* `center` - Center point for this specific animation
* `extrapoints` - Points of interest (e.g., particle effects, bullets)

---

## Playlist Commands

### Sheet Frame

```anim
sheet: "myanimation"
sheet: "myanimation" frames: 1..2
sheet: "myanimation" frames: 1..2 duration: 25ms
sheet: "myanimation_$$direction$$_idle"
```

* Uses default `fps` setting when duration not specified
* Takes all frames with the name from the atlas sheet
* `$$stateName$$` - State variable interpolation in sheet names

### File Frame

```anim
file: "filename.png"
file: "filename.png" duration: 100ms
```

Loads and plays a single frame PNG image.

### Loop

```anim
loop { ... }
loop 3 { ... }
loop untilCommand { ... }
```

* `loop` or `loop: yes` - loops forever
* `loop: <number>` - loops specified number of times
* `loop: untilCommand` - loops until command queue has entry

### Events

```anim
event <name> trigger
event <name> x,y
event <name> random x,y,radius
```

* `trigger` - fires event with specific name
* `x,y` - fires point event at coordinates
* `random x,y,radius` - fires event at random point within radius of (x,y)

### Command

```anim
command
```

Executes next command from the command queue if not empty.

### Goto

```anim
goto <animationName>
```

Switches to another animation. Can be used for transitions.

---

## Extra Points

Extra points are named coordinates where other animations or code interacts with sprites. They can represent impact points, bullet sources, particle effect origins, etc.

```anim
extrapoints {
    fire: 5, -19
    @(direction=>l) targeting: -1, -12
    @(direction=>r) targeting: 5, -12
}
```

---

## Conditionals Based on State

Conditionals filter which animation or extrapoint applies based on state values.

### Animation-level conditionals

```anim
animation @(direction=>l) @(color=>red) {
    name: attack
    ...
}
```

Only applied when `direction=>l` AND `color=>red`.

### Extrapoint conditionals

```anim
extrapoints {
    @(direction=>l) fire: -2, -2
    @(direction=>r) fire: 2, -2
}
```

Only provides the extrapoint when the state matches.

---

## Commands - Programming Interface

Commands control animation behavior from code.

### Command Triggers

* `NEXT_COMMAND_ON_ANIM_END` - on end of animation, end of loop, or `command` playlist command
* `NEXT_COMMAND_WAIT_TIMER` - execute after specified time (ignores animation end)
* `NEXT_COMMAND_NOW` - execute immediately

### Available Commands

* `Delay(seconds)` - wait for specific time before next command
* `SwitchState(stateName)` - switch to another animation name
* `CommandEvent` - trigger an event
* `Callback` - execute a callback function
* `Visible` - set sprite visibility

---

## State Variable Interpolation

Use `$$stateName$$` in sheet names to dynamically insert state values:

```anim
states: direction(l, r)

animation {
    name: walk
    playlist {
        sheet: "marine_$$direction$$_walk"
    }
}
```

When `direction` is `l`, this becomes `marine_l_walk`.
When `direction` is `r`, this becomes `marine_r_walk`.

---

## Complete Example

```anim
sheet: crew2
allowedExtraPoints: [fire, targeting]
states: direction(l, r)
center: 32,48

metadata {
    spriteWidth: 64
    spriteHeight: 48
    @(direction=>l) fireOffsetX: -5
    @(direction=>r) fireOffsetX: 5
}

animation {
    name: idle
    fps: 4
    playlist {
        loop untilCommand {
            sheet: "marine_$$direction$$_idle"
        }
    }
    extrapoints {
        @(direction=>l) targeting: -1, -12
        @(direction=>r) targeting: 5, -12
    }
}

animation {
    name: fire-up
    fps: 20
    loop: 2
    playlist {
        sheet: "marine_$$direction$$_shooting_u"
        event fire trigger
    }
    extrapoints {
        fire: 5, -19
    }
}

animation {
    name: walk
    fps: 8
    loop: yes
    playlist {
        sheet: "marine_$$direction$$_walk"
    }
}

animation @(direction=>l) {
    name: special-attack
    fps: 12
    playlist {
        sheet: "marine_l_special"
        goto idle
    }
}

animation @(direction=>r) {
    name: special-attack
    fps: 12
    playlist {
        sheet: "marine_r_special"
        goto idle
    }
}
```

---

## Haxe Usage Examples

### Loading and Creating AnimationSM

```haxe
import bh.stateanim.AnimParser;
import bh.stateanim.AnimParser.AnimationStateSelector;
import bh.stateanim.AnimationSM;

// Load and parse the .anim file
var parsed = resourceLoader.loadAnimParser("marine.anim");

// Create initial state selector
var stateSelector:AnimationStateSelector = [];
for (key => values in parsed.definedStates) {
    stateSelector.set(key, values[0]); // Set first value as default
}

// Create the animation state machine
var animSM:AnimationSM = parsed.createAnimSM(stateSelector);

// Add to scene
scene.addChild(animSM);
animSM.setScale(3.0);
```

### Controlling Animations with Commands

```haxe
// Switch to a specific animation immediately
animSM.addCommand(SwitchState("idle"), ExecuteNow);

// Queue multiple commands
animSM.addCommand(SwitchState("walk"), Queued);
animSM.addCommand(Delay(2.0), Queued);
animSM.addCommand(SwitchState("fire-up"), Queued);
```

### Handling Animation Events

```haxe
animSM.onAnimationEvent = (event) -> {
    switch event {
        case TRIGGER(name):
            trace('Event triggered: $name');
        case POINT_EVENT(name, point):
            var globalPoint = animSM.localToGlobal(point.toPoint());
            // Spawn effect at globalPoint
    }
};
```

### Accessing Metadata

```haxe
var loadedAnim = parsed.getLoadedAnimation();

// Access metadata with state selector
var fireOffsetX = loadedAnim.metadata.getIntOrDefault("fireOffsetX", 0, stateSelector);

// Access metadata without state (for non-conditional values)
var spriteWidth = loadedAnim.metadata.getIntOrDefault("spriteWidth", 32);
var description = loadedAnim.metadata.getStringOrDefault("description", "Unknown");
```

### Changing States at Runtime

```haxe
// Update state selector
stateSelector.set("direction", "r");

// Recreate animation with new state
animSM = parsed.createAnimSM(stateSelector);
```
