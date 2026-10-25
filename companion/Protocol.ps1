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
            $r.kind -notin @('speech','hello','context','error','hover')) { throw 'Invalid envelope' }
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
