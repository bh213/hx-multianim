const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// 1. Rebuild the Haxe LSP server first, so the packaged server.js can never
// drift from the parser/LSP sources (CI verifies the copy is in sync).
const repoRoot = path.resolve(__dirname, '..');
execSync('haxe lsp/lsp-server.hxml', { cwd: repoRoot, stdio: 'inherit' });
fs.copyFileSync(
  path.join(repoRoot, 'lsp', 'bin', 'server.js'),
  path.join(__dirname, 'server', 'server.js')
);
console.log('LSP server rebuilt: lsp/bin/server.js -> vscode/server/server.js');

// 2. Bundle the extension client.
const buildTime = new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC';

execSync(
  `npx esbuild src/extension.ts --bundle --outfile=out/extension.js --external:vscode --format=cjs --platform=node --define:__BUILD_TIME__='"${buildTime}"'`,
  { stdio: 'inherit' }
);

console.log(`Build time: ${buildTime}`);
