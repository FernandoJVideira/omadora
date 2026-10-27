state_flag_validate() {
  [[ "$flag" =~ ^[A-Za-z0-9._-]+$ ]] || return 1
  [[ "$flag" != "." && "$flag" != ".." ]] || return 1
}

state_list() {
  [[ -d "$SKEIN_STATE_HOME" ]] || return 0

  find "$SKEIN_STATE_HOME" \
    -maxdepth 1 \
    -type f \
    -printf '%f\n' |
    sort
}

state_set() {
  local flag="${1:-}"

  state_flag_validate "$flag" || return 1

  ensure_dir "$SKEIN_STATE_HOME"
  touch -- "$SKEIN_STATE_HOME/$flag"
}

state_clear() {
  local flag="${1:-}"

  state_flag_validate "$flag" || return 1

  rm -f -- "$SKEIN_STATE_HOME/$flag"
}

state_exists() {
  local flag="${1:-}"

  [[ -f "$SKEIN_STATE_HOME/$flag" ]]
}

state_toggles_list() {
  [[ -d "$SKEIN_STATE_HOME" ]] || return 0

  find "$SKEIN_STATE_HOME/toggles" \
    -maxdepth 1 \
    -type f \
    -printf '%f\n' |
    sort
}

state_toggles_set() {
  local toggle="${1:-}"

  state_flag_validate "$toggle" || return 1

  ensure_dir "$SKEIN_STATE_HOME/toggles"
  touch -- "$SKEIN_STATE_HOME/toggles/$toggle"
}

state_toggles_clear() {
  local toggle="${1:-}"

  state_flag_validate "$toggle" || return 1

  rm -f -- "$SKEIN_STATE_HOME/toggles/$toggle"
}

state_toggles_exists() {
  local toggle="${1:-}"

  [[ -f "$SKEIN_STATE_HOME/toggles/$toggle" ]]
}
