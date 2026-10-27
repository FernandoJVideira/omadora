#!/usr/bin/env bash
set -euo pipefail

# Default agent, crash diagnosis and the Defaults menu.
echo "Set up the default agent and crash diagnosis..."

units="$HOME/.config/systemd/user"

# Agent skills for the coding agents on this machine
"$SKEIN_PATH/libexec/skein-agent-skills-link"

# Crash watcher
cp "$SKEIN_PATH/config/systemd/user/skein-crash-watch.service" "$SKEIN_PATH/config/systemd/user/skein-session.target" "$units/"
systemctl --user daemon-reload
systemctl --user start skein-crash-watch.service || true

# Core dumps are only recorded when systemd-coredump is installed
if ! rpm -q systemd-coredump >/dev/null 2>&1; then
  sudo dnf install -y systemd-coredump || echo "Warning: install systemd-coredump to get crash notifications." >&2
fi
