#!/usr/bin/env bash
set -euo pipefail

echo "Migrate to Skein v3.8.2"

export SKEIN_PATH="${SKEIN_PATH:-$HOME/.local/share/skein}"
export SKEIN_INSTALL="${SKEIN_INSTALL:-$SKEIN_PATH/install}"
export PATH="$SKEIN_PATH/bin:$PATH"

migration_log="$HOME/skein-v3.8.2-migration.log"
exec > >(tee -a "$migration_log") 2>&1
echo "Logging migration output to: $migration_log"
echo "Starting Skein v3.8.2 migration at $(date -Is)"

skein() {
  local command="$1"
  shift

  if command -v "$command" >/dev/null 2>&1; then
    "$command" "$@"
  else
    skein-exec "$command" "$@"
  fi
}

refresh_config() {
  skein skein-refresh-config "$1"
}

source_install_script() {
  local script="$1"
  # shellcheck source=/dev/null
  source "$SKEIN_INSTALL/$script"
}

echo "Enable new package sources"
sudo dnf copr remove sdegler/hyprland || true
source_install_script preflight/dnf.sh

echo "Remove cargo-installed eza"
cargo uninstall eza || true

echo "Remove replaced Hyprland polkit agent"
sudo dnf remove -y hyprpolkitagent || true

echo "Remove dnf-installed satty"
sudo dnf remove -y satty || true

echo "Remove old disk usage TUI launcher"
rm -f "$HOME/.local/share/applications/Disk Usage.desktop"

echo "Install updated packages and wrappers"
source_install_script packaging/base.sh
source_install_script packaging/cargo.sh
source_install_script packaging/flatpak.sh
source_install_script packaging/fonts.sh
source_install_script packaging/icons.sh
source_install_script packaging/tuis.sh
source_install_script packaging/npm.sh

echo "Apply updated hardware configuration"
remove_old_networkd_file() {
  local path="$1"
  local expected="$2"
  local tmpfile

  tmpfile="$(mktemp)"
  printf '%s\n' "$expected" >"$tmpfile"

  if sudo test -f "$path" && sudo cmp -s "$tmpfile" "$path"; then
    sudo rm -f "$path"
  fi

  rm -f "$tmpfile"
}

remove_old_networkd_file /etc/systemd/network/20-wired.network '[Match]
Name=en*

[Network]
DHCP=yes'
remove_old_networkd_file /etc/systemd/network/25-wifi.network '[Match]
Name=wl*

[Network]
DHCP=yes'
unset -f remove_old_networkd_file
source_install_script config/hardware/network.sh

echo "Refresh application launchers and MIME associations"
skein skein-refresh-applications
source_install_script config/mimetypes.sh

echo "Refresh Skein configs"
skein skein-refresh-fastfetch
skein skein-refresh-hypridle
skein skein-refresh-hyprland
skein skein-refresh-hyprlock
skein skein-refresh-hyprsunset
skein skein-refresh-bar
skein skein-refresh-wofi

for config in \
  alacritty/alacritty.toml \
  btop/btop.conf \
  chromium-flags.conf \
  fontconfig/fonts.conf \
  ghostty/config \
  hypr/hyprpaper.conf \
  hypr/windows.conf \
  kitty/kitty.conf \
  opencode/opencode.json \
  systemd/user/hypridle.service.d/skein.conf \
  systemd/user/hyprpaper.service.d/skein.conf \
  systemd/user/hyprsunset.service.d/skein.conf \
  systemd/user/mako.service.d/skein.conf \
  systemd/user/skein-battery-monitor.service \
  systemd/user/skein-battery-monitor.timer \
  systemd/user/skein-fcitx5.service \
  systemd/user/skein-hyprland-monitor.service \
  systemd/user/skein-hyprlock.service \
  systemd/user/skein-polkitagent.service \
  systemd/user/skein-recover-internal-monitor.service \
  systemd/user/skein-session.service \
  systemd/user/skein-session.target \
  systemd/user/skein-update-check.service \
  systemd/user/skein-update-check.timer \
  systemd/user/skein-weather-check.service \
  systemd/user/skein-weather-check.timer \
  starship.toml \
  tmux/tmux.conf \
  uwsm/default \
  uwsm/env \
  wiremix/wiremix.toml \
  xdg-terminals.list; do
  refresh_config "$config"
done

echo "Install Nautilus extensions and Skein toggle defaults"
source_install_script config/nautilus-python.sh
source_install_script config/skein-toggles.sh

echo "Backup removed environment.d config"
if [[ -e "$HOME/.config/environment.d" || -L "$HOME/.config/environment.d" ]]; then
  environment_d_backup="$HOME/.config/environment.d.bak.$(date +%s)"
  mv "$HOME/.config/environment.d" "$environment_d_backup"
  echo "Moved existing environment.d config to $environment_d_backup"
