# Install base packages from the official repositories
mapfile -t packages < <(grep -v '^#' "$OMADORA_INSTALL/omadora-base.packages" | grep -v '^$')
sudo pacman -S --needed --noconfirm "${packages[@]}"

# Install AUR packages
mapfile -t packages < <(grep -v '^#' "$OMADORA_INSTALL/omadora-aur.packages" | grep -v '^$')
yay -S --needed --noconfirm "${packages[@]}"
