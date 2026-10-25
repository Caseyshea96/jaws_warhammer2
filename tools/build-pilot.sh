#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
local/tools/lua-5.1.5/src/luac -p mod/script/_lib/mod/jaws_access.lua
python3 tests/check_access.py
mkdir -p artifacts
build_dir="$(mktemp -d "$project_root/artifacts/pilot-build.XXXXXX")"
trap 'rm -rf -- "$build_dir"' EXIT
pack="$build_dir/jaws_access.pack"
bash tools/rpfm.sh pack create -p "$pack"
bash tools/rpfm.sh pack set-file-type -p "$pack" -f mod
bash tools/rpfm.sh pack add -p "$pack" -f "$project_root/mod/script/_lib/mod/jaws_access.lua;script/_lib/mod/jaws_access.lua"
bash tools/rpfm.sh pack extract -p "$pack" -F "/;$build_dir/roundtrip"
cmp mod/script/_lib/mod/jaws_access.lua "$build_dir/roundtrip/script/_lib/mod/jaws_access.lua"
cp "$pack" artifacts/jaws_access.pack
sha256sum artifacts/jaws_access.pack > artifacts/jaws_access.pack.sha256
printf 'Pilot pack built and round-trip verified.\n'