fi
unset environment_d_backup

echo "Backup removed SwayOSD, Walker, and Brave configs"
for config_path in \
  "$HOME/.config/swayosd" \
  "$HOME/.config/walker" \
  "$HOME/.config/brave-flags.conf"; do
  if [[ -e "$config_path" || -L "$config_path" ]]; then
    config_backup="$config_path.bak.$(date +%s)"
    mv "$config_path" "$config_backup"
    echo "Moved existing ${config_path#"$HOME"/} to $config_backup"
  fi
done
unset config_path config_backup

echo "Install updated bash defaults"
if [[ -e "$HOME/.bashrc" || -L "$HOME/.bashrc" ]]; then
  bashrc_backup="$HOME/.bashrc.bak.$(date +%s)"
  mv "$HOME/.bashrc" "$bashrc_backup"
  echo "Moved existing .bashrc to $bashrc_backup"
fi
cp "$SKEIN_PATH/default/bashrc" "$HOME/.bashrc"
unset bashrc_backup

echo "Configure Mise work defaults"
mkdir -p "$HOME/Work/tries"
if [[ ! -f "$HOME/Work/.mise.toml" ]]; then
  cat >"$HOME/Work/.mise.toml" <<'EOF'
[env]
_.path = "{{ cwd }}/bin"
EOF
fi
mise trust "$HOME/Work/.mise.toml"
mise use -g node@latest

echo "Install updated Neovim defaults"
if [[ -e "$HOME/.config/nvim" || -L "$HOME/.config/nvim" ]]; then
  nvim_backup="$HOME/.config/nvim.bak.$(date +%s)"
  mv "$HOME/.config/nvim" "$nvim_backup"
  echo "Moved existing Neovim config to $nvim_backup"
fi
source_install_script packaging/nvim.sh
ln -snf "$HOME/.config/skein/current/theme/neovim.lua" "$HOME/.config/nvim/lua/plugins/skein-theme.lua"
unset nvim_backup

echo "Install and reapply themes"
current_theme="$(skein skein-theme-current 2>/dev/null || true)"
skein skein-theme-install-omarchy -y
if [[ -n "$current_theme" ]] && skein skein-theme-list | grep -qxF "$current_theme"; then
  skein skein-theme-set "$current_theme"
else
  skein skein-theme-set "Rose Pine Darker"
fi
mkdir -p "$HOME/.config/btop/themes" "$HOME/.config/mako"
ln -snf "$HOME/.config/skein/current/theme/btop.theme" "$HOME/.config/btop/themes/current.theme"
ln -snf "$HOME/.config/skein/current/theme/mako.ini" "$HOME/.config/mako/config"
ln -snf "$HOME/.config/skein/current/theme/neovim.lua" "$HOME/.config/nvim/lua/plugins/skein-theme.lua"
unset current_theme

echo "Set GNOME font defaults"
gsettings set org.gnome.desktop.interface font-name "Adwaita Sans 11"
gsettings set org.gnome.desktop.interface document-font-name "Adwaita Sans 12"
gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 10.5"

echo "Add GTK bookmarks without duplicating existing entries"
xdg-user-dirs-update
mkdir -p "$HOME/.config/gtk-3.0"
touch "$HOME/.config/gtk-3.0/bookmarks"
for dir in Desktop Documents Downloads Music Pictures Public Templates Videos; do
  bookmark="file://$HOME/$dir $dir"
  grep -qxF "$bookmark" "$HOME/.config/gtk-3.0/bookmarks" ||
    printf '%s\n' "$bookmark" >>"$HOME/.config/gtk-3.0/bookmarks"
done

echo "Copy hook samples"
mkdir -p "$HOME/.config/skein/hooks"
cp -rn "$SKEIN_PATH"/config/skein/hooks/. "$HOME/.config/skein/hooks/"
cp -rn "$SKEIN_PATH"/config/skein/extensions "$HOME/.config/skein/"
cp -rn "$SKEIN_PATH"/config/skein/themed "$HOME/.config/skein/"

echo "Enable updated login and user services"
systemctl --user daemon-reload || true
source_install_script login/systemd.sh
source_install_script login/login-keyring.sh
systemctl --user daemon-reload || true

echo "Refresh Plymouth theme"
skein skein-refresh-plymouth

echo "Mark reboot required"
sudo touch /run/reboot-required

cat <<'EOF'

************************************************************
*                                                          *
*                    REBOOT REQUIRED                       *
*                                                          *
*        Skein v3.8.2 migration has completed, but       *
*      these changes require a system reboot to apply.     *
*                                                          *
************************************************************

EOF

echo "Completed Skein v3.8.2 migration at $(date -Is)"
