#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ $(id -u) -eq 0 ]]; then
    printf 'Run this script as your normal Ubuntu user, with sudo access.\n' >&2
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    printf 'Cannot identify this Linux distribution.\n' >&2
    exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release
if [[ ${ID:-} != ubuntu || ${VERSION_ID:-} != 24.04 ]]; then
    printf 'This baseline currently supports Ubuntu 24.04; found %s %s.\n' "${ID:-unknown}" "${VERSION_ID:-unknown}" >&2
    exit 1
fi

sudo apt-get update
sudo apt-get install -y ca-certificates curl wget jq apt-transport-https software-properties-common

if ! dpkg-query -W -f='${Status}' packages-microsoft-prod 2>/dev/null | grep -qx 'install ok installed'; then
    repo_package=$(mktemp --suffix=.deb)
    trap 'rm -f -- "$repo_package"' EXIT
    curl -fsSL "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" -o "$repo_package"
    sudo dpkg -i "$repo_package"
fi

sudo apt-get update
# Pin DSC to the stable release: the repository also publishes preview builds.
sudo apt-get install -y dsc=3.3.0 powershell git gh make unzip python3 fzf zoxide

# The bundled Apt DSC resource emits an invalid JSON boolean for a missing
# package in DSC 3.3.0. APT provisions packages; DSC verifies them afterward.
# User tools, shells, and modules run through DSC as this user.
apply_config() {
    local output
    output=$("$@")
    if ! jq -e '.hadErrors == false' <<< "$output" > /dev/null; then
        printf '%s\n' "$output" >&2
        return 1
    fi
    jq -r '"Applied \(.results | length) DSC resources"' <<< "$output"
}

apply_config dsc --progress-format none config set --file "$repo_dir/tools.dsc.yaml" --output-format json
apply_config dsc --progress-format none config set --file "$repo_dir/shells.dsc.yaml" --output-format json

pwsh -NoProfile -File "$repo_dir/Test-WslDsc.ps1" -Quiet
