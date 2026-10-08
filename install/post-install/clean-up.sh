# Nothing to prune on a minimal Arch install; just drop NetworkManager's stale
# configuration so Omadora's own gets applied cleanly.
sudo rm -rf /etc/NetworkManager/conf.d/*omadora* 2>/dev/null || true
