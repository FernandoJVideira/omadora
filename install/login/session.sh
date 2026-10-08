# Log in through SDDM, which lists Hyprland's (uwsm) session from
# /usr/share/wayland-sessions. Enabled here, started on the next boot.
sudo pacman -S --needed --noconfirm sddm
sudo systemctl enable sddm.service
