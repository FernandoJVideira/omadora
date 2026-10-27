#!/usr/bin/env bash
set -euo pipefail

# The Skein login session used to launch the hidden hyprland.desktop entry,
# which uwsm refuses to start. Reinstall the fixed helper and regenerate it.
[[ -x /usr/local/libexec/skein-login-sessions ]] || exit 0

echo "Fix the Skein login session..."

sudo install -Dm755 "$SKEIN_PATH/libexec/skein-login-sessions" /usr/local/libexec/skein-login-sessions
sudo /usr/local/libexec/skein-login-sessions
