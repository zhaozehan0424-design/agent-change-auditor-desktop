# Maintenance

This repository contains the Windows desktop wrapper for Agent Change Auditor. The core audit engine remains in the `agent-change-auditor` CLI repository.

## Release Checklist

1. Verify `aca --help` works locally.
2. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-desktop.ps1`.
3. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\package.ps1`.
4. Upload the generated zip from `dist/` to a GitHub release.
5. Update `CHANGELOG.md` and `REPOSITORY_STATUS.md`.

## 2026-06-30 - Initial publication

- Verified PowerShell parser syntax.
- Verified the GUI launches.
- Generated `preview.png` from the app itself.
- Added packaging and repository hygiene files.
