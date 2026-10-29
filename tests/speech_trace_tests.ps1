$ErrorActionPreference = 'Stop'
$path = Join-Path (Split-Path $PSScriptRoot -Parent) 'companion/Companion.ps1'
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors -join "`n") }
$fn = $ast.Find({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Write-SpeechTrace'}, $true)
. ([scriptblock]::Create($fn.Extent.Text))
$temp = Join-Path ([IO.Path]::GetTempPath()) ('wh2-speech-trace-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temp)
$speechTrace = Join-Path $temp 'trace.jsonl'
$script:SpeechRequestId = 42L
try {
    $TraceSpeech = $false
    Write-SpeechTrace 'request' @{text='New Campaign'}
    if (Test-Path $speechTrace) { throw 'Trace wrote while disabled' }
    $TraceSpeech = $true
    Write-SpeechTrace 'request' @{text='Controls, 1 of 22: New Campaign'; characters=31}
    Write-SpeechTrace 'nvda-return' @{code=0}
    $records = @(Get-Content $speechTrace | ForEach-Object { $_ | ConvertFrom-Json })
    if ($records.Count -ne 2 -or $records[0].request_id -ne 42 -or $records[1].details.code -ne 0) { throw 'Trace correlation failed' }
    if ($records[0].details.text -ne 'Controls, 1 of 22: New Campaign' -or -not $records[0].time_utc) { throw 'Trace lost text or time' }
    $speechTrace = Join-Path $temp 'absent/trace.jsonl'
    Write-SpeechTrace 'stop-request' @{} # Missing parent must not interrupt the caller.
    'PASS: optional speech trace, request correlation, full text, timestamps, and I/O isolation'
} finally {
    Remove-Item -LiteralPath (Join-Path $temp 'trace.jsonl') -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $temp
}
