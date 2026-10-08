# shellcheck shell=bash

# Make sure the package databases are current and an AUR helper (yay) exists.
sudo pacman -Syu --noconfirm

if ! command -v yay >/dev/null; then
  sudo pacman -S --needed --noconfirm base-devel git
  yay_dir="$(mktemp -d)"
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$yay_dir"
  (cd "$yay_dir" && makepkg -si --noconfirm)
  rm -rf "$yay_dir"
fi
