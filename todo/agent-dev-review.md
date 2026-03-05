# Agent-Friendly Development Review

Review of hx-multianim's AI agent integration points: MCP support, scene graph discoverability, app lifecycle, and multi-instance support.

---

## 1. MCP Support Review

### Current State

Architecture: `Claude Code <--stdio--> MCP Server (Node.js) <--HTTP--> DevBridge (Haxe/HL)`

**Strengths:**
- 24 well-designed tools covering inspection, manipulation, capture, and control
- Pause/step/quit for frame-level debugging
- Trace and error capture with ring buffers
- Hot-reload support for live `.manim` editing
- Clean HTTP/JSON protocol, easy to test with `curl`
- All dev code behind `#if MULTIANIM_DEV` — zero prod overhead

**Issues & Suggestions:**

### 1.1 MCP Server Package Not Found Locally

The `.mcp.json` references `npx -y @bh213/hx-multianim-mcp` but the `hx-multianim-mcp/` directory doesn't exist in this repo. If the MCP server lives in a separate repo/package, consider:
- Adding a `tools/mcp-server/` subdirectory with the Node.js source (monorepo approach)
- Or at minimum, adding a README/link so developers can find and modify it
- The MCP server is the bottleneck for adding new tools — every DevBridge method needs a corresponding TypeScript registration

### 1.2 Connection Lifecycle — No Health Check

There's no `ping`/`health` method. An agent can't distinguish between "app not started yet" and "app crashed". Adding a simple `ping` → `{ok: true, uptime: seconds}` would let agents:
- Wait for app readiness with a tight poll loop instead of arbitrary `sleep 5`
- Detect crashes vs slow startup

### 1.3 Scene Graph Lacks Semantic Information

`walkSceneGraph()` (line 958) only reports `type`, `name`, `x`, `y`, `visible`, `alpha`, `scale`, and for `h2d.Text`/`h2d.Bitmap` some extra fields. Missing:
- **Interactive hit regions**: No indication which objects are interactives or their IDs
- **Programmable identity**: No way to know which scene graph node belongs to which programmable
- **Component type**: Can't distinguish "this is a button" from "this is a bitmap" at the semantic level
- **Parameter state**: No current parameter values in the tree

See Section 2 for improvement proposals.

### 1.4 `list_interactives` Requires Screen Name

An agent must first call `list_screens` → find active screen → call `list_interactives(screen)`. Consider adding a screenless variant that returns interactives across all active screens, or having `list_interactives` default to all active screens when `screen` param is omitted.

### 1.5 `find_element_at` Missing Interactive Info

`findObjectsAt()` checks bounds but doesn't report whether the object is an interactive, what its ID is, or whether it's disabled. An agent doing "what can I click at (100, 200)?" gets raw scene graph types, not actionable information.

### 1.6 Missing Tool: `list_ui_elements`

There's no tool to list UI components (buttons, checkboxes, sliders, etc.) registered on a screen. `list_interactives` shows raw interactive regions but not the higher-level components. An agent trying to interact with a UI needs to know "there's a button called 'confirm' at (200, 300)" not "there's an h2d.Interactive at (200, 300)".

### 1.7 Missing Tool: `wait_for_idle`

Agents frequently need to wait for animations/transitions to complete. Currently they must poll `get_tween_state` + `get_screen_state` manually. A `wait_for_idle(timeout_ms)` tool that blocks until no tweens are active and `isTransitioning` is false would simplify agent workflows.

### 1.8 Consider SSE/WebSocket for Push Events

Currently all inspection is pull-based. An SSE endpoint streaming events (screen changes, animation completion, errors) would eliminate polling and make agents more responsive. Low priority but worth considering for v3.

---

## 2. Scene Graph Metadata & Discoverability

### Current Naming

Objects get names via `object.name = node.uniqueNodeName` where `uniqueNodeName = '${name}_${typeName}_${id}'` (e.g., `myButton_PROGRAMMABLE_3`). This is:
- **Not human-readable**: Names include internal type enum names and auto-incremented IDs
- **Not stable**: IDs change when the `.manim` file is modified
- **Missing semantic info**: No way to discover what a scene graph node *does*

