param(
    [string]$GamePath,
    [switch]$Launch,
    [switch]$Console,
    [string]$ReplayFile,
    [switch]$NoHotkeys,
    [switch]$TraceSpeech,
    [ValidateSet('Jaws','Nvda')][string]$ScreenReader = 'Jaws'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Protocol.ps1')
Add-Type -Path (Join-Path $PSScriptRoot 'Bridge.cs')

if ($ReplayFile) {
    $state = New-ProtocolState
    foreach ($line in [IO.File]::ReadLines((Resolve-Path -LiteralPath $ReplayFile).Path)) {
        $r = Convert-BridgeRecord $line $state
        if ($null -ne $r) { Write-Output ($r.context + ': ' + $r.text) }
    }
    exit 0
}
$buildVersion = '0.2.5-dev'
$packageManifestPath = Join-Path $PSScriptRoot 'manifest.json'
if (Test-Path -LiteralPath $packageManifestPath) {
    $packageManifest = Get-Content -LiteralPath $packageManifestPath -Raw | ConvertFrom-Json
    if ($packageManifest.version) { $buildVersion = [string]$packageManifest.version }
    if ($packageManifest.stage -eq 'read-only-native-ui-diagnostic') {
        # This safety boundary is enforced here as well as by the launcher. A
        # direct invocation of the packaged companion must remain read-only.
        $NoHotkeys = $true
        $ScreenReader = 'Nvda'
    }
    if ($packageManifest.stage -eq 'frontend-activation-preview') {
        $NoHotkeys = $true
        $ScreenReader = 'Nvda'
        $TraceSpeech = $true
    }
}
if (-not $GamePath) {
    $configPath = Join-Path $PSScriptRoot 'config.json'
    if (Test-Path -LiteralPath $configPath) { $GamePath = (Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json).game_path }
}
if (-not $GamePath -or -not (Test-Path -LiteralPath (Join-Path $GamePath 'Warhammer2.exe'))) {
    throw 'Game path missing. Run the installer or supply -GamePath.'
}
$base = Join-Path $env:LOCALAPPDATA 'JawsWarhammer2'
[void][IO.Directory]::CreateDirectory($base)
$lockStream = $null
try { $lockStream = [IO.File]::Open((Join-Path $base 'companion.lock'), 'OpenOrCreate', 'ReadWrite', 'None') }
catch { Write-Host 'The companion is already running. Close its window before starting another.'; exit 1 }

try {
    $readerName = $(if ($ScreenReader -eq 'Nvda') { 'NVDA' } else { 'JAWS' })
    $script:Jaws = $null; $script:NvdaConnected = $false
    $script:Muted = $false; $script:HoverEnabled = $false
    $script:Last = 'Warhammer accessibility pilot is ready.'; $script:Step = 40; $script:LastHover = ''
    $script:LastHotkeyError = ''
    $script:PendingClick = $null; $script:ClickDeadline = [DateTime]::MinValue
    $script:StatusText = ''; $script:StatusControl = $null
    $script:LastError = ''; $script:LastErrorTime = [DateTime]::MinValue
    $diagnostic = Join-Path $base 'companion.log'
    $script:SpeechRequestId = 0L
    $speechTrace = Join-Path $base 'speech-trace.jsonl'
    function Write-SpeechTrace([string]$Event, [hashtable]$Details) {
        if (-not $TraceSpeech) { return }
        try {
            if ((Test-Path -LiteralPath $speechTrace) -and (Get-Item -LiteralPath $speechTrace).Length -gt 1048576) {
                Move-Item -LiteralPath $speechTrace -Destination ($speechTrace + '.previous') -Force
            }
            $record = @{ time_utc = [DateTime]::UtcNow.ToString('o'); process_id = $PID;
                event = $Event; request_id = $script:SpeechRequestId; details = $Details }
            Add-Content -LiteralPath $speechTrace -Value ($record | ConvertTo-Json -Compress -Depth 4) -Encoding UTF8
        } catch { } # Diagnostic I/O must never prevent speech.
    }
    if ((Test-Path -LiteralPath $diagnostic) -and (Get-Item -LiteralPath $diagnostic).Length -gt 1048576) {
        Move-Item -LiteralPath $diagnostic -Destination ($diagnostic + '.previous') -Force
    }
    function Set-Status([string]$Text) {
        if ($script:StatusText -eq $Text) { return }
        $script:StatusText = $Text
        if ($script:StatusControl) { $script:StatusControl.Text = $Text }
        Write-Host $Text
    }
    function Log-Error([string]$Text) {
        if ($script:LastError -eq $Text -and ([DateTime]::UtcNow - $script:LastErrorTime).TotalSeconds -lt 30) { return }
        $script:LastError = $Text; $script:LastErrorTime = [DateTime]::UtcNow
        try {
            if ((Test-Path -LiteralPath $diagnostic) -and (Get-Item -LiteralPath $diagnostic).Length -gt 1048576) {
                Move-Item -LiteralPath $diagnostic -Destination ($diagnostic + '.previous') -Force
            }
            Add-Content -LiteralPath $diagnostic -Value ((Get-Date -Format o) + ' ' + $Text) -Encoding UTF8
        } catch {}
    }
    function Connect-ScreenReader {
        if ($Console) { return $true }
        if ($ScreenReader -eq 'Nvda') {
            try {
                if (-not ('WarhammerAccessibility.NvdaController' -as [type])) {
                    Add-Type -Path (Join-Path $PSScriptRoot 'NvdaController.cs')
                }
                [WarhammerAccessibility.NvdaController]::Initialize((Join-Path $PSScriptRoot 'nvdaControllerClient.dll'))
                $code = [WarhammerAccessibility.NvdaController]::TestIfRunning()
                if ($code -ne 0) { throw [ComponentModel.Win32Exception]::new($code) }
                $script:NvdaConnected = $true
                Set-Status 'NVDA connected. Waiting for game messages.'
                return $true
            } catch {
                $script:NvdaConnected = $false
                Set-Status 'NVDA unavailable. Start NVDA, then choose Test NVDA to reconnect.'
                Log-Error $_.Exception.Message
                return $false
            }
        }
        try {
            $script:Jaws = New-Object -ComObject 'FreedomSci.JawsApi'
            Set-Status 'JAWS connected. Waiting for game messages.'
            return $true
        } catch {
            $script:Jaws = $null
            Set-Status 'JAWS unavailable. Start JAWS, then choose Test JAWS to reconnect.'
            Log-Error $_.Exception.Message
            return $false
        }
    }
    function Speak([string]$Text, [switch]$Force) {
        $script:SpeechRequestId++
        Write-SpeechTrace 'request' @{ text = $Text; characters = $Text.Length; reader = $ScreenReader;
            muted = [bool]$script:Muted; forced = [bool]$Force; connected = [bool]$script:NvdaConnected }
        $script:Last = $Text
        if ($Console) { Write-Output $Text; return }
        if ($script:Muted -and -not $Force) { return }
        if ($ScreenReader -eq 'Nvda') {
            if (-not $script:NvdaConnected) { return }
            try {
                $code = [WarhammerAccessibility.NvdaController]::Speak($Text, $true)
                Write-SpeechTrace 'nvda-return' @{ code = $code; interrupt_previous = $true }
                if ($code -ne 0) { throw [ComponentModel.Win32Exception]::new($code) }
                $brailleCode = [WarhammerAccessibility.NvdaController]::Braille($Text)
                if ($brailleCode -ne 0) { Log-Error ('NVDA braille output failed: ' + $brailleCode) }
            } catch {
                $script:NvdaConnected = $false
                Write-SpeechTrace 'nvda-error' @{ message = $_.Exception.Message }
                Set-Status 'NVDA disconnected. Start NVDA, then choose Test NVDA to reconnect.'
                Log-Error $_.Exception.Message
            }
            return
        }
        if (-not $script:Jaws) { return }
        try {
            $ok = $script:Jaws.SayString($Text, $true)
            if ($ok -eq $false) { throw 'JAWS rejected speech. Check that JAWS is running.' }
        } catch { $script:Jaws = $null; Set-Status 'JAWS disconnected. Choose Test JAWS to reconnect.'; Log-Error $_.Exception.Message }
    }
    function Stop-Speech {
        Write-SpeechTrace 'stop-request' @{}
        if ($ScreenReader -eq 'Nvda') {
            if ($script:NvdaConnected) {
                try {
                    $code = [WarhammerAccessibility.NvdaController]::CancelSpeech()
                    if ($code -ne 0) { throw [ComponentModel.Win32Exception]::new($code) }
                } catch { $script:NvdaConnected = $false; Log-Error $_.Exception.Message }
            }
            return
        }
        if ($script:Jaws) { try { $script:Jaws.StopSpeech() } catch { Log-Error $_.Exception.Message } }
    }
    function Test-Speech {
        if (-not (Connect-ScreenReader)) { return $false }
        Speak ('Warhammer accessibility pilot. ' + $readerName + ' speech test successful.') -Force
        return $true
    }
    function Toggle-Mute {
        $script:Muted = -not $script:Muted
        Stop-Speech
        Speak $(if ($script:Muted) { 'Pilot speech muted.' } else { 'Pilot speech enabled.' }) -Force
    }
    function Launch-Game {
        $connected = $(if ($ScreenReader -eq 'Nvda') { $script:NvdaConnected } else { $null -ne $script:Jaws })
        if (-not $connected -and -not (Connect-ScreenReader)) {
            Set-Status ($readerName + ' must be connected before the game can launch.')
            return $false
        }
        Start-Process 'steam://rungameid/594570'
        return $true
    }
    $tails = @(
        [JawsPilot.Tail]::new((Join-Path $base 'bridge.jsonl'), $true),
        [JawsPilot.Tail]::new((Join-Path $GamePath 'jaws_access.jsonl'), $true)
    )
    $states = @((New-ProtocolState), (New-ProtocolState))
    function Read-Bridge {
        if (-not $Console -and $keys) {
            $failures = $keys.UpdateFocus(-not $NoHotkeys)
            $failureKey = $failures -join ','
            if ($failures.Count -and $failureKey -ne $script:LastHotkeyError) {
                Log-Error ('Shortcut registration/release failed for IDs: ' + ($failures -join ','))
                Speak 'Some companion shortcuts could not be registered or released. See the diagnostic log.' -Force
            }
            $script:LastHotkeyError = $failureKey
        }
        if ($null -ne $script:PendingClick -and -not $Console) {
            if (-not [JawsPilot.Pointer]::GameFocused() -or [DateTime]::UtcNow -gt $script:ClickDeadline) {
                $script:PendingClick = $null
                Speak 'Pending click cancelled.'
            } elseif ([JawsPilot.Pointer]::ModifiersReleased()) {
                $right = [bool]$script:PendingClick
                $script:PendingClick = $null
                Speak ([JawsPilot.Pointer]::Click($right))
            }
        }
        $latest = $null; $lastHoverRecord = $null; $batch = New-SpeechBatch
        for ($i = 0; $i -lt $tails.Count; $i++) {
            try {
                foreach ($line in $tails[$i].Poll()) {
                    $r = Convert-BridgeRecord $line $states[$i]
                    if ($null -eq $r) { continue }
                    if ($r.kind -eq 'hover') { $lastHoverRecord = $r }
                    else { $latest = $r; Add-SpeechRecord $batch $r }
                }
            } catch { Log-Error $_.Exception.Message }
        }
        if ($latest) {
            Set-Status ('Connected to game: ' + $latest.context + '. Last message: ' + $latest.text.Substring(0, [Math]::Min(100, $latest.text.Length)))
            if ($batch.Dropped) { Log-Error ("Speech batch overflow: " + $batch.Dropped + " records; original messages remain in the bridge file.") }
            Speak (Get-SpeechBatchText $batch)
        } elseif ($lastHoverRecord -and $script:HoverEnabled -and $lastHoverRecord.text -ne $script:LastHover) {
            $script:LastHover = $lastHoverRecord.text
            Speak $lastHoverRecord.text
        }
    }
    if ($Console) {
        Write-Host 'Console bridge; Ctrl+C to stop. Existing log history is skipped.'
        while ($true) { Read-Bridge; Start-Sleep -Milliseconds 100 }
    }
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    if (-not $NoHotkeys) {
        Add-Type -Path @((Join-Path $PSScriptRoot 'Native.cs'), (Join-Path $PSScriptRoot 'HotkeyPolicy.cs')) -ReferencedAssemblies @('System.dll','System.Windows.Forms.dll')
        [void][JawsPilot.Pointer]::SetProcessDPIAware()
    }
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form = New-Object Windows.Forms.Form
    $form.Text = $(if ($NoHotkeys) { 'Warhammer II ' + $readerName + ' read-only keyboard browser ' + $buildVersion } else { 'Warhammer II ' + $readerName + ' Pilot ' + $buildVersion })
    if ($packageManifest.stage -eq 'frontend-activation-preview') { $form.Text = 'Warhammer II NVDA frontend accessibility preview ' + $buildVersion }
    $form.Width = 700; $form.Height = 490
    $form.StartPosition = 'CenterScreen'
    $panel = New-Object Windows.Forms.FlowLayoutPanel
    $panel.Dock = 'Fill'; $panel.FlowDirection = 'TopDown'; $panel.WrapContents = $false; $panel.AutoScroll = $true
    $form.Controls.Add($panel)
    $label = New-Object Windows.Forms.Label
    $label.Text = 'Experimental co-op accessibility pilot. Enable jaws_access in the game Mod Manager. F2 next, F3 previous, F4 twice to activate. Ctrl+F2 changes category.'
    if ($NoHotkeys) { $label.Text = 'Read-only keyboard browser: companion global hotkeys disabled. In the main menu, tap F2 for next or F3 for previous. F4 is disabled. No mouse or game command is used.' }
    if ($packageManifest.stage -eq 'frontend-activation-preview') {
        $label.Text = 'F2 next, F3 previous. Press F4 twice within four seconds on a supported control. New Campaign opens campaign setup; Continue supports the captured Vortex selection. Other campaign choices remain read only. Use Escape to return. Enter is not bound.'
    }
    $label.Width = 650; $label.Height = 60; $panel.Controls.Add($label)
    $script:StatusControl = New-Object Windows.Forms.TextBox
    $script:StatusControl.ReadOnly = $true; $script:StatusControl.Multiline = $true
    $script:StatusControl.Width = 650; $script:StatusControl.Height = 55
    $script:StatusControl.AccessibleName = 'Connection status'
    $panel.Controls.Add($script:StatusControl)
    function Add-Button([string]$Name, [scriptblock]$Action) {
        $button = New-Object Windows.Forms.Button
        $button.Text = $Name; $button.Width = 640; $button.Height = 29
        $button.Add_Click($Action); $panel.Controls.Add($button)
    }
    Add-Button ('&Test ' + $readerName + ' / reconnect') { [void](Test-Speech) }
    Add-Button '&Launch game through Steam' { [void](Launch-Game) }
    Add-Button $(if ($NoHotkeys) { '&Repeat last message' } else { '&Repeat last message (Ctrl+Alt+R)' }) { Speak $script:Last -Force }
    Add-Button $(if ($NoHotkeys) { '&Stop speech' } else { '&Stop speech (Ctrl+Alt+S)' }) { Stop-Speech }
    Add-Button $(if ($NoHotkeys) { '&Mute / unmute' } else { '&Mute / unmute (Ctrl+Alt+M)' }) { Toggle-Mute }
    if (-not $NoHotkeys) {
        Add-Button 'Toggle &hover speech (Ctrl+Alt+H)' {
            $script:HoverEnabled = -not $script:HoverEnabled
            Speak $(if ($script:HoverEnabled) { 'Hover speech on.' } else { 'Hover speech off.' })
        }
    }
    Add-Button '&Open diagnostic folder' { Start-Process explorer.exe -ArgumentList $base }
    $keys = $null
    # Ctrl+Alt: R/S/M/H, arrows, Enter, Space, C to center, F fine/coarse.
    $keyCodes = @(82,83,77,72,37,38,39,40,13,32,67,70)
    if (-not $NoHotkeys) {
        $keys = [JawsPilot.Hotkeys]::new()
        for ($i = 0; $i -lt $keyCodes.Count; $i++) { $keys.Configure($i + 1, $keyCodes[$i]) }
        $keys.Add_Pressed({ param($sender, $eventArgs)
        switch ($eventArgs.Id) {
            1 { Speak $script:Last -Force }
            2 { Stop-Speech }
            3 { Toggle-Mute }
            4 { $script:HoverEnabled = -not $script:HoverEnabled; Speak $(if ($script:HoverEnabled) { 'Hover speech on.' } else { 'Hover speech off.' }) }
            5 { Speak ([JawsPilot.Pointer]::Move(-$script:Step,0,$false)) }
            6 { Speak ([JawsPilot.Pointer]::Move(0,-$script:Step,$false)) }
            7 { Speak ([JawsPilot.Pointer]::Move($script:Step,0,$false)) }
            8 { Speak ([JawsPilot.Pointer]::Move(0,$script:Step,$false)) }
            9 { $script:PendingClick = $true; $script:ClickDeadline = [DateTime]::UtcNow.AddSeconds(2); Speak 'Release modifiers to right click.' }
            10 { $script:PendingClick = $false; $script:ClickDeadline = [DateTime]::UtcNow.AddSeconds(2); Speak 'Release modifiers to left click.' }
            11 { Speak ([JawsPilot.Pointer]::Move(0,0,$true)) }
            12 { $script:Step = $(if ($script:Step -eq 40) { 5 } else { 40 }); Speak ('Cursor step ' + $script:Step + ' pixels.') }
        }
        })
    }
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 100
    $timer.Add_Tick({ Read-Bridge })
    $form.Add_Shown({
        $connected = Test-Speech
        $timer.Start()
        if ($Launch -and $connected) { [void](Launch-Game) }
        elseif ($Launch) { Set-Status ($readerName + ' must be connected before the game can launch.') }
    })
    try { [void]$form.ShowDialog() }
    finally { $timer.Stop(); $timer.Dispose(); if ($keys) { $keys.Dispose() }; $form.Dispose(); Stop-Speech }
} catch {
    Write-Host ('Warhammer accessibility pilot failed: ' + $_.Exception.Message)
    if (Get-Command Log-Error -ErrorAction SilentlyContinue) { Log-Error $_.Exception.Message }
    exit 1
} finally { if ($lockStream) { $lockStream.Dispose() } }
