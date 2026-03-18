import * as path from 'path';
import { ExtensionContext, workspace } from 'vscode';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
} from 'vscode-languageclient/node';

let client: LanguageClient | undefined;

export function activate(context: ExtensionContext) {
    const serverModule = context.asAbsolutePath(path.join('server', 'server.js'));

    const serverOptions: ServerOptions = {
        run: { command: 'node', args: [serverModule] },
        debug: { command: 'node', args: [serverModule] },
    };

    const clientOptions: LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'multianim' }],
        synchronize: {
            fileEvents: workspace.createFileSystemWatcher('**/*.manim'),
        },
    };

    client = new LanguageClient(
        'manimLanguageServer',
        '.manim Language Server',
        serverOptions,
        clientOptions
    );

    client.start();
}

export function deactivate(): Thenable<void> | undefined {
    if (!client) {
        return undefined;
    }
    return client.stop();
}
