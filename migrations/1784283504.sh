#!/usr/bin/env bash
set -euo pipefail

echo "Refreshing the weather timer..."
omactl config restore-path systemd/user/omadora-weather-check.timer

echo "Restarting weather checks..."
omactl service daemon-reload
omactl service restart omadora-weather-check.timer
