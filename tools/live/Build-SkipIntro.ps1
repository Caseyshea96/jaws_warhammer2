# Build work/skip-intro/jaws_skip_intro.pack: three empty files named like the
# game's startup movies, so the game skips them. Test launches only; the game
# folder and TW Mod Manager's profile are never touched.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rpfm = Join-Path $repo 'local\tools\rpfm-4.5.4-windows\rpfm_cli.exe'
$dir = Join-Path $repo 'work\skip-intro'
$src = Join-Path $dir 'src'
[void][IO.Directory]::CreateDirectory($src)
$pack = Join-Path $dir 'jaws_skip_intro.pack'
if (Test-Path -LiteralPath $pack) { Remove-Item -LiteralPath $pack }
& $rpfm --game warhammer_2 pack create -p $pack 2>$null
& $rpfm --game warhammer_2 pack set-file-type -p $pack -f mod 2>$null
foreach ($n in 1..3) {
    $file = Join-Path $src "startup_movie_0$n.ca_vp8"
    [IO.File]::WriteAllBytes($file, [byte[]]@())
    & $rpfm --game warhammer_2 pack add -p $pack -f ($file + ';movies/startup_movie_0' + $n + '.ca_vp8') 2>$null
    if ($LASTEXITCODE) { throw "Adding startup_movie_0$n failed." }
}
$listed = @(& $rpfm --game warhammer_2 pack list -p $pack 2>$null | Where-Object { $_ -like 'movies/startup_movie_0*' })
if ($listed.Count -ne 3) { throw "Expected 3 movie entries, found $($listed.Count)." }
"BUILT=$pack"
