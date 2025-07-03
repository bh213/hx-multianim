# hx-multianim Playground

A comprehensive demonstration of the [hx-multianim](https://github.com/bh213/hx-multianim) library, showcasing its powerful multi-animation system for Haxe/Heaps applications.

## Overview

This demo showcases the capabilities of the hx-multianim library, which provides a sophisticated animation system for creating rich, interactive UI components and game elements. The demo includes multiple screens demonstrating various features:

- **Master Screen**: Overview and navigation hub
- **Components Test**: Interactive UI components (buttons, checkboxes, sliders, dropdowns)
- **State Animations**: Complex state-based animations
- **Particles**: Particle system demonstrations
- **Paths**: Path-based animations and motion
- **Fonts**: Various font rendering examples
- **Room 1**: 3D room environment with animations
- **Examples 1**: Basic animation examples
- **Settings**: Configuration and customization options
- **Dialog Start**: Dialog system demonstrations

## Features Demonstrated

### UI Components
- Multi-state buttons with hover/press animations
- Checkboxes with custom animations
- Sliders with visual feedback
- Dropdown menus with smooth transitions
- Scrollable lists with custom styling

### Animation Systems
- State-based animations
- Particle effects
- Path-following animations
- Font rendering with SDF support
- Multi-layer sprite animations

### Technical Features
- Cross-platform support (JavaScript and HashLink)
- Live resource reloading
- Custom font management
- Atlas-based sprite management
- Tween-based animations

## Prerequisites

- [Haxe](https://haxe.org/) (4.0 or later)
- [Heaps](https://heaps.io/) library
- [HashLink](https://hashlink.haxe.org/) (for native builds)
- [lix](https://github.com/lix-pm/lix.client) (for dependency management)
- [Node.js](https://nodejs.org/) (16.0 or later, for development tools)

## Installation

1. Navigate to the playground directory in the hx-multianim repository:
```bash
cd playground
```

2. Install dependencies using lix:
```bash
lix install
```

3. Install Node.js development dependencies:
```bash
npm install
```

## Building and Running

### Quick Start (Development Mode)
For the best development experience with live reloading:

```bash
npm run dev
```

This will:
- Start a local server at `http://localhost:8080`
- Watch for changes in source files and automatically rebuild
- Reload the browser when changes are detected

### Manual Building

#### JavaScript Target
```bash
# Standard build
npm run build

# Or the old way
js.bat
```

Or manually:
```bash
haxe playground.hxml
```

#### HashLink Target (Native)
```bash
haxe demo-hl.hxml
hl build/demo.hl
```

### GitHub Pages Deployment

To build specifically for GitHub Pages:
```bash
npm run build:gh-pages
```

The project includes automatic GitHub Actions deployment. When you push to the main branch, it will automatically build and deploy to GitHub Pages.

## Development Scripts

| Command | Description |
|---------|-------------|
| `npm run build` | Build the project for development |
| `npm run build:gh-pages` | Build the project for GitHub Pages deployment |
| `npm run watch` | Watch for changes and rebuild automatically |
| `npm run watch:gh-pages` | Watch for changes and rebuild for GitHub Pages |
| `npm run serve` | Start a local development server |
| `npm run dev` | Start development mode (watch + serve) |
| `npm run dev:gh-pages` | Start development mode for GitHub Pages |
| `npm run clean` | Clean build directory |

## Interactive Playground

The playground now includes an interactive editor with:

- **Left Panel**: Dropdown to select manim examples and text editor for modifying content
- **Right Panel**: Live preview canvas showing the changes
- **Real-time Updates**: Changes in the text editor can be applied to see immediate results

### Using the Playground

1. Select an example from the dropdown
2. The manim file content will load in the text area
3. Edit the content to experiment with different animations
4. Use the 'R' key to reload resources and see changes

## Controls

- **R**: Reload resources (live update)
- **Q**: Quit (HashLink only)
- **Mouse**: Navigate through UI components
- **Arrow Keys**: Navigate between screens (in some contexts)

## Dependencies

- **hx-multianim**: Core animation library
- **heaps**: Graphics and game framework
- **hxparse**: Parsing utilities
- **tweenxcore**: Animation tweening

## Fonts

The demo includes various fonts for testing the font rendering system. See [ATTRIBUTION.md](ATTRIBUTION.md) for font sources and licensing information.

## Contributing

This playground is part of the hx-multianim library repository. For contributions to the core library, please visit the [hx-multianim repository](https://github.com/bh213/hx-multianim).

## Related Projects

- **[hx-multianim](https://github.com/bh213/hx-multianim)**: The main library this demo showcases
- **[Heaps](https://heaps.io/)**: The graphics framework used
- **[Haxe](https://haxe.org/)**: The programming language