### Approach Options

#### Option A: Custom h2d.Object Subclass with Metadata (Recommended)

Create a lightweight `DevAnnotation` object (similar to the existing `ReloadSentinel` pattern) that attaches metadata to scene graph nodes:

```haxe
#if MULTIANIM_DEV
class DevAnnotation extends h2d.Object {
    public var componentType:String;      // "programmable", "interactive", "slot", "button", etc.
    public var componentId:String;        // user-facing name from .manim
    public var programmableName:String;   // parent programmable
    public var parameters:Map<String, String>; // current param snapshot
    public var interactiveId:String;      // for interactives

    public function new() { super(); visible = false; }
}
```

**Pros**: No runtime cost in prod (behind `#if MULTIANIM_DEV`), follows existing `ReloadSentinel` pattern, no Haxe language limitations to work around.

**Cons**: Adds invisible children to scene graph. Requires walking children to find annotations.

**Integration with `walkSceneGraph`**: Check each node for a `DevAnnotation` child and include its fields in the JSON output.

#### Option B: Enriched `object.name` with Structured Format

Instead of `myButton_PROGRAMMABLE_3`, use a structured name like `manim:button:myButton` or `manim://programmable/myButton`. Then `walkSceneGraph` can parse this format and extract semantic info.

**Pros**: Zero overhead, works with existing Heaps `getObjectByName()`. No extra children.

**Cons**: Fragile string parsing, limited metadata capacity, breaks if other code depends on `object.name`.

#### Option C: Macro-injected Fields (domkit-style)

Haxe macros can add fields to classes at compile time, but `h2d.Object` is a library type — you can't add fields to it via macros from outside. You'd need wrapper classes for every Heaps type, which is impractical.

**Verdict**: Not viable for arbitrary h2d.Object subclasses.

#### Option D: External Registry (Current Approach, Enhanced)

The `ReloadableRegistry` already maps source paths to `BuilderResult` handles. Extend this with a scene graph object → metadata map:

```haxe
// In DevBridge or a companion class
var objectMetadata:Map<Int, ObjectMeta> = new Map(); // keyed by object identity hash
```

**Pros**: No scene graph changes at all.

**Cons**: Requires manual registration, object identity in Haxe is tricky (no stable pointer), GC can invalidate keys.

### Recommendation: Combine A + Enhanced walkSceneGraph

1. During build, when `#if MULTIANIM_DEV`, attach a `DevAnnotation` child to key objects:
   - Every programmable root → `componentType: "programmable"`, `componentId: programmableName`
   - Every interactive → `componentType: "interactive"`, `interactiveId: id`
   - Every slot → `componentType: "slot"`, `componentId: slotName`
   - Every named element (`#name`) → `componentType: "named"`, `componentId: name`

2. Enhance `walkSceneGraph` to detect `DevAnnotation` children and merge their fields into the parent node's JSON.

3. The result: an agent calling `scene_graph` gets a tree where buttons, interactives, and programmables are clearly labeled with their semantic identity.

### Quick Win: Better `object.name`

Even without the full annotation system, improving the naming scheme helps:

```haxe
// Current:  'myButton_PROGRAMMABLE_3'
// Proposed: '#myButton' (for named elements) or 'programmable:myButton' (for programmable roots)
```

This makes `getObjectByName()` calls and `scene_graph` output immediately more useful.

---

## 3. App Start & End Lifecycle

### Current Problem

Agents keep adding `sleep 5` because:
1. No way to know when the app is ready to accept DevBridge connections
2. `Sys.exit()` is a hard termination — no graceful shutdown signal
3. No startup notification mechanism

### Suggestions

#### 3.1 Ready Signal File

On `DevBridge.start()` success, write a marker file:

```haxe
function start():Void {
    // ... existing bind code ...
    // Write ready signal
    var readyFile = Sys.getEnv("HX_DEV_READY_FILE");
    if (readyFile == null) readyFile = ".dev-bridge-ready";
    sys.io.File.saveContent(readyFile, '{"port": $port, "pid": ${Sys.programPath()}}');
    trace('[DevBridge] Ready file written: $readyFile');
}

function stop():Void {
    // ... existing code ...
    // Remove ready file
    try { sys.FileSystem.deleteFile(readyFile); } catch(_) {}
}
```

