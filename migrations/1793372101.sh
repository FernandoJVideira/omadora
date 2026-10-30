#!/usr/bin/env bash
set -uo pipefail

# The COPR's hyprland-devel needs glaze-static, which only the COPR's glaze-devel provides. Terra ships a newer
# glaze-devel that conflicts with it and blocks Nobara's updater, so hold the COPR build.
if [[ "$(. /etc/os-release && echo "${ID:-}")" == "nobara" ]]; then
  (
    if rpm -q glaze-devel >/dev/null 2>&1; then
      locks=$(dnf5 versionlock list 2>/dev/null) || exit 1
      grep -q 'glaze-devel' <<<"$locks" && exit 0
      origin=$(dnf5 repoquery --installed glaze-devel --qf '%{from_repo}\n' 2>/dev/null | head -n1)
      if [[ "$origin" == *lionheartp* || "$origin" == *Hyprland* ]] ||
        { [[ -z "$origin" || "$origin" == "@System" || "$origin" == "<unknown>" ]] && rpm -q hyprland-devel >/dev/null 2>&1; }; then
        sudo dnf5 versionlock add glaze-devel
      fi
    fi
  ) || echo "Could not lock glaze-devel; if 'nobara-sync' reports a glaze-devel conflict, run 'sudo dnf5 versionlock add glaze-devel'" >&2
fi

exit 0
