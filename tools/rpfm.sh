#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
binary="$project_root/local/tools/rpfm-4.5.4/usr/bin/rpfm_cli"
if [[ ! -x "$binary" ]]; then
    printf 'Run bash tools/setup-rpfm.sh first.\n' >&2
    exit 1
fi
mkdir -p "$project_root/local/rpfm-config"
export XDG_CONFIG_HOME="$project_root/local/rpfm-config"
exec "$binary" --game warhammer_2 "$@"
