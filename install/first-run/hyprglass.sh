#!/bin/bash

# Build the HyprGlass plugin behind Liquid Glass (Settings > Appearance). It needs a running Hyprland, so it
# cannot happen at install time. Glass stays off until you switch it on; a failed build is not fatal.

"$SKEIN_PATH/libexec/skein-hyprglass" install || echo "Could not build HyprGlass; Liquid Glass will only blur" >&2
