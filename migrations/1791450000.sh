#!/usr/bin/env bash
set -euo pipefail

# The dock now draws app icons from the WhiteSur pack. Install it on machines that already have Skein.
if skein-icon-pack install whitesur; then
  skein-icon-pack apply whitesur
else
  echo "Could not install the icon pack; the dock keeps using the system icons" >&2
fi
