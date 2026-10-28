readonly SKEIN_USER_THEMES_DIR="${SKEIN_CONFIG_HOME}/themes"
readonly SKEIN_CURRENT_THEME_DIR="${SKEIN_CONFIG_HOME}/current/theme"
readonly SKEIN_NEXT_THEME_DIR="${SKEIN_CONFIG_HOME}/current/next-theme"
readonly SKEIN_THEME_NAME_FILE="${SKEIN_CONFIG_HOME}/current/theme.name"
readonly SKEIN_THEME_LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/skein-theme-set.lock"
readonly SKEIN_USER_BACKGROUNDS_DIR="${SKEIN_BACKGROUNDS_DIR:-${HOME}/Pictures/Wallpapers}"
readonly SKEIN_CURRENT_BACKGROUND_LINK="${SKEIN_CONFIG_HOME}/current/background"

theme_name_normalize() {
  echo "$1" |
    sed -E 's/<[^>]+>//g' |
    tr '[:upper:]' '[:lower:]' |
    tr ' ' '-'
}

theme_name_is_safe() {
  local theme_name="$1"

  [[ -n $theme_name && $theme_name != .* && $theme_name != */* ]]
}

theme_exists() {
  local theme="$1"

  theme_list_all | grep -qxF -- "$theme"
}

theme_current() {
  [[ -s "$SKEIN_THEME_NAME_FILE" ]] || return 1
  head -n 1 -- "$SKEIN_THEME_NAME_FILE"
}

theme_list_user() {
  [[ -d "$SKEIN_USER_THEMES_DIR" ]] || return 0

  find "$SKEIN_USER_THEMES_DIR" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -printf '%f\n' |
    sort
}

theme_list_system() {
  [[ -d "$SKEIN_THEMES_DIR" ]] || return 0

  find "$SKEIN_THEMES_DIR" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -printf '%f\n' |
    sort
}

theme_list_all() {
  {
    theme_list_user || return 1
    theme_list_system || return 1
  } | sort -u
}

theme_list_backgrounds() {
  local theme_name="$1"

  local backgrounds_dir="${SKEIN_USER_BACKGROUNDS_DIR}/${theme_name}"

  [[ -d "$backgrounds_dir" ]] || return 0

  find "$backgrounds_dir" \
    -maxdepth 1 \
    -type f \
    -printf '%f\n' |
    sort
}

theme_set_gnome() {
  command -v gsettings >/dev/null 2>&1 || return 1

  local colors_file="${SKEIN_CURRENT_THEME_DIR}/colors.toml"
  local icons_file="${SKEIN_CURRENT_THEME_DIR}/icons.theme"
  local mode

  local gtk_theme="adw-gtk3-dark"
  local icon_theme="Yaru-blue"
  local color_scheme="prefer-dark"

  mode="$("$SKEIN_LIBEXEC_DIR/skein-theme-color" --file "$colors_file" mode)" || return 1

  if [[ $mode == "light" ]]; then
    color_scheme="prefer-light"
    gtk_theme="adw-gtk3"
  fi

  if [[ -f "$icons_file" ]]; then
    icon_theme="$(<"$icons_file")"
  fi

  gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
  gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
  gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
}

# How the wallpaper fills the screen: cover (fill), contain (fit), fill (stretch) or tile
theme_background_fit() {
  local fit
  fit="$(cat "${SKEIN_CONFIG_HOME}/wallpaper-fit" 2>/dev/null || true)"
  case "$fit" in
  cover | contain | fill | tile) echo "$fit" ;;
  *) echo cover ;;
  esac
}

theme_apply_background() {
  hyprctl hyprpaper wallpaper ,"$SKEIN_CURRENT_BACKGROUND_LINK","$(theme_background_fit)"
}