An agent or MCP server can watch for this file instead of sleeping:
```bash
# In MCP server or agent script
while [ ! -f .dev-bridge-ready ]; do sleep 0.1; done
```

#### 3.2 `ping` Endpoint

Add a trivial handler:

```haxe
case "ping": { alive: true, port: port, uptime: haxe.Timer.stamp() - startTime };
```

The MCP server can retry `ping` with exponential backoff on connection failure, giving the agent a clean "wait for ready" primitive.

#### 3.3 Graceful Shutdown Notification

The `quit` handler already works (delays exit by 100ms for response). But the MCP server should:
- Detect connection loss and report "app exited" to the agent
- Not retry after a `quit` call

#### 3.4 Process Management in MCP Server

The MCP server (Node.js) could own the app process lifecycle:

```typescript
// MCP tool: "start_app"
// - Spawns the HL process with -D MULTIANIM_DEV
// - Waits for ready signal (file or ping)
// - Returns { pid, port }

// MCP tool: "stop_app"
// - Calls quit via DevBridge
// - Falls back to SIGTERM after timeout
// - Cleans up ready file
```

This eliminates the "agent starts app, then needs to find it" problem entirely.

---

## 4. Multiple Instances

### Current Problem

DevBridge binds to a fixed port (default 9001). Second instance fails with "Failed to bind port" and silently loses DevBridge support. The MCP server connects to one port, so it can only talk to one instance.

### Suggestions

#### 4.1 Auto-Port Selection

If the configured port is busy, try the next one:

```haxe
function start():Void {
    var basePort = resolvePort();
    for (offset in 0...10) {
        var tryPort = basePort + offset;
        try {
            serverSocket.bind("0.0.0.0", tryPort, onClientConnected);
            this.actualPort = tryPort;
            trace('[DevBridge] Listening on port $tryPort');
            writeReadyFile(tryPort);
            return;
        } catch (e:Dynamic) {
            if (offset < 9) continue;
            trace('[DevBridge] All ports busy ($basePort-${basePort+9})');
        }
    }
}
```

#### 4.2 Instance Discovery via Ready Files

Use unique ready files per instance:

```
.dev-bridge-9001.json  → {"port": 9001, "pid": 1234, "project": "my-game"}
.dev-bridge-9002.json  → {"port": 9002, "pid": 5678, "project": "my-game"}
```

The MCP server can glob for `.dev-bridge-*.json` and present available instances.

#### 4.3 MCP Server Instance Routing

Add an optional `instance` parameter to MCP tools:

```json
{"method": "screenshot", "params": {"instance": 9002}}
```

Or add instance management tools:
- `list_instances` → discovers running instances from ready files
- `select_instance(port)` → sets default target for subsequent calls

#### 4.4 Lock File with PID

To handle zombie ready files (process crashed without cleanup):

```haxe
// In ready file: include PID
// MCP server: check if PID is alive before connecting

function isProcessAlive(pid:Int):Bool {
    // platform-specific check
}
```

---

## Summary of Priorities

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| **High** | Add `ping` endpoint | Trivial | Eliminates `sleep` hacks |
| **High** | Ready signal file on DevBridge.start() | Small | Clean startup detection |
| **High** | Better `object.name` format | Small | Immediate scene graph readability |
| **Medium** | `DevAnnotation` metadata in scene graph | Medium | Full semantic discoverability |
| **Medium** | Auto-port selection for multi-instance | Small | Enables parallel development |
| **Medium** | Instance discovery via ready files | Small | Multi-instance MCP routing |
| **Medium** | `list_interactives` without screen param | Trivial | Better agent ergonomics |
| **Medium** | Enhanced `find_element_at` with interactive info | Small | Actionable click targets |
| **Low** | `list_ui_elements` tool | Medium | High-level component discovery |
| **Low** | `wait_for_idle` tool | Medium | Eliminates tween polling |
| **Low** | Process management in MCP server | Medium | Full lifecycle control |
| **Low** | SSE push events | Large | Eliminates all polling |
