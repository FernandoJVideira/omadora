#!/usr/bin/env bash
set -euo pipefail

echo "Refreshing wofi style.css..."
skein-exec skein-refresh-wofi
