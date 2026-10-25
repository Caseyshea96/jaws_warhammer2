#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
source_file="mod/script/_lib/mod/jaws_access.lua"
output_name="jaws_access"
if [[ "${1:-}" == "--diagnostic" ]]; then
    source_file="diagnostics/jaws_access.lua"
    output_name="jaws_access_diagnostic"
    local/tools/lua-5.1.5/src/lua tests/diagnostic_harness.lua
else
    python3 tests/check_access.py
fi
local/tools/lua-5.1.5/src/luac -p "$source_file"
mkdir -p artifacts
build_dir="$(mktemp -d "$project_root/artifacts/pilot-build.XXXXXX")"
trap 'rm -rf -- "$build_dir"' EXIT
pack="$build_dir/jaws_access.pack"
bash tools/rpfm.sh pack create -p "$pack"
bash tools/rpfm.sh pack set-file-type -p "$pack" -f mod
bash tools/rpfm.sh pack add -p "$pack" -f "$project_root/$source_file;script/_lib/mod/jaws_access.lua"
bash tools/rpfm.sh pack extract -p "$pack" -F "/;$build_dir/roundtrip"
cmp "$source_file" "$build_dir/roundtrip/script/_lib/mod/jaws_access.lua"
cp "$pack" "artifacts/$output_name.pack"
sha256sum "artifacts/$output_name.pack" > "artifacts/$output_name.pack.sha256"
printf 'Pilot pack built and round-trip verified.\n'
