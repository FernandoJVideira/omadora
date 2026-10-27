# shellcheck shell=bash

if [[ -z "${SKEIN_ROOT:-}" ]]; then
  printf 'error: SKEIN_ROOT must be set before sourcing paths.sh\n' >&2
  return 1
fi

readonly SKEIN_LIB_DIR="$SKEIN_ROOT/lib"
readonly SKEIN_LIBEXEC_DIR="$SKEIN_ROOT/libexec"
readonly SKEIN_THEMES_DIR="$SKEIN_ROOT/themes"
readonly SKEIN_DEFAULTS_DIR="$SKEIN_ROOT/defaults"
readonly SKEIN_MIGRATIONS_DIR="$SKEIN_ROOT/migrations"

readonly SKEIN_DATA_HOME="${SKEIN_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/skein}"
readonly SKEIN_CONFIG_HOME="${SKEIN_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/skein}"
readonly SKEIN_CONFIG_FILE="${SKEIN_CONFIG_HOME}/config.json"
readonly SKEIN_STATE_HOME="${SKEIN_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/skein}"
readonly SKEIN_CACHE_HOME="${SKEIN_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/skein}"

if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
  readonly SKEIN_RUNTIME_DIR="${SKEIN_RUNTIME_DIR:-$XDG_RUNTIME_DIR/skein}"
fi
