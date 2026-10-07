# Install base groups (Nobara already ships a full desktop and its own multimedia stack)
if [[ -z "${OMADORA_NOBARA:-}" ]]; then
  mapfile -t groups < <(grep -v '^#' "$OMADORA_INSTALL/omadora-base.groups" | grep -v '^$')
  sudo dnf group install -y "${groups[@]}"
fi

# Install base packages
mapfile -t packages < <(grep -v '^#' "$OMADORA_INSTALL/omadora-base.packages" | grep -v '^$')
if [[ -n "${OMADORA_NOBARA:-}" ]]; then
  # Keep NetworkManager instead of iwd/systemd-networkd, Nobara's cardwire
  # conflicts with switcheroo-control, and KWallet already provides the
  # secret service (GNOME Keyring would compete with it in Plasma)
  mapfile -t packages < <(printf '%s\n' "${packages[@]}" | grep -vxE 'iwd|systemd-networkd-defaults|switcheroo-control|gnome-keyring-pam|seahorse')
fi
sudo dnf install -y "${packages[@]}"

# Install copr packages
mapfile -t packages < <(grep -v '^#' "$OMADORA_INSTALL/omadora-copr.packages" | grep -v '^$')
sudo dnf install -y "${packages[@]}"
