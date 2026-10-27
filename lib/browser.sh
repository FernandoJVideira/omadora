# shellcheck shell=bash

skein_browser_cache_dir() {
  printf '%s\n' "${SKEIN_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/skein}"
}

skein_browser_desktop_dirs() {
  printf '%s\n' \
    "$HOME/.local/share/applications" \
    "$HOME/.local/share/flatpak/exports/share/applications" \
    "$HOME/.nix-profile/share/applications" \
    /usr/local/share/applications \
    /usr/share/applications \
    /var/lib/flatpak/exports/share/applications
}

skein_browser_desktop_mtime() {
  [[ -f "$1" ]] || return 1
  stat -c '%Y' "$1" 2>/dev/null
}

skein_browser_find_desktop_file() {
  local browser="$1"
  local dir path

  while IFS= read -r dir; do
    path="$dir/$browser"

    if [[ -f "$path" ]]; then
      printf '%s\n' "$path"
      return
    fi
  done < <(skein_browser_desktop_dirs)
}

skein_browser_desktop_exec() {
  sed -n 's/^Exec=//p' "$1" | head -n1
}

skein_browser_private_flag() {
  local browser="$1"

  case "${browser,,}" in
  *firefox* | *zen* | *librewolf* | *mullvad*)
    printf '%s\n' "--private-window"
    ;;
  *edge*)
    printf '%s\n' "--inprivate"
    ;;
  *)
    printf '%s\n' "--incognito"
    ;;
  esac
}

skein_browser_supports_app_mode() {
  local browser="$1"

  case "$browser" in
  google-chrome* | brave-browser* | microsoft-edge* | opera* | vivaldi* | helium*) return 0 ;;
  *) return 1 ;;
  esac
}

skein_browser_app_mode_browser() {
  local default_browser="$1"

  if skein_browser_supports_app_mode "$default_browser"; then
    printf '%s\n' "$default_browser"
  else
    printf '%s\n' "chromium-browser.desktop"
  fi
}

skein_browser_resolve() {
  local browser="$1"
  local cache_name="$2"
  local command_mode="${3:-default}"
  local cache_dir cache_file
  local cached_browser="" cached_desktop_file="" cached_desktop_mtime=""
  local cached_browser_command="" cached_private_flag=""
  local desktop_file desktop_mtime exec_line
  local -a exec_parts=()

  cache_dir="$(skein_browser_cache_dir)"
  cache_file="$cache_dir/$cache_name"

  if [[ -r "$cache_file" ]]; then
    # shellcheck source=/dev/null
    source "$cache_file"
  fi

  if [[ "$cached_browser" == "$browser" &&
    -n "$cached_desktop_file" &&
    -f "$cached_desktop_file" &&
    "$cached_desktop_mtime" == "$(skein_browser_desktop_mtime "$cached_desktop_file")" &&
    -n "$cached_browser_command" ]]; then
    SKEIN_BROWSER_COMMAND="$cached_browser_command"
    SKEIN_BROWSER_PRIVATE_FLAG="$cached_private_flag"
    return 0
  fi

  desktop_file="$(skein_browser_find_desktop_file "$browser")"
  [[ -n "$desktop_file" ]] || return 1

  exec_line="$(skein_browser_desktop_exec "$desktop_file")"
  [[ -n "$exec_line" ]] || return 1

  read -ra exec_parts <<<"$exec_line"

  if [[ "$command_mode" == "flatpak-app-id" ]]; then
    case "${exec_parts[0]}" in
    flatpak | */flatpak)
      SKEIN_BROWSER_COMMAND="${exec_parts[0]} run ${browser%.desktop}"
      ;;
    *)
      SKEIN_BROWSER_COMMAND="${exec_parts[0]}"
      ;;
    esac
  else
    SKEIN_BROWSER_COMMAND="${exec_parts[0]}"
  fi

  SKEIN_BROWSER_PRIVATE_FLAG="$(skein_browser_private_flag "$browser")"
  desktop_mtime="$(skein_browser_desktop_mtime "$desktop_file")"

  mkdir -p "$cache_dir"
  {
    printf 'cached_browser=%q\n' "$browser"
    printf 'cached_desktop_file=%q\n' "$desktop_file"
    printf 'cached_desktop_mtime=%q\n' "$desktop_mtime"
    printf 'cached_browser_command=%q\n' "$SKEIN_BROWSER_COMMAND"
    printf 'cached_private_flag=%q\n' "$SKEIN_BROWSER_PRIVATE_FLAG"
  } >"$cache_file"
}
