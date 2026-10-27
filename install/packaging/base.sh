# Install base packages from the official repositories
mapfile -t packages < <(grep -v '^#' "$SKEIN_INSTALL/skein-base.packages" | grep -v '^$')
sudo pacman -S --needed --noconfirm "${packages[@]}"

# Install AUR packages
mapfile -t packages < <(grep -v '^#' "$SKEIN_INSTALL/skein-aur.packages" | grep -v '^$')
yay -S --needed --noconfirm "${packages[@]}"
