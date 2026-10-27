echo "Install required packages"
sudo dnf install -y libxkbcommon-utils

echo "Copy in extensions examples"
cp -r "$SKEIN_PATH/config/skein/extensions" "$HOME/.config/skein/extensions"

echo "Copy configs for kitty if not existing"
if [[ ! -f ~/.config/kitty/kitty.conf ]]; then
  mkdir -p ~/.config/kitty
  cp -Rpf "$SKEIN_PATH/config/kitty/kitty.conf" ~/.config/kitty/kitty.conf
fi

echo "Update configs"
skein-refresh-hypridle
skein-refresh-bar
