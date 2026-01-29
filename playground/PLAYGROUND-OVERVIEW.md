# hx-multianim Playground Overview

## Purpose

The playground is a **web-based interactive IDE** for the hx-multianim animation library. It allows users to:
- Edit `.manim` and `.anim` files with syntax highlighting
- See real-time preview of animations rendered via WebGL
- Explore various UI components and animation examples
- Learn the hx-multianim DSL through interactive experimentation

**Live Demo:** https://bh213.github.io/hx-multianim/

## Architecture

The playground uses a **hybrid Haxe/React architecture**:

```
┌─────────────────────────────────────────────────────────────────┐
│                      React Frontend (TypeScript)                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ File Browser│  │ Code Editor │  │ Playground/Console Panel│  │
│  │   (Left)    │  │  (Monaco)   │  │    (Right - WebGL)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ PlaygroundLoader │  (Bridge Layer)
                    │   + FileLoader   │
                    └────────┬────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    Haxe Backend (Heaps/WebGL)                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Main.hx   │  │ScreenManager│  │  16 Demo Screens        │  │
│  │ (Entry)     │  │  + Reload   │  │  (Button, Slider, etc.) │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
playground/
├── react_src/                 # React/TypeScript frontend
│   ├── App.tsx               # Main UI component (1075 lines)
│   ├── CodeEditor.tsx        # Monaco editor wrapper
│   ├── PlaygroundLoader.ts   # Bridge to Haxe backend
│   ├── fileLoader.ts         # In-memory file system (Vite glob)
│   ├── haxe-loader.ts        # Script loader with retry logic
│   ├── types.ts              # TypeScript interfaces
│   ├── index.css             # Tailwind CSS styles
│   ├── main.tsx              # React entry point
│   ├── manim.tmLanguage.json # Syntax highlighting for .manim
│   └── anim.tmLanguage.json  # Syntax highlighting for .anim
├── src/                       # Haxe source code
│   ├── Main.hx               # Haxe entry point (@:expose)
│   └── screens/              # 16 demonstration screens
├── public/                    # Static assets
│   └── assets/               # .manim and .anim test files
├── res/                       # Heaps resources (fonts, atlases)
├── haxe_libraries/           # Lix-managed Haxe dependencies
├── playground.hxml           # Haxe build configuration
├── vite.config.ts            # Vite bundler configuration
├── package.json              # npm scripts and dependencies
├── tsconfig.json             # TypeScript configuration
└── nodemon.json              # File watcher configuration
```

## Key Components

### React Frontend

| File | Purpose |
|------|---------|
| `App.tsx` | Main UI: 3-panel layout, screen/file selection, error display |
| `CodeEditor.tsx` | Monaco editor with custom `.manim`/`.anim` syntax highlighting |
| `PlaygroundLoader.ts` | Screen/file definitions, bridge to Haxe reload function |
| `fileLoader.ts` | In-memory file storage using Vite's `import.meta.glob` |
| `haxe-loader.ts` | Loads `playground.js` with retry logic and error UI |

### Haxe Backend

| File | Purpose |
|------|---------|
| `Main.hx` | Entry point, font registration, screen setup, reload handler |
| `screens/*.hx` | Individual demo screens for different features |

### Bridge Layer

The `PlaygroundLoader` class bridges React and Haxe:
1. **File Management**: Stores edited content in memory via `fileMap`
2. **Screen Definitions**: Maps screen names to `.manim` files
3. **Reload Trigger**: Calls `window.PlaygroundMain.instance.reload(screenName)`
4. **FileLoader Setup**: Provides `window.FileLoader` for Haxe to fetch edited content

## Data Flow: Editing and Preview

```
User edits code in Monaco
        │
        ▼
App.handleEditorChange() → setManimContent(content)
        │
        ▼
User clicks "Apply Changes" (or Ctrl+S)
        │
        ▼
handleApplyChanges()
   ├─→ updateFileContent(filename, content)  // Update in-memory fileMap
   └─→ loader.reloadPlayground(screenName)
              │
              ▼
        window.PlaygroundMain.instance.reload(screenName)
              │
              ▼
        Haxe Main.reload()
              │
              ▼
        screenManager.reload() → Re-parses .manim file
              │
              ▼
        FileLoader.load(filename) → Returns content from fileMap
              │
              ▼
        MultiAnimBuilder.load() → Parses .manim DSL
              │
              ▼
        Screen renders updated animation on WebGL canvas
```

## Available Screens (16 total)

| Screen Name | Display Name | Description |
|-------------|--------------|-------------|
| scrollableList | Scrollable List Test | List component with selection and scrolling |
| button | Button Test | Interactive button controls |
| checkbox | Checkbox Test | Checkbox state management |
| slider | Slider Test | Slider controls |
| particles | Particles | Particle effects and animations |
| pixels | Pixels | Pixel art demonstrations |
| components | Components | UI components showcase |
| examples1 | Examples 1 | Basic animation examples |
| paths | Paths | Path-based animations |
| fonts | Fonts | Font rendering with SDF support |
| room1 | Room 1 | 3D room environment |
| stateAnim | State Animation | State-based animation transitions |
| dialogStart | Dialog Start | Dialog system animations |
| settings | Settings | Configuration interface |
| atlasTest | Atlas Test | Sprite sheet loading |
| draggable | Draggable Test | Drag and drop functionality |

## Build Commands

```bash
# Install dependencies
npm install
lix download

# Development mode (Haxe + React hot reload)
npm run dev

# Production build
npm run full:build

# Individual builds
npm run build        # Haxe only → public/playground.js
npm run react:build  # React only → dist/
```

## Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Language (Frontend) | TypeScript | ^5.2.2 |
| Language (Backend) | Haxe | 4.3.2/4.3.6 |
| UI Framework | React | ^18.2.0 |
| Code Editor | Monaco Editor | ^0.52.2 |
| CSS Framework | Tailwind CSS | ^4.1.10 |
| Build Tool | Vite | ^5.0.8 |
| Game Engine | Heaps | (via Lix) |
| Parser | hxparse (fork) | github.com/bh213/hxparse |

## GitHub Pages Deployment

The playground is automatically deployed to GitHub Pages on push to `main`:
1. GitHub Actions runs `npm run full:build`
2. Output in `dist/` is pushed to `gh-pages` branch
3. GitHub Pages serves from `gh-pages` branch

See `.github/workflows/deploy-playground-to-gh-pages.yml`
