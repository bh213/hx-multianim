export interface Screen {
    name: string;
    displayName: string;
    description: string;
    manimFile: string;
}

export interface ManimFile {
    filename: string;
    displayName: string;
    description: string;
    content: string | null;
}

export interface AnimFile {
    filename: string;
    content: string | null;
}

export interface PlaygroundLoader {
    screens: Screen[];
    manimFiles: ManimFile[];
    animFiles: AnimFile[];
    currentFile: string | null;
    currentExample: string | null;
    reloadTimeout: number | null;
    reloadDelay: number;
    mainApp: any;
    baseUrl: string;
}

export interface FileLoader {
    baseUrl: string;
    resolveUrl: (url: string) => string;
    load: (url: string) => ArrayBuffer;
    stringToArrayBuffer: (str: string) => ArrayBuffer;
}

declare global {
    interface Window {
        FileLoader: FileLoader;
        playgroundLoader: PlaygroundLoader;
        PlaygroundMain: {
            instance: any;
            defaultScreen: string;
        };
        hxd?: {
            res?: {
                load?: (url: string) => {
                    entry?: {
                        getBytes?: () => any;
                    };
                };
            };
        };
    }
} 