// Compares the packaged LSP server (vscode/server/server.js) with a fresh build of it
// (lsp/bin/server.js), ignoring line endings: the files' own (a CRLF checkout on Windows)
// and "\r\n" escape sequences inside string literals (a literal spanning source lines
// embeds the checkout's line endings). Anything else that differs is drift: the parser or
// LSP sources changed without the packaged server being rebuilt.
//
//   node vscode/drift-check.js            compare (lsp/bin/server.js must be built)
//   node vscode/drift-check.js --build    build with `haxe lsp/lsp-server.hxml` first
//
// CI runs it as the "LSP server drift gate"; `npm run drift-check` in vscode/ is the same.
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const built = path.join(repoRoot, 'lsp', 'bin', 'server.js');
const packaged = path.join(__dirname, 'server', 'server.js');

if (process.argv.includes('--build')) {
  execSync('haxe lsp/lsp-server.hxml', { cwd: repoRoot, stdio: 'inherit' });
}

function normalizedLines(file) {
  if (!fs.existsSync(file)) {
    console.error(`ERROR: ${path.relative(repoRoot, file)} not found` + (file === built ? ' (run haxe lsp/lsp-server.hxml, or pass --build)' : ''));
    process.exit(2);
  }
  return fs.readFileSync(file, 'utf8')
    .replace(/\r\n/g, '\n')       // the file's line endings
    .replace(/\\r\\n/g, '\\n')    // "\r\n" escapes in string literals
    .split('\n');
}

const a = normalizedLines(packaged);
const b = normalizedLines(built);
const differing = [];
for (let i = 0; i < Math.max(a.length, b.length); i++) {
  if (a[i] !== b[i]) differing.push(i);
}

if (differing.length === 0) {
  console.log('LSP server in sync (line endings ignored)');
  process.exit(0);
}

console.error('ERROR: vscode/server/server.js is stale: parser/LSP sources changed without rebuilding the packaged server.');
console.error("Fix: run 'npm run build' in vscode/ (rebuilds and copies lsp/bin/server.js) and commit vscode/server/server.js.");
console.error(`${differing.length} line(s) differ; the first ones:`);
const clip = (s) => (s === undefined ? '<missing>' : s.length > 300 ? s.slice(0, 300) + '…' : s);
for (const i of differing.slice(0, 10)) {
  console.error(`  line ${i + 1}`);
  console.error(`    packaged: ${clip(a[i])}`);
  console.error(`    built:    ${clip(b[i])}`);
}
process.exit(1);
