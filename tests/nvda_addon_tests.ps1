$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$manifestPath = Join-Path $root 'nvda-addon\manifest.ini'
$modulePath = Join-Path $root 'nvda-addon\appModules\warhammer2.py'
$manifest = [IO.File]::ReadAllText($manifestPath)
$module = [IO.File]::ReadAllText($modulePath)

foreach ($required in @(
    'name = "warhammer2QuietMode"',
    'version = "0.1.0"',
    'minimumNVDAVersion = "2026.2"',
    'lastTestedNVDAVersion = "2026.2"'
)) {
    if (-not $manifest.Contains($required)) { throw "Missing manifest field: $required" }
}
if (-not $module.Contains('class AppModule(appModuleHandler.AppModule):')) { throw 'AppModule class is missing.' }
if (-not $module.Contains('sleepMode = True')) { throw 'Sleep mode is not enabled.' }
foreach ($forbidden in @('script_', '_gestures', 'mouse', 'click', 'sendInput', 'winUser')) {
    if ($module.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "Forbidden input capability in app module: $forbidden"
    }
}
Write-Output 'PASS: NVDA app module is Warhammer-specific sleep mode with no gestures or input capability'
