$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'companion/Protocol.ps1')
function Assert($ok,$msg) { if (-not $ok) { throw $msg } }
function Record($kind,$text) { return [pscustomobject]@{ kind=$kind; text=$text } }
$b=New-SpeechBatch
Add-SpeechRecord $b (Record 'focus' 'First item.')
Add-SpeechRecord $b (Record 'focus' 'Second item.')
Add-SpeechRecord $b (Record 'error' 'Control changed.')
Add-SpeechRecord $b (Record 'focus' 'Third item.')
Add-SpeechRecord $b (Record 'result' 'Input sent.')
Add-SpeechRecord $b (Record 'hover' 'Background hover.')
Assert ((Get-SpeechBatchText $b) -eq 'Second item. Control changed. Third item. Input sent.') 'Focus coalescing lost or reordered primary records'
$b=New-SpeechBatch
1..20 | ForEach-Object { Add-SpeechRecord $b (Record 'error' "Error $_.") }
Assert ($b.Items.Count -eq 16 -and $b.Dropped -eq 4) 'Record budget exceeded'
Assert ((Get-SpeechBatchText $b).Contains('4 additional messages omitted')) 'Overflow was silent'
$b=New-SpeechBatch
Add-SpeechRecord $b (Record 'speech' ('x' * 7900))
Add-SpeechRecord $b (Record 'result' ('y' * 200))
Assert ($b.Characters -eq 7900 -and $b.Dropped -eq 1) 'Character budget exceeded'
$b=New-SpeechBatch
Add-SpeechRecord $b (Record 'focus' ('x' * 7000))
Add-SpeechRecord $b (Record 'focus' 'Short.')
Assert ($b.Characters -eq 6 -and $b.Items.Count -eq 1) 'Replacement did not reclaim character budget'
foreach ($kind in @('focus','result')) {
    $state=New-ProtocolState
    $line=@{version=1;session='test';sequence=1;context='frontend';kind=$kind;text='test'} | ConvertTo-Json -Compress
    Assert ($null -ne (Convert-BridgeRecord $line $state)) "Parser rejected $kind"
}
Write-Output 'PASS: navigation coalescing, error/result ordering, hover exclusion, explicit bounded overflow, protocol kinds'
