$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Add-Type -Path (Join-Path $root 'companion/HotkeyPolicy.cs')
$script:registered = New-Object 'System.Collections.Generic.HashSet[int]'
$script:attempts = 0
$script:failRegister = $true
$script:failRelease = $false
$register = [Func[int,int,bool]] { param($id,$key)
    $script:attempts++
    if ($id -eq 2 -and $script:failRegister) { return $false }
    return $script:registered.Add($id)
}
$unregister = [Func[int,bool]] { param($id)
    if ($script:failRelease) { return $false }
    return $script:registered.Remove($id)
}
function Assert($ok,$msg) { if (-not $ok) { throw $msg } }
$p = [JawsPilot.HotkeyPolicy]::new($register,$unregister)
$p.Add(1,37); $p.Add(2,38)
Assert ($script:registered.Count -eq 0) 'Configuration reserved global keys'
[void]$p.SetActive($false)
Assert ($script:attempts -eq 0) 'Background registered keys'
$f = $p.SetActive($true)
Assert ($f.Count -eq 1 -and $f[0] -eq 2) 'Conflict not reported'
Assert ($p.CanDispatch(1) -and -not $p.CanDispatch(2)) 'Unowned key dispatched'
[void]$p.SetActive($true)
Assert ($script:attempts -eq 2) 'Repeated focus caused registration churn'
$script:failRelease=$true
$f=$p.SetActive($false)
Assert ($f.Count -eq 1 -and -not $p.CanDispatch(1)) 'Failed release allowed stale dispatch'
$script:failRelease=$false
[void]$p.SetActive($false)
Assert ($script:registered.Count -eq 0) 'Release retry did not free keys'
$script:failRegister=$false
[void]$p.SetActive($true)
Assert ($script:registered.Count -eq 2) 'Focus re-entry did not retry conflict'
$p.Dispose()
Assert ($script:registered.Count -eq 0 -and -not $p.CanDispatch(1)) 'Dispose left keys active'
[void]$p.SetActive($true)
Assert ($script:registered.Count -eq 0) 'Disposed policy reactivated'
Write-Output 'PASS: foreground transitions, conflicts, release retries, stale dispatch, no registration churn, disposal'
