#!/usr/bin/env bash
set -euo pipefail

# The Claude Code status line still pointed at the old omadora-claude-statusline, which was renamed,
# so the agents panel stopped receiving rate limits. Point it at skein-claude-statusline.
settings="$HOME/.claude/settings.json"
store="${XDG_CONFIG_HOME:-$HOME/.config}/skein/agents.json"

rewrite() { # <file> <jq path>
  local file="$1" path="$2"
  [[ -f $file ]] || return 0
  jq -e "($path // \"\") | test(\"omadora\")" "$file" >/dev/null 2>&1 || return 0
  echo "Fix the Claude Code status line in $file..."
  cp "$file" "$file.skein-backup"
  jq "$path |= gsub(\"omadora\"; \"skein\")" "$file" >"$file.tmp" && mv "$file.tmp" "$file"
}

rewrite "$settings" .statusLine.command
rewrite "$store" .claudeStatusline
