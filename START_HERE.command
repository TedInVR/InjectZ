#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
[[ "$(uname -s)" == Darwin ]] || { echo 'This setup requires macOS.'; exit 1; }
exec /bin/bash "$repo/Setup/GuidedSetup.sh" "$repo"
