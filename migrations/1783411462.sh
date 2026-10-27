#!/usr/bin/env bash
set -euo pipefail

echo "Update web app desktop launchers to run through skein-exec"

desktop_dir="$HOME/.local/share/applications"

if [[ ! -d $desktop_dir ]]; then
  exit 0
fi

while IFS= read -r -d '' desktop_file; do
  if grep -q '^Exec=\(skein-launch-webapp\|skein-webapp-handler\)\([[:space:]]\|$\)' "$desktop_file"; then
    sed -i 's/^Exec=\(skein-launch-webapp\|skein-webapp-handler\)\([[:space:]]\|$\)/Exec=skein-exec \1\2/' "$desktop_file"
    echo "Updated $desktop_file"
  fi
done < <(find "$desktop_dir" -maxdepth 1 -type f -name '*.desktop' -print0)
