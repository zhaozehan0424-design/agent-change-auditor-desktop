param(
    [switch]$SkipAca
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $root "AgentChangeAuditorDesktop.ps1"

$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count -gt 0) {
    $errors | Format-List | Out-String | Write-Error
    exit 1
}
Write-Host "syntax_ok=true"

if (-not $SkipAca) {
    $aca = Get-Command aca -ErrorAction SilentlyContinue
    if (-not $aca) {
        throw "aca command not found in PATH"
    }
    & aca --help | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "aca --help failed" }
    Write-Host "aca_ok=true"
}

$screenshot = Join-Path $env:TEMP ("aca-desktop-preview-" + [Guid]::NewGuid().ToString() + ".png")
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -ScreenshotPath $screenshot
if ($LASTEXITCODE -ne 0) { throw "screenshot command failed" }
if (-not (Test-Path -LiteralPath $screenshot)) { throw "screenshot was not created" }
if ((Get-Item -LiteralPath $screenshot).Length -lt 1000) { throw "screenshot too small" }
Remove-Item -LiteralPath $screenshot -Force -ErrorAction SilentlyContinue
Write-Host "screenshot_ok=true"
