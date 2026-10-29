param([string]$ClientPath=(Join-Path $PSScriptRoot '..\companion\Automation.ps1'))
$ErrorActionPreference='Stop'
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Resolve-Path -LiteralPath $ClientPath).Path,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw 'Automation client has syntax errors.' }
$definition=$ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Write-Atomic'},$true)
if (-not $definition) { throw 'Atomic writer function missing.' }
. ([scriptblock]::Create($definition.Extent.Text))
$taskTempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$BasePath=Join-Path $taskTempRoot ('wh2-atomic-test-' + [guid]::NewGuid().ToString('N'))
$resolvedTaskPath=[IO.Path]::GetFullPath($BasePath)
if (-not $resolvedTaskPath.StartsWith($taskTempRoot,[StringComparison]::OrdinalIgnoreCase)) { throw 'Temporary test path escaped its root.' }
[void][IO.Directory]::CreateDirectory($BasePath)
$encoding=New-Object Text.UTF8Encoding($false,$true)
try {
    $path=Join-Path $BasePath 'request.tsv'
    Write-Atomic $path "first`n"
    Write-Atomic $path "second`n"
    if ([IO.File]::ReadAllText($path) -ne "second`n") { throw 'Existing request was not atomically replaced.' }
    if (@(Get-ChildItem -LiteralPath $BasePath -File).Count -ne 1) { throw 'Temporary writer payload was left behind.' }
    Write-Output ('PASS: atomic create and existing-request replacement on PowerShell ' + $PSVersionTable.PSVersion)
} finally {
    $checkedPath=[IO.Path]::GetFullPath($BasePath)
    if ($checkedPath -ne $resolvedTaskPath -or -not $checkedPath.StartsWith($taskTempRoot,[StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing cleanup outside the verified temporary fixture.' }
    Remove-Item -LiteralPath $checkedPath -Recurse -Force
}
