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

    Write-Host "=== Discovering VS Code profiles ==="
    $profiles = @("Default")
    $storageJson = Join-Path $env:APPDATA "Code\User\globalStorage\storage.json"
    if (Test-Path $storageJson) {
        $storage = Get-Content $storageJson -Raw | ConvertFrom-Json
        if ($storage.userDataProfiles) {
            $profiles += $storage.userDataProfiles | ForEach-Object { $_.name }
        }
    }

    if ($profiles.Count -eq 1) {
        $selected = @("Default")
    } else {
        Write-Host ""
        Write-Host "Available VS Code profiles:"
        for ($i = 0; $i -lt $profiles.Count; $i++) {
            Write-Host "  [$i] $($profiles[$i])"
        }
        Write-Host "  [a] All profiles"
        Write-Host ""
        $choice = Read-Host "Select profile(s) to install into (comma-separated numbers, or 'a' for all)"

        if ($choice -eq 'a') {
            $selected = $profiles
        } else {
            $indices = $choice -split ',' | ForEach-Object { [int]$_.Trim() }
            $selected = $indices | ForEach-Object { $profiles[$_] }
        }
    }

    Write-Host "=== Installing to VS Code ==="
    Get-Item *.vsix | ForEach-Object {
        $vsix = $_.FullName
        foreach ($profile in $selected) {
            Write-Host "Installing into profile: $profile"
            if ($profile -eq "Default") {
                code.cmd --install-extension $vsix --force
            } else {
                code.cmd --install-extension $vsix --force --profile $profile
            }
        }
    }
} finally { Pop-Location }

Write-Host "=== Done! Reload VS Code to activate. ==="
