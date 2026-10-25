param([string]$GamePath)
$ErrorActionPreference = 'Stop'
try {
    $manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
    $source = Join-Path $PSScriptRoot 'jaws_probe.pack'
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $manifest.pack_sha256) {
        throw 'Package checksum failed. Download/extract a fresh package.'
    }
    if (Get-Process -Name 'Warhammer2' -ErrorAction SilentlyContinue) {
        throw 'Close Warhammer II before installing.'
    }
    if (-not $GamePath) {
        $roots = @()
        $steam = Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue
        if ($steam.SteamPath) { $roots += $steam.SteamPath }
        if (${env:ProgramFiles(x86)}) { $roots += (Join-Path ${env:ProgramFiles(x86)} 'Steam') }
        if ($env:ProgramFiles) { $roots += (Join-Path $env:ProgramFiles 'Steam') }
        $candidates = @($roots | Select-Object -Unique | ForEach-Object {
            Join-Path $_ 'steamapps\common\Total War WARHAMMER II'
        } | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'Warhammer2.exe') })
        if ($candidates.Count -eq 1) { $GamePath = $candidates[0] }
        else { $GamePath = Read-Host 'Enter the game folder containing Warhammer2.exe (Steam > Manage > Browse local files)' }
    }
    $GamePath = (Resolve-Path -LiteralPath $GamePath.Trim('"')).Path
    if (-not (Test-Path -LiteralPath (Join-Path $GamePath 'Warhammer2.exe'))) {
        throw 'This is not the Windows Warhammer II game folder.'
    }
    $data = Join-Path $GamePath 'data'
    if (-not (Test-Path -LiteralPath $data -PathType Container)) { throw 'Game data folder missing.' }
    $target = Join-Path $data 'jaws_probe.pack'
    if (Test-Path -LiteralPath $target) {
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $manifest.pack_sha256) {
            throw 'A different jaws_probe.pack already exists. Back it up and remove it before installing this version.'
        }
        Write-Host 'This exact probe is already installed.'
    } else {
        # Exclusive creation protects an existing mod even if it appears after the check.
        $inputFile = [IO.File]::OpenRead($source)
        try {
            $outputFile = [IO.File]::Open($target, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
            try { $inputFile.CopyTo($outputFile) } finally { $outputFile.Dispose() }
        } finally { $inputFile.Dispose() }
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $manifest.pack_sha256) {
            throw 'Installed file verification failed. Remove the incomplete jaws_probe.pack and retry.'
        }
        Write-Host "Installed and verified: $target"
    }
    Write-Host 'Next: run Launch Warhammer II.cmd, open Mod Manager, enable jaws_probe, then Play.'
    Write-Host 'This is a diagnostic probe. It does not provide JAWS speech or keyboard navigation yet.'
    exit 0
} catch {
    Write-Host ("Installation failed: " + $_.Exception.Message)
    Write-Host 'If access was denied, run Install.cmd as administrator and enter the game path if prompted.'
    exit 1
}
