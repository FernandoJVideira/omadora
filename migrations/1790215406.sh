#!/usr/bin/env bash
set -euo pipefail

current_theme="$("$SKEIN_PATH/libexec/skein-theme-current" 2>/dev/null || true)"

if [[ -n $current_theme ]] &&
  "$SKEIN_PATH/libexec/skein-theme-list" | grep -qxF "$current_theme" &&
  "$SKEIN_PATH/libexec/skein-theme-set" "$current_theme"; then
  echo "Reapplied current theme: $current_theme"
else
  if [[ -n $current_theme ]]; then
    echo "Warning: failed to reapply current theme '$current_theme'. Falling back to Rose Pine Darker." >&2
  fi

  "$SKEIN_PATH/libexec/skein-theme-set" "Rose Pine Darker" ||
    echo "Warning: failed to apply fallback theme 'Rose Pine Darker'." >&2
fi
