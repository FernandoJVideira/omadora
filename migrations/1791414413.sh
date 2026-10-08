#!/usr/bin/env bash
set -euo pipefail

# The Omadora login session used to launch the hidden hyprland.desktop entry,
# which uwsm refuses to start. Reinstall the fixed helper and regenerate it.
[[ -x /usr/local/libexec/omadora-login-sessions ]] || exit 0

echo "Fix the Omadora login session..."

sudo install -Dm755 "$OMADORA_PATH/libexec/omadora-login-sessions" /usr/local/libexec/omadora-login-sessions
sudo /usr/local/libexec/omadora-login-sessions
