echo "Ensure packages installed"
source $SKEIN_PATH/install/packages.sh

echo "Add fontconfig"
if [[ ! -d $HOME/.config/fontconfig ]]; then
  cp -r $SKEIN_PATH/config/fontconfig $HOME/.config/
fi

echo "Add starship config"
if [[ ! -f $HOME/.config/starship.toml ]]; then
  cp $SKEIN_PATH/config/starship.toml $HOME/.config/
fi

echo "Add brave-flags.conf"
if [[ ! -f $HOME/.config/brave-flags.conf ]]; then
  cp $SKEIN_PATH/config/brave-flags.conf $HOME/.config/
fi

echo "Copy screensaver logo"
mkdir -p $HOME/.config/skein/branding
cp $SKEIN_PATH/logo.txt $HOME/.config/skein/branding/screensaver.txt

echo "Update fastfetch"
mkdir -p $HOME/.config/skein/branding
cp $SKEIN_PATH/icon.txt $HOME/.config/skein/branding/about.txt
skein-refresh-config fastfetch/config.jsonc

echo "Update configs"
skein-refresh-config hypr/bindings.conf
skein-refresh-hyprland
skein-refresh-hyprlock
skein-refresh-hypridle
skein-refresh-walker
skein-refresh-wofi
skein-refresh-bar
skein-refresh-applications

echo "Remove old desktop files and icons"
rm -f $HOME/.local/share/applications/About.desktop
rm -f $HOME/.local/share/applications/Activity.desktop
rm -f $HOME/.local/share/applications/wiremix.desktop
rm -f $HOME/.local/share/icons/hicolor/48x48/apps/Activity.png
rm -f $HOME/.local/share/icons/hicolor/48x48/apps/Arch.png
rm -f $HOME/.local/share/icons/hicolor/48x48/apps/Docker.png
rm -f $HOME/.local/share/icons/hicolor/48x48/apps/Fedora.png
rm -f $HOME/.local/share/icons/hicolor/48x48/apps/Flatpak.png
