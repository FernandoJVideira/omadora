#!/usr/bin/env bash
set -euo pipefail

echo "Migrate default Flatpaks to system installation"

export SKEIN_PATH="${SKEIN_PATH:-$HOME/.local/share/skein}"
export SKEIN_INSTALL="${SKEIN_INSTALL:-$SKEIN_PATH/install}"

default_flatpaks=(
  com.dec05eba.gpu_screen_recorder
  org.localsend.localsend_app
)

for app_id in "${default_flatpaks[@]}"; do
  if flatpak info --user "$app_id" >/dev/null 2>&1; then
    flatpak uninstall --user --noninteractive -y "$app_id"
  fi
done

if flatpak remotes --user --columns=name 2>/dev/null | grep -Fxq flathub; then
  flatpak remote-delete --user --force flathub
fi

source "$SKEIN_INSTALL/packaging/flatpak.sh"
