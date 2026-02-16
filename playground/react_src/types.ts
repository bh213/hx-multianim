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
    isLibrary?: boolean;
}

export interface AnimFile {
    filename: string;
    content: string | null;
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
        playgroundLoader: any;
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
