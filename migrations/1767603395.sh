echo "Remove uneeded wiremix cargo binary"
cargo uninstall wiremix

echo "Install required packages"
sudo dnf install -y wiremix gnome-keyring xdg-terminal-exec

echo "Update theme symlinks"
for f in ~/.local/share/skein/themes/*; do ln -nfs "$f" ~/.config/skein/themes/; done

echo "Update application desktop files, icons, and mimetype associations"
bash "$SKEIN_PATH/install/config/mimetypes.sh"

echo "Add default webapps"
skein-webapp-install "Google Maps" https://maps.google.com "Google Maps.png"
skein-webapp-install "ChatGPT" https://chatgpt.com/ ChatGPT.png
skein-webapp-install "YouTube" https://youtube.com/ YouTube.png

echo "Update uwsm config"
skein-refresh-config uwsm/env
skein-refresh-config uwsm/default
skein-state set relaunch-required

echo "Update hyprland configs"
skein-refresh-hypridle
skein-refresh-hyprland
skein-refresh-hyprlock
skein-refresh-hyprsunset
skein-refresh-config hypr/windows.conf
skein-refresh-fastfetch
skein-refresh-bar
skein-refresh-wofi

echo "Update other configs"
skein-refresh-config alacritty/alacritty.toml
skein-refresh-config btop/btop.conf
skein-refresh-config fcitx5/conf/clipboard.conf
skein-refresh-config ghostty/config
skein-refresh-config systemd/user/skein-battery-monitor.service
skein-refresh-config xdg-terminals.list

echo "Add a default keyring for gnome-keyring that unlocks on login"
if [ -f "$HOME/.local/share/keyrings/Default_keyring.keyring" ] || [ -f "$HOME/.local/share/keyrings/default" ]; then
    if gum confirm "Do you want to replace existing keyring with one that's auto-unlocked on login?"; then
        bash "$SKEIN_PATH/install/login/default-keyring.sh"
    fi
else
    bash "$SKEIN_PATH/install/login/default-keyring.sh"
fi

echo "Copy hooks examples"
cp -r "$SKEIN_PATH"/config/skein/* "$HOME"/.config/skein/

skein-state set reboot-required
