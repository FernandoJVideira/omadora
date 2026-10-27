SKEIN_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." &&
    pwd
)"

_skein_exec_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]:-}"

  COMPREPLY=()

  if ((COMP_CWORD == 1)); then
    mapfile -t COMPREPLY < <("$SKEIN_ROOT/bin/skein-exec" __complete "$cur" 2>/dev/null)
  fi
}

complete -F _skein_exec_completion skein-exec
