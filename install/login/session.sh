# Log in through greetd with the Quickshell greeter (omadora-greeter; its colors and logo follow the
# active Omadora theme). On Nobara, Plasma Login Manager stays installed but disabled, so it can be
# switched back with `omadora-greeter rollback`; `omadora-remove-kde` drops KDE altogether.
# Set OMADORA_KEEP_LOGIN_MANAGER=1 to keep Plasma Login Manager as the login screen instead: it is
# then made the active display manager, offering only "Plasma" and "Omadora" sessions, and a dnf
# action re-applies that filter whenever the session packages update. The helper is copied to a
# root-owned location so dnf (running as root) never executes a user-writable file.
if [[ -n "${OMADORA_NOBARA:-}" ]]; then
  if [[ -n "${OMADORA_KEEP_LOGIN_MANAGER:-}" ]] && ! systemctl is-enabled --quiet greetd.service 2>/dev/null; then
    sudo dnf install -y plasma-login-manager
    sudo systemctl enable --force plasmalogin.service

    sudo install -Dm755 "$OMADORA_PATH/libexec/omadora-login-sessions" /usr/local/libexec/omadora-login-sessions
    printf '%s\n' \
      'post_transaction:hyprland*:in::/usr/local/libexec/omadora-login-sessions' \
      'post_transaction:plasma-workspace*:in::/usr/local/libexec/omadora-login-sessions' \
      'post_transaction:plasma-login-manager*:in::/usr/local/libexec/omadora-login-sessions' |
      sudo tee /etc/dnf/libdnf5-plugins/actions.d/omadora-sessions.actions >/dev/null
    sudo /usr/local/libexec/omadora-login-sessions
  else
    "$OMADORA_PATH/libexec/omadora-greeter" install ||
      echo "WARNING: the greeter didn't install; run omadora-greeter install by hand (Plasma Login Manager is still the login screen)."
  fi
fi
