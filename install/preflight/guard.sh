abort() {
  echo -e "\e[31mOmadora install requires: $1\e[0m"
  echo

  read -rp "Proceed anyway on your own accord and without assistance? [y/N] " response
  case "$response" in
  [yY][eE][sS] | [yY]) ;;
  *) exit 1 ;;
  esac
}

# Must be Arch Linux (or an Arch-based distro that keeps pacman and the official repos)
[[ -f /etc/os-release ]] || abort "Arch Linux"
# shellcheck source=/dev/null
source /etc/os-release
[[ "${ID:-}" == "arch" || "${ID_LIKE:-}" == *arch* ]] || abort "Arch Linux"
command -v pacman >/dev/null || abort "pacman"

# Must not be running as root
if [ "$EUID" -eq 0 ]; then
  abort "Running as user (not root)"
fi

# Must be x86_64 (the AUR and Hyprland's packages target it)
if [ "$(uname -m)" != "x86_64" ]; then
  abort "x86_64 CPU"
fi

# Should be a minimal install (no desktop environment or display manager yet)
for dm in gdm sddm lightdm plasmalogin; do
  systemctl is-enabled "$dm.service" &>/dev/null && abort "Minimal install without a display manager ($dm is enabled)"
done

# Cleared all guards
echo "Guards: OK"
