# Enable a test lease, start the speech companion and launch the game through
# Steam (which opens TW Mod Manager; click PLAY there). Records the owned
# companion so Stop-Session.ps1 only ever stops processes this session started.
param(
    [Parameter(Mandatory=$true)][string]$Evidence,   # folder under work/
    [ValidateRange(1,1800)][int]$LeaseSeconds = 1800,
    [switch]$CampaignDiscovery, # opt-in read-only campaign snapshot, no map actions
    [switch]$StringFindProbe,                         # opt-in 0.6.18 probe
    [switch]$Direct,  # launch Warhammer2.exe with TWMM's mod list (no PLAY click needed)
    [switch]$WithIntro  # with -Direct: play the startup movies (default skips them via work/skip-intro)
)
$ErrorActionPreference = 'Stop'
$base = Join-Path $env:LOCALAPPDATA 'JawsWarhammer2'
$app = Join-Path $base 'App'
[void][IO.Directory]::CreateDirectory($Evidence)
if (Get-CimInstance Win32_Process -Filter "Name='Warhammer2.exe'") { throw 'Game already running; close it first.' }
if ($CampaignDiscovery) {
    $campaignFlag = Join-Path $base 'campaign-discovery.tsv'
    if (Test-Path -LiteralPath $campaignFlag) { throw 'Another campaign discovery flag exists; inspect its owner before replacing it.' }
    $campaignSettings = Join-Path $env:APPDATA 'The Creative Assembly\Warhammer2'
    $campaignBackup = Join-Path $Evidence 'pre-campaign-backup'
    [void][IO.Directory]::CreateDirectory($campaignBackup)
    foreach ($name in @('save_games','advice_history')) {
        $source = Join-Path $campaignSettings $name
        if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination (Join-Path $campaignBackup $name) -Recurse }
    }
    $campaignOwner = [guid]::NewGuid().ToString('N')
    $campaignExpiry = [datetime]::UtcNow.AddSeconds($LeaseSeconds).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $campaignRaw = "WH2CAM1`t$campaignOwner`t$campaignExpiry`tverify`n"
    [IO.File]::WriteAllText($campaignFlag, $campaignRaw, (New-Object Text.UTF8Encoding $false))
    [pscustomobject]@{path=$campaignFlag;owner=$campaignOwner;expires=$campaignExpiry;raw=$campaignRaw} |
        ConvertTo-Json | Set-Content (Join-Path $Evidence 'owned-campaign-flag.json') -Encoding UTF8
}
$probe = Join-Path $base 'string-find-probe.flag'
if ($StringFindProbe) { Set-Content -LiteralPath $probe -Value '1' -Encoding Ascii }
elseif (Test-Path -LiteralPath $probe) { Remove-Item -LiteralPath $probe }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $app 'Automation.ps1') -Action Enable -LeaseSeconds $LeaseSeconds
if ($LASTEXITCODE) { throw 'Lease enable failed.' }
$companion = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like '*JawsWarhammer2\App\Companion.ps1*' }
if (-not $companion) {
    $proc = Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
        '-NoProfile','-Sta','-ExecutionPolicy','Bypass','-File',(Join-Path $app 'Companion.ps1'),
        '-NoHotkeys','-MenuKeys','-ScreenReader','Nvda','-TraceSpeech')
    Start-Sleep -Seconds 2
    $companion = Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)"
    if (-not $companion) { throw 'Companion exited immediately.' }
}
$companion | Select-Object ProcessId,Name,ExecutablePath,CommandLine,@{n='CreationDate';e={$_.CreationDate.ToString('o')}} |
    ConvertTo-Json | Set-Content (Join-Path $Evidence 'owned-companion.json') -Encoding UTF8
"COMPANION=$($companion.ProcessId)"
if ($Direct) {
    # Same command line TW Mod Manager uses; check its list enables only our pack.
    $mods = Join-Path $env:APPDATA 'The Creative Assembly\TWMM\games\wh2\used_mods.txt'
    $enabled = @(Get-Content -LiteralPath $mods | Where-Object { $_ -like 'mod *' })
    if ($enabled.Count -ne 1 -or $enabled[0] -ne 'mod "jaws_access.pack";') { throw "TWMM mod list is not exactly jaws_access.pack: $enabled" }
    $game = 'C:\Program Files (x86)\Steam\steamapps\common\Total War WARHAMMER II'
    if (-not $WithIntro) {
        # A test-only mod list beside the skip pack; TWMM's own list is untouched.
        $skipPack = Join-Path $PSScriptRoot '..\..\work\skip-intro\jaws_skip_intro.pack'
        if (-not (Test-Path -LiteralPath $skipPack)) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Build-SkipIntro.ps1') | Out-Null
            if ($LASTEXITCODE) { throw 'Skip-intro pack build failed.' }
        }
        $skipDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..\work\skip-intro')).Path
        $mods = Join-Path $skipDir 'test_mods.txt'
        $lines = @(
            ('add_working_directory "' + ($game -replace '\\','/') + '/data";'),
            ('add_working_directory "' + ($skipDir -replace '\\','/') + '";'),
            'mod "jaws_skip_intro.pack";',
            'mod "jaws_access.pack";')
        [IO.File]::WriteAllText($mods, ($lines -join "`n") + "`n", (New-Object Text.UTF8Encoding $false))
    }
    Start-Process -FilePath (Join-Path $game 'Warhammer2.exe') -WorkingDirectory $game -ArgumentList ('"' + $mods + '"'),'; -dx11'
    'Direct launch requested. Run Wait-Game.ps1.'
} else {
    Start-Process 'steam://rungameid/594570'
    'Steam launch requested. Click PLAY in TW Mod Manager, then run Wait-Game.ps1.'
}
