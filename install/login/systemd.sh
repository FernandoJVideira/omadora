# Ensure system boots to GUI-capable state
sudo systemctl set-default graphical.target

# Enable Skein systemd units
systemctl --user enable skein-session.target
systemctl --user enable skein-recover-internal-monitor.service

# Let PAM unlock a user-manager-owned keyring daemon before a graphical session starts
if true; then
  systemctl --user enable gnome-keyring-daemon.socket
fi
