# Services Arch leaves disabled after installing the packages
sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null || sudo systemctl enable power-profiles-daemon.service
sudo systemctl enable bluetooth.service
powerprofilesctl set balanced || true
