# Windows PowerShell 5.1 compatible; also tested with portable PowerShell on Linux.
function New-ProtocolState {
    return @{ Session = ''; Sequence = 0L; Retired = (New-Object 'System.Collections.Generic.HashSet[string]'); Invalid = 0 }
}
function Convert-BridgeRecord {
    param([string]$Line, [hashtable]$State)
    try {
        if ($Line.Length -gt 32768) { throw 'Oversized record' }
        $r = $Line | ConvertFrom-Json -ErrorAction Stop
        if ($r.version -ne 1 -or $r.session -isnot [string] -or $r.session.Length -gt 200 -or
            [string]::IsNullOrEmpty($r.session) -or $r.text -isnot [string] -or $r.text.Length -gt 8000 -or
            $r.context -notin @('frontend','campaign','battle') -or
            $r.kind -notin @('speech','focus','result','hello','context','error','hover')) { throw 'Invalid envelope' }
        $seq = 0L
        if (-not [long]::TryParse([string]$r.sequence, [ref]$seq) -or $seq -lt 1) { throw 'Invalid sequence' }
        if ($State.Retired.Contains($r.session)) { return $null }
        if ($State.Session -ne $r.session) {
            if ($State.Session) { [void]$State.Retired.Add($State.Session) }
            # Bound lifetime memory. A session never sends game commands.
            if ($State.Retired.Count -gt 1000) { $State.Retired.Clear() }
            $State.Session = $r.session; $State.Sequence = 0L
        }
        if ($seq -le $State.Sequence) { return $null }
        $State.Sequence = $seq
        return $r
    } catch { $State.Invalid++; return $null }
}

# Collapse consecutive focus updates only. Preserve errors/results and their order.
# One batch becomes one utterance so a later event in the same poll cannot flush it.
function New-SpeechBatch { return @{ Items = (New-Object 'System.Collections.Generic.List[object]'); Dropped = 0; Characters = 0 } }
function Add-SpeechRecord {
    param([hashtable]$Batch, $Record)
    if ($Record.kind -eq 'hover') { return }
    $items = $Batch.Items
    if ($Record.kind -eq 'focus' -and $items.Count -gt 0 -and $items[$items.Count-1].kind -eq 'focus') {
        $Batch.Characters -= $items[$items.Count-1].text.Length
        $items.RemoveAt($items.Count-1)
    }
    if ($items.Count -ge 16 -or $Batch.Characters + $Record.text.Length -gt 8000) {
        $Batch.Dropped++; return
    }
    $items.Add($Record)
    $Batch.Characters += $Record.text.Length
}
function Get-SpeechBatchText {
    param([hashtable]$Batch)
    $text = ($Batch.Items | ForEach-Object { $_.text }) -join ' '
    if ($Batch.Dropped) { $text += (' ' + $Batch.Dropped + ' additional messages omitted. Review the game bridge log.') }
    return $text.Trim()
}
