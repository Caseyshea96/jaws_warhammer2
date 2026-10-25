#!/usr/bin/env bash
# Install the pinned official Linux build locally; interrupted downloads resume.
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tool_root="$project_root/local/tools"
version=4.5.4
archive="$tool_root/rpfm-$version.tar.zst"
destination="$tool_root/rpfm-$version"
url="https://github.com/Frodo45127/rpfm/releases/download/v$version/rpfm-v$version-x86_64-unknown-linux-gnu.tar.zst"
expected=0bc4b6535b5d2852ab925a552d7bb53c7ec9de4293b00ead9a80a85701642df6
mkdir -p "$tool_root"
if [[ -f "$destination/.verified-release" ]]; then
    printf 'RPFM already extracted at %s\n' "$destination"
    exit 0
fi
if [[ ! -f "$archive" ]] || ! printf '%s  %s\n' "$expected" "$archive" | sha256sum --check --status; then
    curl --fail --location --continue-at - --retry 3 "$url" --output "$archive"
fi
printf '%s  %s\n' "$expected" "$archive" | sha256sum --check
mkdir -p "$destination"
tar --zstd --extract --file "$archive" --directory "$destination" --no-same-owner
printf '%s\n' "$expected" > "$destination/.verified-release"
printf 'Verified and extracted RPFM to %s\n' "$destination"
printf 'Inspect the included README and binaries before configuring the game.\n'
