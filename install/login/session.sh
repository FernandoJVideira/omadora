# Log in through greetd with the Quickshell greeter (omadora-greeter; its colors and logo follow the
# active Omadora theme). SDDM stays installed but disabled, so it can be switched back with
# `omadora-greeter rollback`. Hyprland's (uwsm) session is launched by the greeter itself. Enabled
# here, started on the next boot.
# Set OMADORA_KEEP_LOGIN_MANAGER=1 to keep SDDM with the Omadora login theme instead (colors and
# wallpaper follow the active Omadora theme; re-sync with `omactl theme login sync`).
if [[ -n "${OMADORA_KEEP_LOGIN_MANAGER:-}" ]] && ! systemctl is-enabled --quiet greetd.service 2>/dev/null; then
  sudo pacman -S --needed --noconfirm sddm qt6-svg qt6-declarative
  sudo systemctl enable --force sddm.service
  "$OMADORA_PATH/libexec/omadora-sddm-theme" set omadora
else
  "$OMADORA_PATH/libexec/omadora-greeter" install ||
    echo "WARNING: the greeter didn't install; run omadora-greeter install by hand."
fi
