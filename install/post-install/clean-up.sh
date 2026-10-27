# Nothing to prune on a minimal Arch install; just drop NetworkManager's stale
# configuration so Skein's own gets applied cleanly.
sudo rm -rf /etc/NetworkManager/conf.d/*skein* 2>/dev/null || true
