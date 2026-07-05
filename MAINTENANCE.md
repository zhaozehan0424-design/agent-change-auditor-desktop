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

## 2026-07-05 - Routine maintenance check

- Fetched `origin/main` and confirmed the local branch was aligned with GitHub.
- Re-ran verification: `scripts/check-desktop.ps1 -> syntax_ok=true, aca_ok=true, screenshot_ok=true`.
- Portable Windows wrapper still launches and generates a preview screenshot.
- No new secrets, generated runtime artifacts, or release blockers were identified during this pass.

