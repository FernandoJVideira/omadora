#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define paths
export SKEIN_PATH="$HOME/.local/share/skein"
export SKEIN_INSTALL="$SKEIN_PATH/install"
export PATH="$SKEIN_PATH/bin:$PATH"

# Detect Nobara (Fedora-based, ships its own desktop, drivers and repos)
# shellcheck source=/dev/null
source /etc/os-release
if [[ "${ID:-}" == "nobara" ]]; then
  export SKEIN_NOBARA=true
fi

install_log="$HOME/skein-install.log"
exec > >(tee -a "$install_log") 2>&1
echo "Logging install output to: $install_log"

# Install
source "$SKEIN_INSTALL/preflight/all.sh"
source "$SKEIN_INSTALL/packaging/all.sh"
source "$SKEIN_INSTALL/config/all.sh"
source "$SKEIN_INSTALL/login/all.sh"
source "$SKEIN_INSTALL/post-install/all.sh"
