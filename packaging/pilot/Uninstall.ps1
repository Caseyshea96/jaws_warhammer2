$ErrorActionPreference = 'Stop'
try {
    if (Get-Process -Name 'Warhammer2' -ErrorAction SilentlyContinue) { throw 'Close Warhammer II first.' }
    $base = Join-Path $env:LOCALAPPDATA 'JawsWarhammer2'
    $lock = [IO.File]::Open((Join-Path $base 'companion.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
    try {
        $receipt = Get-Content -LiteralPath (Join-Path $base 'receipt.json') -Raw | ConvertFrom-Json
        $app = Join-Path $base 'App'
        if ($receipt.app_path -ne $app) { throw 'Receipt App path does not match this user.' }
        $manifest = Get-Content -LiteralPath (Join-Path $app 'manifest.json') -Raw | ConvertFrom-Json
        $target = Join-Path $receipt.game_path 'data/jaws_access.pack'
        if (Test-Path -LiteralPath $target) {
            if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $receipt.pack_sha256) {
                throw 'Installed pack changed; it was left untouched. Back it up and remove it manually if desired.'
            }
            Remove-Item -LiteralPath $target
        }
        foreach ($name in @('Companion.ps1','Bridge.cs','Native.cs','Protocol.ps1','Uninstall.ps1','README.txt','Start Pilot.cmd','Uninstall.cmd')) {
            $path = Join-Path $app $name
            if ((Test-Path -LiteralPath $path) -and (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $manifest.files.$name) {
                Remove-Item -LiteralPath $path
            }
        }
        foreach ($name in @('config.json','manifest.json')) { Remove-Item -LiteralPath (Join-Path $app $name) -ErrorAction SilentlyContinue }
        if (@(Get-ChildItem -LiteralPath $app -Force).Count -eq 0) { Remove-Item -LiteralPath $app }
        if ($env:OS -eq 'Windows_NT') {
            $shortcutPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Warhammer JAWS Pilot.lnk'
            if (Test-Path -LiteralPath $shortcutPath) {
                $shell = New-Object -ComObject WScript.Shell
                if ($shell.CreateShortcut($shortcutPath).TargetPath -eq (Join-Path $app 'Start Pilot.cmd')) { Remove-Item -LiteralPath $shortcutPath }
            }
        }
        Remove-Item -LiteralPath (Join-Path $base 'receipt.json')
        Write-Host 'Pilot removed. Saves, other mods, diagnostics and the old probe backup were preserved.'
    } finally { $lock.Dispose() }
    exit 0
} catch { Write-Host ('Uninstall failed: ' + $_.Exception.Message); exit 1 }
