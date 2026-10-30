#!/usr/bin/env bash
set -uo pipefail

# The monitor recovery watcher needs socat, which older installs never got; without it the unit used to restart in a loop.
if [[ "$(. /etc/os-release && echo "${ID:-}")" == "nobara" ]] && ! command -v socat >/dev/null 2>&1; then
  sudo dnf5 install -y socat || echo "Could not install socat; run 'sudo dnf install socat'" >&2
fi

exit 0
