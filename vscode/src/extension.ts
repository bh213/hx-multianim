import * as path from 'path';
import { workspace, window, ExtensionContext } from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from 'vscode-languageclient/node';

declare const __BUILD_TIME__: string;

let client: LanguageClient;
const outputChannel = window.createOutputChannel('MultiAnim');

export function activate(context: ExtensionContext) {
  const ext = context.extension;
  const version = ext.packageJSON?.version ?? 'unknown';
  const buildTime = typeof __BUILD_TIME__ !== 'undefined' ? __BUILD_TIME__ : 'dev';

  outputChannel.appendLine(`MultiAnim Language Support v${version} (built: ${buildTime})`);

  const serverModule = context.asAbsolutePath(
    path.join('server', 'server.js')
  );

  const serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.stdio },
    debug: { module: serverModule, transport: TransportKind.stdio },
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [
      { scheme: 'file', language: 'multianim' },
      { scheme: 'file', language: 'anim' },
    ],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher('**/*.{manim,anim}'),
    },
    outputChannel,
  };

  client = new LanguageClient(
    'manimLanguageServer',
    'MultiAnim Language Server',
    serverOptions,
    clientOptions
  );

  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) return undefined;
  return client.stop();
}
