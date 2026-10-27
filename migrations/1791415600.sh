#!/usr/bin/env bash
set -euo pipefail

# The Quickshell shell now also runs the launcher/menus, notifications, OSD and
# lock screen, replacing Wofi, Mako and Hyprlock.
echo "Move launcher, notifications, OSD and lock screen to Quickshell..."

units="$HOME/.config/systemd/user"

# Shell config (including the lock screen's PAM stack)
mkdir -p "$HOME/.config/quickshell"
cp -r "$SKEIN_PATH/config/quickshell/skein" "$HOME/.config/quickshell/"

# Units: the bar unit now runs the whole shell, and Mako/Hyprlock are gone
cp "$SKEIN_PATH/config/systemd/user/skein-bar.service" "$SKEIN_PATH/config/systemd/user/skein-session.target" "$units/"
systemctl --quiet --user stop mako.service 2>/dev/null || true
rm -f "$units/skein-hyprlock.service"
rm -rf "$units/mako.service.d"
systemctl --user daemon-reload

# Idle: check the new lock screen instead of Hyprlock
"$SKEIN_PATH/libexec/skein-refresh-hypridle" >/dev/null

# Drop the old app configs
rm -rf "$HOME/.config/mako" "$HOME/.config/wofi"
rm -f "$HOME/.config/hypr/hyprlock.conf"

# Re-render the theme so the shell gets the accent color
current_theme="$("$SKEIN_PATH/libexec/skein-theme-current" 2>/dev/null || true)"
"$SKEIN_PATH/libexec/skein-theme-set" "${current_theme:-Rose Pine Darker}" ||
  echo "Warning: failed to reapply the theme." >&2

systemctl --user restart skein-bar.service

# Remove the replaced apps
removable=()
for package in wofi mako hyprlock; do
  rpm -q "$package" >/dev/null 2>&1 && removable+=("$package")
done

if ((${#removable[@]} > 0)); then
  sudo dnf remove -y "${removable[@]}" || echo "Warning: could not remove ${removable[*]}; remove them manually." >&2
fi
