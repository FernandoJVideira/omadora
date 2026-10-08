#!/usr/bin/env bash
set -euo pipefail

# Waybar is gone: the Quickshell bar is the only top bar.
echo "Remove Waybar..."

systemctl --user disable --now waybar.service 2>/dev/null || true
rm -rf "$HOME/.config/systemd/user/waybar.service.d" "$HOME/.config/waybar"
rm -f "$HOME/.local/state/omadora/toggles/bar-waybar" "$HOME/.local/state/omadora/toggles/waybar-off"
systemctl --user daemon-reload

# The session target no longer wants waybar.service
cp "$OMADORA_PATH/config/systemd/user/omadora-session.target" "$HOME/.config/systemd/user/"
systemctl --user daemon-reload

# Reload the user's keybindings (Toggle top bar now uses "omactl ui toggle bar")
hyprctl reload >/dev/null 2>&1 || true
