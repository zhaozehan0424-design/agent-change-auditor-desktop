$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $root "VERSION") -Raw).Trim()
$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "scripts\check-desktop.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$packageRoot = Join-Path $env:TEMP ("aca-desktop-package-" + [Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null
$folder = Join-Path $packageRoot "AgentChangeAuditorDesktop"
New-Item -ItemType Directory -Force -Path $folder | Out-Null

$files = @(
    "AgentChangeAuditorDesktop.ps1",
    "Start-AgentChangeAuditorDesktop.cmd",
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
    "SECURITY.md",
    "preview.png",
    "VERSION"
)
foreach ($file in $files) {
    Copy-Item -LiteralPath (Join-Path $root $file) -Destination $folder -Force
}

$zip = Join-Path $dist "AgentChangeAuditorDesktop-v$version.zip"
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $folder "*") -DestinationPath $zip -Force
Remove-Item -LiteralPath $packageRoot -Recurse -Force
Write-Host "package=$zip"
