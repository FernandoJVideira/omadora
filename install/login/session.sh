# Log in through greetd with the Quickshell greeter (skein-greeter; its colors and logo follow the
# active Skein theme). SDDM stays installed but disabled, so it can be switched back with
# `skein-greeter rollback`. Hyprland's (uwsm) session is launched by the greeter itself. Enabled
# here, started on the next boot.
# Set SKEIN_KEEP_LOGIN_MANAGER=1 to keep SDDM with the Skein login theme instead (colors and
# wallpaper follow the active Skein theme; re-sync with `skeinctl theme login sync`).
if [[ -n "${SKEIN_KEEP_LOGIN_MANAGER:-}" ]] && ! systemctl is-enabled --quiet greetd.service 2>/dev/null; then
  sudo pacman -S --needed --noconfirm sddm qt6-svg qt6-declarative
  sudo systemctl enable --force sddm.service
  "$SKEIN_PATH/libexec/skein-sddm-theme" set skein
else
  "$SKEIN_PATH/libexec/skein-greeter" install ||
    echo "WARNING: the greeter didn't install; run skein-greeter install by hand."
fi
