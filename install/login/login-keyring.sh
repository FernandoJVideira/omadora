# Unlock the GNOME Keyring at login. Arch has no authselect, so add the PAM
# lines to the TTY and display-manager stacks directly (idempotent).
configure_omadora_login_keyring() {
  local keyrings_dir="$HOME/.local/share/keyrings"
  mkdir -p "$keyrings_dir"
  chmod 700 "$keyrings_dir"
  printf '%s\n' "login" >"$keyrings_dir/default"

  local pam_file
  for pam_file in /etc/pam.d/login /etc/pam.d/sddm; do
    [[ -f $pam_file ]] || continue
    if ! sudo grep -q pam_gnome_keyring.so "$pam_file"; then
      printf '\n%s\n%s\n' \
        'auth       optional     pam_gnome_keyring.so' \
        'session    optional     pam_gnome_keyring.so auto_start' |
        sudo tee -a "$pam_file" >/dev/null
    fi
  done
}

configure_omadora_login_keyring
unset -f configure_omadora_login_keyring
