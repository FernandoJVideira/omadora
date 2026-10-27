# Log in through greetd with the Quickshell greeter (skein-greeter; its colors and logo follow the
# active Skein theme). On Nobara, Plasma Login Manager stays installed but disabled, so it can be
# switched back with `skein-greeter rollback`; `skein-remove-kde` drops KDE altogether.
# Set SKEIN_KEEP_LOGIN_MANAGER=1 to keep Plasma Login Manager as the login screen instead: it is
# then made the active display manager, offering only "Plasma" and "Skein" sessions, and a dnf
# action re-applies that filter whenever the session packages update. The helper is copied to a
# root-owned location so dnf (running as root) never executes a user-writable file.
if [[ -n "${SKEIN_NOBARA:-}" ]]; then
  if [[ -n "${SKEIN_KEEP_LOGIN_MANAGER:-}" ]] && ! systemctl is-enabled --quiet greetd.service 2>/dev/null; then
    sudo dnf install -y plasma-login-manager
    sudo systemctl enable --force plasmalogin.service

    sudo install -Dm755 "$SKEIN_PATH/libexec/skein-login-sessions" /usr/local/libexec/skein-login-sessions
    printf '%s\n' \
      'post_transaction:hyprland*:in::/usr/local/libexec/skein-login-sessions' \
      'post_transaction:plasma-workspace*:in::/usr/local/libexec/skein-login-sessions' \
      'post_transaction:plasma-login-manager*:in::/usr/local/libexec/skein-login-sessions' |
      sudo tee /etc/dnf/libdnf5-plugins/actions.d/skein-sessions.actions >/dev/null
    sudo /usr/local/libexec/skein-login-sessions
  else
    "$SKEIN_PATH/libexec/skein-greeter" install ||
      echo "WARNING: the greeter didn't install; run skein-greeter install by hand (Plasma Login Manager is still the login screen)."
  fi
fi
