# Nobara logs in through SDDM: make sure it is installed and the active display
# manager, and offer only "Plasma" and "Omadora" sessions. A dnf action
# re-applies the session filter whenever the session packages update. The
# helper is copied to a root-owned location so dnf (running as root) never
# executes a user-writable file.
if [[ -n "${OMADORA_NOBARA:-}" ]]; then
  sudo dnf install -y sddm
  sudo systemctl enable --force sddm.service

  sudo install -Dm755 "$OMADORA_PATH/libexec/omadora-login-sessions" /usr/local/libexec/omadora-login-sessions
  printf '%s\n' \
    'post_transaction:hyprland*:in::/usr/local/libexec/omadora-login-sessions' \
    'post_transaction:plasma-workspace*:in::/usr/local/libexec/omadora-login-sessions' \
    'post_transaction:sddm*:in::/usr/local/libexec/omadora-login-sessions' |
    sudo tee /etc/dnf/libdnf5-plugins/actions.d/omadora-sessions.actions >/dev/null
  sudo /usr/local/libexec/omadora-login-sessions
fi
