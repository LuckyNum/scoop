# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal Scoop bucket repository (bucket name: `LuckyNum`) containing Windows application manifests. Scoop is a command-line package manager for Windows, and this bucket provides custom app definitions for installation via `scoop install`.

## Development Commands

### Testing
```powershell
.\bin\test.ps1              # Run full test suite (requires Pester 5.2.0+ and BuildHelpers 2.0.1+)
```

### Validation
```powershell
.\bin\checkver.ps1          # Check for new versions of packages
.\bin\checkhashes.ps1       # Verify file hashes
.\bin\checkurls.ps1         # Validate download URLs
.\bin\missing-checkver.ps1  # Find packages without checkver field
.\bin\formatjson.ps1        # Format JSON manifests
```

### Test prerequisites
Tests require `$env:SCOOP_HOME` to be set (auto-detected from `scoop prefix scoop` if not set).

## Architecture

### Bucket Structure
- `bucket/*.json` - Package manifests (core content)
- `deprecated/` - Deprecated manifest files
- `bin/*.ps1` - Helper scripts that delegate to Scoop core functionality
- `scripts/` - Custom scripts referenced by manifests

### Manifest Schema
All manifests follow the official Scoop schema (validated via `.vscode/settings.json` against `https://raw.githubusercontent.com/ScoopInstaller/Scoop/master/schema.json`).

**Key manifest patterns:**
- **Multi-architecture**: Use `architecture.64bit`, `architecture.32bit`, `architecture.arm64` with separate `url` and `hash` for each
- **Installer extraction**: Some packages (e.g., drawio.json) extract from NSIS installers using `pre_install` with `Expand-7zipArchive`
- **Hash extraction**: Use `autoupdate.hash.url` with regex to extract hashes from release pages (e.g., PowerShell manifest)
- **Persistence**: Use `persist` array for user data directories to survive updates
- **Chinese mirrors**: Some manifests use `ghproxy.com` proxy for GitHub releases

**Checkver patterns:**
- `"checkver": "github"` - Auto-detect from GitHub releases
- `{"url": "...", "regex": "..."}` - Custom URL with regex extraction

### Automation
- **CI**: `.github/workflows/ci.yml` runs Pester tests on Windows PowerShell and PowerShell Core
- **Excavator**: `.github/workflows/excavator.yml` runs every 4 hours to auto-update packages
- **Issue/PR handlers**: Automated workflows for verification requests and hash errors

### Code Style
- UTF-8 encoding, CRLF line endings (Windows-specific tool)
- 4-space indentation (2-space for YAML)
- JSON manifests use lowercase with hyphens for naming (e.g., `tiny-rdm.json`)
- PowerShell code formatting uses OTBS preset (configured in `.vscode/settings.json`)

## Adding a New Package

1. Create `bucket/<app-name>.json` following the schema
2. Include `checkver` for automatic version detection
3. Include `autoupdate` with URL patterns using `$version` variable
4. For multi-architecture packages, provide all variants when available
5. Use `persist` for user data, `shortcuts` for GUI applications
6. Run `.\bin\test.ps1` to validate
