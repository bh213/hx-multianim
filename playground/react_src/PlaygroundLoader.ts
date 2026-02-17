import { Screen, ManimFile, AnimFile } from './types';
import { getFileContent, updateFileContent, fileExists } from './fileLoader';
import { DEFAULT_SCREEN } from './App';

/** Single source of truth for screen definitions */
interface ScreenData {
    name: string;
    displayName: string;
    description: string;
    manimFile: string;
    haxeFile: string;
}

const SCREEN_DATA: ScreenData[] = [
    { name: 'scrollableList', displayName: 'Scrollable List Test', description: 'Scrollable list component test screen with interactive list selection and scrolling functionality.', manimFile: 'scrollable-list.manim', haxeFile: 'ScrollableListTestScreen.hx' },
    { name: 'button', displayName: 'Button Test', description: 'Button component test screen with interactive button controls and click feedback.', manimFile: 'button.manim', haxeFile: 'ButtonTestScreen.hx' },
    { name: 'checkbox', displayName: 'Checkbox Test', description: 'Checkbox component test screen with interactive checkbox controls and state display.', manimFile: 'checkbox.manim', haxeFile: 'CheckboxTestScreen.hx' },
    { name: 'slider', displayName: 'Slider Test', description: 'Slider component test screen with interactive slider controls and screen selection functionality.', manimFile: 'slider.manim', haxeFile: 'SliderTestScreen.hx' },
    { name: 'particlesAdvanced', displayName: 'Particles', description: 'Particle system examples demonstrating color gradients, force fields, bounds modes, trails, and various emission patterns.', manimFile: 'particles-advanced.manim', haxeFile: 'ParticlesAdvancedScreen.hx' },
    { name: 'pixels', displayName: 'Pixels', description: 'Pixel art and static pixel demo screen.', manimFile: 'pixels.manim', haxeFile: 'PixelsScreen.hx' },
    { name: 'components', displayName: 'Components', description: 'Interactive UI components showcase featuring buttons, checkboxes, sliders, and other form elements with hover and press animations.', manimFile: 'components.manim', haxeFile: 'ComponentsTestScreen.hx' },
    { name: 'examples1', displayName: 'Examples 1', description: 'Basic animation examples demonstrating fundamental hx-multianim features including sprite animations, transitions, and simple UI elements.', manimFile: 'examples1.manim', haxeFile: 'Examples1Screen.hx' },
    { name: 'paths', displayName: 'Paths', description: 'Path-based animations showing objects following complex paths, motion trails, and smooth movement animations.', manimFile: 'paths.manim', haxeFile: 'PathsScreen.hx' },
    { name: 'fonts', displayName: 'Fonts', description: 'Font rendering demonstrations with various font types, sizes, and text effects including SDF (Signed Distance Field) fonts.', manimFile: 'fonts.manim', haxeFile: 'FontsScreen.hx' },
    { name: 'room1', displayName: 'Room 1', description: '3D room environment with spatial animations, depth effects, and immersive 3D scene demonstrations.', manimFile: 'room1.manim', haxeFile: 'Room1Screen.hx' },
    { name: 'stateAnim', displayName: 'State Animation', description: 'Complex state-based animations demonstrating transitions between different UI states and conditional animations.', manimFile: 'stateanim.manim', haxeFile: 'StateAnimScreen.hx' },
    { name: 'dialogStart', displayName: 'Dialog Start', description: 'Dialog startup animations and initial dialog states with smooth entrance effects and loading sequences.', manimFile: 'dialog-start.manim', haxeFile: 'DialogStartScreen.hx' },
    { name: 'settings', displayName: 'Settings', description: 'Settings interface with configuration options, preference panels, and settings-specific UI animations.', manimFile: 'settings.manim', haxeFile: 'SettingsScreen.hx' },
    { name: 'atlasTest', displayName: 'Atlas Test', description: 'Atlas texture testing screen demonstrating sprite sheet loading, grid layouts, and atlas-based animations.', manimFile: 'atlas-test.manim', haxeFile: 'AtlasTestScreen.hx' },
    { name: 'draggable', displayName: 'Draggable Test', description: 'Drag and drop functionality demonstration with free dragging, bounds-constrained dragging, and zone-restricted dropping.', manimFile: 'draggable.manim', haxeFile: 'DraggableTestScreen.hx' },
    { name: 'animViewer', displayName: 'Animation Viewer', description: 'Animation viewer for .anim files. Displays all animations from the selected .anim file in a grid layout.', manimFile: 'animviewer.manim', haxeFile: 'AnimViewerScreen.hx' },
];

