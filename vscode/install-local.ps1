$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path "$PSScriptRoot\.."

Write-Host "=== Building LSP server (Haxe -> JS) ==="
Push-Location $repoRoot
try {
    haxe lsp/lsp-server.hxml
    if ($LASTEXITCODE -ne 0) { throw "LSP server build failed" }
} finally { Pop-Location }

Write-Host "=== Copying LICENSE ==="
Copy-Item "$repoRoot\LICENSE" "$PSScriptRoot\LICENSE" -Force

Write-Host "=== Copying server.js ==="
New-Item -ItemType Directory -Path "$PSScriptRoot\server" -Force | Out-Null
Copy-Item "$repoRoot\lsp\bin\server.js" "$PSScriptRoot\server\server.js" -Force

Write-Host "=== Bumping patch version ==="
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json','utf8'));const v=p.version.split('.');v[2]=parseInt(v[2])+1;p.version=v.join('.');fs.writeFileSync('package.json',JSON.stringify(p,null,2)+'\n');console.log('Version: '+p.version);"

Write-Host "=== Installing npm dependencies ==="
Push-Location $PSScriptRoot
try {
    npm install --silent
    if ($LASTEXITCODE -ne 0) { throw "npm install failed" }

    Write-Host "=== Building extension (TypeScript) ==="
    node build.js
    if ($LASTEXITCODE -ne 0) { throw "TypeScript build failed" }

    Write-Host "=== Removing old .vsix files ==="
    Remove-Item *.vsix -ErrorAction SilentlyContinue

    Write-Host "=== Packaging extension ==="
    npx @vscode/vsce package --allow-missing-repository
    if ($LASTEXITCODE -ne 0) { throw "Packaging failed" }

    Write-Host "=== Installing to VS Code ==="
    Get-Item *.vsix | ForEach-Object {
        Write-Host "Installing $_"
        code --install-extension $_.FullName --force
    }
} finally { Pop-Location }

Write-Host "=== Done! Reload VS Code to activate. ==="
