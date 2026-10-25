#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$project_root/local/pwsh-cache" "$project_root/local/pwsh-config" "$project_root/local/pwsh-data"
export XDG_CACHE_HOME="$project_root/local/pwsh-cache"
export XDG_CONFIG_HOME="$project_root/local/pwsh-config"
export XDG_DATA_HOME="$project_root/local/pwsh-data"
export POWERSHELL_TELEMETRY_OPTOUT=1
exec "$project_root/local/tools/powershell/pwsh" -NoProfile "$@"
