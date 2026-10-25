# Compile the shipped C# against Microsoft's .NET Framework 4.8 reference assemblies.
# This checks Windows PowerShell-era API compatibility, not user32 runtime behavior.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$referenceFolder = Join-Path $root 'local/tools/net48-reference'
$refs = [Microsoft.CodeAnalysis.MetadataReference[]]@(
    foreach ($name in @('mscorlib.dll','System.dll','System.Core.dll','System.Windows.Forms.dll','System.Drawing.dll')) {
        [Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile((Join-Path $referenceFolder $name))
    }
)
$parse = [Microsoft.CodeAnalysis.CSharp.CSharpParseOptions]::Default.WithLanguageVersion([Microsoft.CodeAnalysis.CSharp.LanguageVersion]::CSharp5)
$trees = [Microsoft.CodeAnalysis.SyntaxTree[]]@(
    foreach ($name in @('Bridge.cs','Native.cs','HotkeyPolicy.cs')) {
        [Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText([IO.File]::ReadAllText((Join-Path $root ('companion/' + $name))), $parse)
    }
)
$options = [Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions]::new([Microsoft.CodeAnalysis.OutputKind]::DynamicallyLinkedLibrary)
$compilation = [Microsoft.CodeAnalysis.CSharp.CSharpCompilation]::Create('JawsPilotWindowsCheck',$trees,$refs,$options)
$stream = [IO.MemoryStream]::new()
try {
    $result = $compilation.Emit($stream)
    if (-not $result.Success) { $result.Diagnostics | ForEach-Object { Write-Output $_.ToString() }; throw 'Windows framework compilation failed' }
    Write-Output 'PASS: Bridge.cs and Native.cs compile as C# 5 against .NET Framework 4.8 (including WinForms)'
} finally { $stream.Dispose() }