/** Extra manim files that don't have a corresponding screen */
const EXTRA_MANIM_FILES = [
    { filename: 'dialog-base.manim', displayName: 'Dialog Base', description: 'Dialog system foundation with base dialog layouts, text rendering, and dialog-specific animations and transitions.' },
    { filename: 'std.manim', displayName: 'Standard Library', description: 'Standard library components and utilities for hx-multianim including common animations, effects, and helper functions.' },
];

const ANIM_FILES = ['arrows.anim', 'dice.anim', 'marine.anim', 'shield.anim', 'turret.anim'];

/**
 * PlaygroundLoader - Combined file and manim loader for the hx-multianim playground
 * Handles loading manim files, editing them, and reloading the playground application
 */
export class PlaygroundLoader {
    public screens: Screen[];
    public manimFiles: ManimFile[];
    public animFiles: AnimFile[];

    public currentFile: string | null = null;
    public currentExample: string | null = null;
    public currentScreen: string | null = null;
    public reloadTimeout: number | null = null;
    public reloadDelay: number = 1000;
    public mainApp: any = null;
    public baseUrl: string = '';

    constructor() {
        // Derive screens and manimFiles from single source of truth
        this.screens = SCREEN_DATA.map(s => ({
            name: s.name,
            displayName: s.displayName,
            description: s.description,
            manimFile: s.manimFile
        }));

        this.manimFiles = [
            ...SCREEN_DATA.map(s => ({
                filename: s.manimFile,
                displayName: s.displayName,
                description: s.description,
                content: null as string | null
            })),
            ...EXTRA_MANIM_FILES.map(f => ({
                filename: f.filename,
                displayName: f.displayName,
                description: f.description,
                content: null as string | null,
                isLibrary: true
            }))
        ];

        this.animFiles = ANIM_FILES.map(f => ({ filename: f, content: null }));

        this.init();
    }

    getScreenHaxeFile(screenName: string): string {
        const data = SCREEN_DATA.find(s => s.name === screenName);
        if (data) return data.haxeFile;
        return `${screenName.charAt(0).toUpperCase() + screenName.slice(1)}Screen.hx`;
    }

    init(): void {
        this.setupFileLoader();
        this.loadFilesFromMap();
        this.waitForMainApp();
    }

    loadFilesFromMap(): void {
        this.manimFiles.forEach(file => {
            const content = getFileContent(file.filename);
            if (content) {
                file.content = content;
            }
        });

        this.animFiles.forEach(file => {
            const content = getFileContent(file.filename);
            if (content) {
                file.content = content;
            }
        });
    }

    waitForMainApp(): void {
        if (typeof window.PlaygroundMain !== 'undefined' && window.PlaygroundMain.instance) {
            this.mainApp = window.PlaygroundMain.instance;
        } else {
            setTimeout(() => this.waitForMainApp(), 100);
        }
    }

    setupFileLoader(): void {
        this.baseUrl = (() => {
            if (typeof window !== 'undefined' && window.location) {
                return window.location.href;
            }
            return '';
        })();

        window.FileLoader = {
            baseUrl: this.baseUrl,
            resolveUrl: (url: string) => this.resolveUrl(url),
            load: (url: string) => this.loadFile(url),
            stringToArrayBuffer: this.stringToArrayBuffer
        };
    }

    resolveUrl(url: string): string {
        if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('//') || url.startsWith('file://')) {
            return url;
        }

