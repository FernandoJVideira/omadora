#!/bin/bash

set -e

# Set install mode to online since boot.sh is used for curl installations
export SKEIN_ONLINE_INSTALL=true

ansi_art='
▄██████▄    ▄▄▄▄███▄▄▄▄      ▄████████ ████████▄   ▄██████▄     ▄████████    ▄████████
███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ ███   ▀███ ███    ███   ███    ███   ███    ███
███    ███ ███   ███   ███   ███    ███ ███    ███ ███    ███   ███    ███   ███    ███
███    ███ ███   ███   ███   ███    ███ ███    ███ ███    ███  ▄███▄▄▄▄██▀   ███    ███
███    ███ ███   ███   ███ ▀███████████ ███    ███ ███    ███ ▀▀███▀▀▀▀▀   ▀███████████
███    ███ ███   ███   ███   ███    ███ ███    ███ ███    ███ ▀███████████   ███    ███
███    ███ ███   ███   ███   ███    ███ ███   ▄███ ███    ███   ███    ███   ███    ███
 ▀██████▀   ▀█   ███   █▀    ███    █▀  ████████▀   ▀██████▀    ███    ███   ███    █▀
                                                                ███    ███'

clear
echo -e "\n$ansi_art\n"

echo "Installing git to clone the Skein repo..."
sudo dnf install -y git

# Use custom repo if specified, otherwise default
SKEIN_REPO="${SKEIN_REPO:-FernandoJVideira/skein}"

# Use custom branch if instructed, otherwise default to master
SKEIN_REF="${SKEIN_REF:-master}"

echo -e "\nCloning Skein from: https://github.com/${SKEIN_REPO}.git"
echo -e "\e[32mUsing ref: $SKEIN_REF\e[0m"
rm -rf ~/.local/share/skein/
git clone --depth 1 --branch "$SKEIN_REF" "https://github.com/${SKEIN_REPO}.git" ~/.local/share/skein >/dev/null

echo -e "\nInstallation starting..."
source ~/.local/share/skein/install.sh
