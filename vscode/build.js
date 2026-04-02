const { execSync } = require('child_process');

const buildTime = new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC';

execSync(
  `npx esbuild src/extension.ts --bundle --outfile=out/extension.js --external:vscode --format=cjs --platform=node --define:__BUILD_TIME__='"${buildTime}"'`,
  { stdio: 'inherit' }
);

console.log(`Build time: ${buildTime}`);
