#!/usr/bin/env bash
set -euo pipefail

# Liquid Glass (Settings > Appearance, off by default) uses the HyprGlass plugin. Build it on machines that
# already have Skein. It needs a running Hyprland session; without one, the first-run step is skipped here.
sudo pacman -S --needed --noconfirm cmake meson cpio || true

if hyprctl version >/dev/null 2>&1; then
  skein-hyprglass install || echo "Could not build HyprGlass; Liquid Glass will only blur" >&2
else
  echo "No running Hyprland: run 'skein-hyprglass install' from inside the session to build HyprGlass" >&2
fi
