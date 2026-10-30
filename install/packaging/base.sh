# Install base groups (Nobara already ships a full desktop and its own multimedia stack,
# but still needs the development headers for the cargo builds)
if [[ -n "${SKEIN_NOBARA:-}" ]]; then
  sudo dnf group install -y development-libs
else
  mapfile -t groups < <(grep -v '^#' "$SKEIN_INSTALL/skein-base.groups" | grep -v '^$')
  sudo dnf group install -y "${groups[@]}"
fi

# Install base packages
mapfile -t packages < <(grep -v '^#' "$SKEIN_INSTALL/skein-base.packages" | grep -v '^$')
if [[ -n "${SKEIN_NOBARA:-}" ]]; then
  # Keep NetworkManager instead of iwd/systemd-networkd and Nobara's cardwire
  # conflicts with switcheroo-control
  skip='iwd|systemd-networkd-defaults|switcheroo-control'
  # With KWallet as the secret service, GNOME Keyring would compete with it in Plasma
  [[ "${SKEIN_KEYRING:-gnome}" == "kwallet" ]] && skip+='|gnome-keyring-pam|seahorse'
  mapfile -t packages < <(printf '%s\n' "${packages[@]}" | grep -vxE "$skip")
fi
sudo dnf install -y "${packages[@]}"

# Drop KWallet when GNOME Keyring is the secret service, unless something else needs it
if [[ -n "${SKEIN_NOBARA:-}" && "${SKEIN_KEYRING:-gnome}" == "gnome" ]]; then
  kwallet_set=(pam-kwallet kf6-kwallet kf6-kwallet-libs kf5-kwallet kf5-kwallet-libs)
  kwallet_installed=()
  for pkg in "${kwallet_set[@]}"; do
    rpm -q "$pkg" >/dev/null 2>&1 && kwallet_installed+=("$pkg")
  done
  if ((${#kwallet_installed[@]})); then
    kwallet_users=$(rpm -q --qf '%{NAME}\n' --whatrequires "${kwallet_installed[@]}" 2>/dev/null |
      grep -v 'no package requires' | grep -vxF -f <(printf '%s\n' "${kwallet_set[@]}") || true)
    if [[ -z "$kwallet_users" ]]; then
      sudo dnf remove -y "${kwallet_installed[@]}" || echo "Could not remove KWallet, skipping."
    else
      echo "Keeping KWallet, still required by: $(tr '\n' ' ' <<<"$kwallet_users")"
    fi
  fi
fi

# Install copr packages
mapfile -t packages < <(grep -v '^#' "$SKEIN_INSTALL/skein-copr.packages" | grep -v '^$')
sudo dnf install -y "${packages[@]}"
