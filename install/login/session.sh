# Log in through SDDM, using the Omadora login theme (colors and wallpaper follow the
# active Omadora theme; re-sync with `omactl theme login sync`). Hyprland's (uwsm) session
# comes from /usr/share/wayland-sessions. Enabled here, started on the next boot.
sudo pacman -S --needed --noconfirm sddm qt6-svg qt6-declarative
sudo systemctl enable --force sddm.service
"$OMADORA_PATH/libexec/omadora-sddm-theme" set omadora