        if (!this.baseUrl) {
            return url;
        }

        try {
            return new URL(url, this.baseUrl).href;
        } catch (e) {
            const base = this.baseUrl.endsWith('/') ? this.baseUrl : this.baseUrl + '/';
            const path = url.startsWith('/') ? url.substring(1) : url;
            return base + path;
        }
    }

    stringToArrayBuffer(str: string): ArrayBuffer {
        return new TextEncoder().encode(str).buffer;
    }

    loadFile(url: string): ArrayBuffer {
        const filename = this.extractFilenameFromUrl(url);

        if (filename && fileExists(filename)) {
            const content = getFileContent(filename);
            if (content) {
                return this.stringToArrayBuffer(content);
            }
        }

        // Try Haxe loader as fallback
        if (typeof window.hxd !== 'undefined' && window.hxd.res && window.hxd.res.load) {
            try {
                const resource = window.hxd.res.load(url);
                if (resource && resource.entry && resource.entry.getBytes) {
                    const bytes = resource.entry.getBytes();
                    return this.stringToArrayBuffer(bytes.toString());
                }
            } catch (e) {
                // Haxe loader failed, continue to HTTP fallback
            }
        }

        // Fall back to synchronous HTTP loading (required by Haxe FileLoader contract)
        const resolvedUrl = this.resolveUrl(url);
        const xhr = new XMLHttpRequest();
        xhr.open('GET', resolvedUrl, false);
        xhr.send();
        if (xhr.status === 200) {
            return this.stringToArrayBuffer(xhr.response);
        } else {
            return new ArrayBuffer(0);
        }
    }

    private extractFilenameFromUrl(url: string): string | null {
        const cleanUrl = url.split('?')[0].split('#')[0];
        const pathParts = cleanUrl.split('/');
        const filename = pathParts[pathParts.length - 1];

        if (filename && (filename.endsWith('.manim') || filename.endsWith('.anim') ||
                        filename.endsWith('.png') || filename.endsWith('.atlas2') ||
                        filename.endsWith('.fnt') || filename.endsWith('.tps'))) {
            return filename;
        }

        return null;
    }

    onContentChanged(content: string): void {
        if (this.currentFile) {
            const manimFile = this.manimFiles.find(file => file.filename === this.currentFile);
            if (manimFile) {
                manimFile.content = content;
                updateFileContent(this.currentFile, content);
            }

            const animFile = this.animFiles.find(file => file.filename === this.currentFile);
            if (animFile) {
                animFile.content = content;
                updateFileContent(this.currentFile, content);
            }
        }

        if (this.reloadTimeout) {
            clearTimeout(this.reloadTimeout);
        }

        this.reloadTimeout = setTimeout(() => {
            this.reloadPlayground();
        }, this.reloadDelay);
    }

    reloadPlayground(screenName?: string): any {
        const selectedScreen = screenName || this.currentScreen || 'particles';
        this.currentScreen = selectedScreen;

        if (window.PlaygroundMain?.instance) {
            try {
                return window.PlaygroundMain.instance.reload(selectedScreen, true);
            } catch (error) {
                return { __nativeException: error };
            }
        }
        return null;
    }

    getCurrentFile(): string | null {
        return this.currentFile;
    }

    getEditedContent(filename: string): string | null {
        const manimFile = this.manimFiles.find(file => file.filename === filename);
        if (manimFile) return manimFile.content;

        const animFile = this.animFiles.find(file => file.filename === filename);
        if (animFile) return animFile.content;

        return null;
    }

    updateContent(filename: string, content: string): void {
        const manimFile = this.manimFiles.find(file => file.filename === filename);
        if (manimFile) {
            manimFile.content = content;
            updateFileContent(filename, content);
        }
    }

    dispose(): void {
        if (this.mainApp && typeof this.mainApp.dispose === 'function') {
            this.mainApp.dispose();
        }
    }

    public static getDefaultScreen(): string {
        return DEFAULT_SCREEN;
    }
}
