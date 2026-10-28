#!/usr/bin/env bash
set -euo pipefail

# Your own wallpapers now live in ~/Pictures/Wallpapers/<theme>/ instead of ~/.config/skein/backgrounds/<theme>/.
old="$HOME/.config/skein/backgrounds"
new="$HOME/Pictures/Wallpapers"

[[ -d $old ]] || exit 0

echo "Move wallpapers to $new..."
mkdir -p "$new"
cp -an "$old"/. "$new"/
rm -rf "$old"
