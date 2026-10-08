# NetworkManager handles wired and WiFi (iwd is installed but used as its backend only if configured)
sudo systemctl enable NetworkManager.service
sudo systemctl disable systemd-networkd.service systemd-networkd-wait-online.service 2>/dev/null || true
