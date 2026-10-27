#!/usr/bin/env bash
set -euo pipefail

echo "Refreshing the weather timer..."
skeinctl config restore-path systemd/user/skein-weather-check.timer

echo "Restarting weather checks..."
skeinctl service daemon-reload
skeinctl service restart skein-weather-check.timer
