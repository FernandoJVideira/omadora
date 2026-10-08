#!/usr/bin/env bash
set -euo pipefail

# Default agent, crash diagnosis and the Defaults menu.
echo "Set up the default agent and crash diagnosis..."

units="$HOME/.config/systemd/user"

# Agent skills for the coding agents on this machine
"$OMADORA_PATH/libexec/omadora-agent-skills-link"

# Crash watcher
cp "$OMADORA_PATH/config/systemd/user/omadora-crash-watch.service" "$OMADORA_PATH/config/systemd/user/omadora-session.target" "$units/"
systemctl --user daemon-reload
systemctl --user start omadora-crash-watch.service || true

# Core dumps are only recorded when systemd-coredump is installed
if ! rpm -q systemd-coredump >/dev/null 2>&1; then
  sudo dnf install -y systemd-coredump || echo "Warning: install systemd-coredump to get crash notifications." >&2
fi
