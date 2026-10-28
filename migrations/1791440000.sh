#!/usr/bin/env bash
set -euo pipefail

# Plasma Login Manager is no longer an option: remove the session filter it needed, the dnf action that
# re-ran it, and any Plasma login wallpaper settings of ours.
helper=/usr/local/libexec/skein-login-sessions
actions=/etc/dnf/libdnf5-plugins/actions.d/skein-sessions.actions

[[ -e $helper || -e $actions ]] || exit 0

echo "Remove the Plasma Login Manager session filter..."
sudo rm -f "$helper" "$actions"
