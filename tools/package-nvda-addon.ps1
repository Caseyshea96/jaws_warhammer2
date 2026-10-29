$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $root 'nvda-addon'
$artifacts = Join-Path $root 'artifacts'
$name = 'warhammer2-quiet-mode-0.1.0.nvda-addon'
$temporaryZip = Join-Path $artifacts 'warhammer2-quiet-mode-0.1.0.zip'
$output = Join-Path $artifacts $name

$expected = @(
    'manifest.ini',
    'appModules/warhammer2.py',
    'doc/en/readme.html'
) | Sort-Object
$actual = @(Get-ChildItem -LiteralPath $source -Recurse -File | ForEach-Object {
    $_.FullName.Substring($source.Length + 1).Replace('\', '/')
} | Sort-Object)
if ((Compare-Object $expected $actual).Count -ne 0) {
    throw 'NVDA add-on source differs from the expected minimal file list.'
}

$module = [IO.File]::ReadAllText((Join-Path $source 'appModules\warhammer2.py'))
if (-not $module.Contains('sleepMode = True')) { throw 'NVDA app module does not enable sleep mode.' }
foreach ($forbidden in @('script_', '_gestures', 'mouse', 'click', 'sendInput', 'winUser')) {
    if ($module.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "Forbidden input capability in NVDA app module: $forbidden"
    }
}

if (Test-Path -LiteralPath $temporaryZip) { Remove-Item -LiteralPath $temporaryZip }
if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output }
Compress-Archive -Path (Join-Path $source '*') -DestinationPath $temporaryZip -CompressionLevel Optimal
Move-Item -LiteralPath $temporaryZip -Destination $output

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($output)
try {
    $archiveFiles = @($archive.Entries | Where-Object { -not $_.FullName.EndsWith('/') } |
        ForEach-Object { $_.FullName.Replace('\', '/') } | Sort-Object)
    if ((Compare-Object $expected $archiveFiles).Count -ne 0) {
        throw 'NVDA add-on archive differs from the expected minimal file list.'
    }
} finally { $archive.Dispose() }

$hash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText(($output + '.sha256'), ($hash + '  ' + $name + [Environment]::NewLine), [Text.Encoding]::ASCII)
Write-Output $output
Write-Output $hash
