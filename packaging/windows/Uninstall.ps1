param([string]$GamePath)
$ErrorActionPreference = 'Stop'
try {
    if (Get-Process -Name 'Warhammer2' -ErrorAction SilentlyContinue) { throw 'Close the game first.' }
    if (-not $GamePath) { $GamePath = Read-Host 'Enter the game folder containing Warhammer2.exe' }
    $GamePath = (Resolve-Path -LiteralPath $GamePath.Trim('"')).Path
    if (-not (Test-Path -LiteralPath (Join-Path $GamePath 'Warhammer2.exe'))) { throw 'Invalid game folder.' }
    $target = Join-Path $GamePath 'data\jaws_probe.pack'
    $manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
    if (-not (Test-Path -LiteralPath $target)) { Write-Host 'Probe is not installed.'; exit 0 }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $manifest.pack_sha256) {
        throw 'Installed probe differs from this package. It has been left untouched.'
    }
    Remove-Item -LiteralPath $target
    Write-Host 'Removed the matching diagnostic mod. Logs, saves and other mods were preserved.'
    exit 0
} catch { Write-Host $_.Exception.Message; exit 1 }
