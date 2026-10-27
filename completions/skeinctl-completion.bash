SKEIN_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." &&
    pwd
)"

_skeinctl_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]:-}"
  local prev_count=0
  local line option
  local -a results=()

  if ((COMP_CWORD > 1)); then
    prev_count=$((COMP_CWORD - 1))
  fi

  COMPREPLY=()

  mapfile -t results < <(
    "$SKEIN_ROOT/bin/skeinctl" __complete "$cur" "${COMP_WORDS[@]:1:prev_count}" 2>/dev/null
  )

  for line in "${results[@]}"; do
    if [[ "$line" == __skeinctl_compopt:* ]]; then
      option="${line#__skeinctl_compopt:}"
      [[ -n "$option" ]] && compopt -o "$option" 2>/dev/null || true
      continue
    fi

    COMPREPLY+=("$line")
  done
}

complete -F _skeinctl_completion skeinctl
