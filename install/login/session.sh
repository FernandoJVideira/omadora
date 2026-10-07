# Nobara logs in through a display manager: offer a single "Omadora" session
# and hide the stock Hyprland entries. A dnf action re-applies this whenever the
# Hyprland packages update. The helper is copied to a root-owned location so
# dnf (running as root) never executes a user-writable file.
if [[ -n "${OMADORA_NOBARA:-}" ]]; then
  sudo install -Dm755 "$OMADORA_PATH/libexec/omadora-login-sessions" /usr/local/libexec/omadora-login-sessions
  echo 'post_transaction:hyprland*:in::/usr/local/libexec/omadora-login-sessions' |
    sudo tee /etc/dnf/libdnf5-plugins/actions.d/omadora-sessions.actions >/dev/null
  sudo /usr/local/libexec/omadora-login-sessions
fi
