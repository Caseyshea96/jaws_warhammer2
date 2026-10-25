#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
mkdir -p artifacts
build_dir="$(mktemp -d "$project_root/artifacts/probe-build.XXXXXX")"
trap 'rm -rf -- "$build_dir"' EXIT
pack="$build_dir/jaws_probe.pack"
bash tools/rpfm.sh pack create -p "$pack"
bash tools/rpfm.sh pack set-file-type -p "$pack" -f mod
bash tools/rpfm.sh pack add -p "$pack" -f "$project_root/mod/script/_lib/mod/jaws_probe.lua;script/_lib/mod/jaws_probe.lua"
bash tools/rpfm.sh pack extract -p "$pack" -F "/;$build_dir/roundtrip"
cmp mod/script/_lib/mod/jaws_probe.lua "$build_dir/roundtrip/script/_lib/mod/jaws_probe.lua"
cp "$pack" artifacts/jaws_probe.pack
sha256sum artifacts/jaws_probe.pack > artifacts/jaws_probe.pack.sha256
printf 'Built and round-trip verified artifacts/jaws_probe.pack\n'
