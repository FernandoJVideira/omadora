# shellcheck shell=bash

# Enable necessary COPRs
if [[ -n "${OMADORA_NOBARA:-}" ]]; then
  # The copr plugin can't map Nobara to a chroot, so name the Fedora one.
  # mise and starship are already provided by Nobara/Terra repos.
  sudo dnf copr enable -y lionheartp/Hyprland "fedora-${VERSION_ID}-$(uname -m)"
else
  sudo dnf copr enable -y lionheartp/Hyprland
  sudo dnf copr enable -y jdxcode/mise
  sudo dnf copr enable -y atim/starship
fi
