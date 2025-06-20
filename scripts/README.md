# Release Scripts

This directory contains scripts to automate the release process for the hx-multianim library.

## Available Scripts

### PowerShell Script (Windows)
- **File**: `release.ps1`
- **Usage**: `.\scripts\release.ps1 [patch|minor|major] "Release notes"`

### Bash Script (Unix/Linux/macOS)
- **File**: `release.sh`
- **Usage**: `./scripts/release.sh [patch|minor|major] "Release notes"`

## Prerequisites

### Required Tools
1. **Git** - Must be installed and configured
2. **GitHub Token** - For creating GitHub releases (optional but recommended)

### Optional Tools
- **jq** - For better JSON parsing in bash script (falls back to sed if not available)

## Setup

### 1. Install Git
- **Windows**: Download from [git-scm.com](https://git-scm.com/)
- **macOS**: `brew install git`
- **Linux**: Use your package manager

### 2. Set up GitHub Token
Create a GitHub Personal Access Token with `repo` permissions:

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token with `repo` scope
3. Set as environment variable:

**Windows (PowerShell)**:
```powershell
$env:GITHUB_TOKEN = "your_token_here"
```

**Unix/Linux/macOS**:
```bash
export GITHUB_TOKEN="your_token_here"
```

**Permanent setup**:
- Add to your shell profile (`.bashrc`, `.zshrc`, etc.)
- Or add to Windows environment variables

### 3. Make Scripts Executable (Unix/Linux/macOS)
```bash
chmod +x scripts/release.sh
```

## Usage Examples

### Patch Release (Bug Fix)
```bash
# Bash
./scripts/release.sh patch "Fixed animation timing issue in state transitions"

# PowerShell
.\scripts\release.ps1 patch "Fixed animation timing issue in state transitions"
```

### Minor Release (New Feature)
```bash
# Bash
./scripts/release.sh minor "Added support for custom animation filters"

# PowerShell
.\scripts\release.ps1 minor "Added support for custom animation filters"
```

### Major Release (Breaking Changes)
```bash
# Bash
./scripts/release.sh major "Breaking: Changed animation API structure"

# PowerShell
.\scripts\release.ps1 major "Breaking: Changed animation API structure"
```

## What the Script Does

1. **Validates Prerequisites**
   - Checks if Git is available
   - Verifies you're in a git repository
   - Confirms `haxelib.json` exists

2. **Version Management**
   - Reads current version from `haxelib.json`
   - Calculates new version based on type (patch/minor/major)
   - Updates version and release notes in `haxelib.json`

3. **Git Operations**
   - Stages all changes
   - Creates commit with version and release notes
   - Creates annotated tag
   - Pushes changes and tag to remote

4. **GitHub Release** (if token provided)
   - Creates GitHub release with tag
   - Sets release notes
   - Provides release URL

5. **Final Instructions**
   - Reminds you to publish to Haxelib

## Version Semantics

- **Patch** (1.2.3 → 1.2.4): Bug fixes, small improvements
- **Minor** (1.2.3 → 1.3.0): New features, backward compatible
- **Major** (1.2.3 → 2.0.0): Breaking changes, major updates

## Manual Steps After Release

After running the script, you may want to:

1. **Publish to Haxelib**:
   ```bash
   haxelib submit .
   ```

2. **Update Documentation** (if needed):
   - Update README.md
   - Update CHANGELOG.md
   - Update examples

3. **Announce Release**:
   - Post on forums
   - Update social media
   - Notify users

## Troubleshooting

### Common Issues

**"Git is not available"**
- Install Git and ensure it's in your PATH

**"Not in a git repository"**
- Run the script from the project root directory

**"haxelib.json not found"**
- Ensure you're in the correct directory

**"Failed to create GitHub release"**
- Check your GitHub token has `repo` permissions
- Verify the token is set correctly

**Permission denied (bash script)**
- Make the script executable: `chmod +x scripts/release.sh`

### Getting Help

If you encounter issues:

1. Check the error messages for specific details
2. Verify all prerequisites are met
3. Ensure you have proper permissions
4. Check your GitHub token permissions

## Security Notes

- Never commit your GitHub token to version control
- Use environment variables for sensitive data
- Regularly rotate your GitHub tokens
- Use minimal required permissions for tokens 