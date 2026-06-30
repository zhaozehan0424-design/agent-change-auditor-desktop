# Agent Change Auditor Desktop

[![CI](https://github.com/zhaozehan0424-design/agent-change-auditor-desktop/actions/workflows/ci.yml/badge.svg)](https://github.com/zhaozehan0424-design/agent-change-auditor-desktop/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

A lightweight Windows desktop wrapper for [Agent Change Auditor](https://github.com/zhaozehan0424-design/agent-change-auditor).

It gives the `aca` CLI a simple button-based workflow: select a project, initialize/start an audit, paste the agent claim, stop the audit, and preview the generated reports.

![Desktop preview](preview.png)

## Download / Portable Use

This first release is a portable Windows package. Download the release zip, extract it, then double-click:

```text
Start-AgentChangeAuditorDesktop.cmd
```

Local development path on the maintainer machine:

```text
C:\Users\33404\Documents\Codex\agent-change-auditor-desktop
```

## Requirements

- Windows
- PowerShell 5.1+
- The `aca` command available in `PATH`

Install/link the CLI first:

```powershell
cd C:\Users\33404\Documents\Codex\agent-change-auditor
npm link
aca --help
```

## Workflow

1. Click **选择...** and select the project folder to audit.
2. Click **1. 初始化 aca init** if the project is not a git repository yet.
3. Fill in the task label and click **2. 开始记录**.
4. Let an AI coding agent modify the selected project.
5. Paste the agent's self-summary into **Agent 自述 / Claim** and click **3. 保存 Agent 自述**.
6. Optionally enter test/build commands.
7. Click **4. 停止并生成报告**.
8. Preview or open `AI_CHANGE_AUDIT.zh-CN.md`, `AI_CHANGE_AUDIT.en.md`, or `AI_CHANGE_AUDIT.md`.

## What This App Does

- Wraps the deterministic `aca` CLI; it does not send project code to a model.
- Keeps the audit window manual: you decide when to start and stop.
- Helps non-CLI users collect an evidence-based review trail for AI-generated code changes.

## Development Checks

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-desktop.ps1
```

## Package

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\package.ps1
```

The zip is written to `dist/`.

## Status

See [REPOSITORY_STATUS.md](./REPOSITORY_STATUS.md).

## License

MIT. See [LICENSE](./LICENSE).
