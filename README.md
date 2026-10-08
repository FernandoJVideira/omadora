# Omadora

This is a minimal install of Hyprland for Arch Linux, based on the Omarchy implementation and patterns.

This branch (`arch`) is a fork of [elpritchos/omadora](https://github.com/elpritchos/omadora), branched from this fork's `nobara` branch and converted from dnf/COPR to pacman and the AUR. It targets a minimal Arch install with no desktop environment. The Nobara branch is `nobara`; keep shared changes (the shell, themes, `omactl`) in step between the two.

Omadora purposely does not include all the apps and features included with Omarchy, as it's intended to be a minimal install that provides core desktop functionality to allow users to build from.
However, as the implementation closely matches Omarchy, adding the extra features from Omarchy should be simple if you wish to do so.

## Preview

[![Omadora desktop using the dark theme](docs/screenshots/desktop-dark.png)](docs/screenshots/)

See the [screenshot gallery](docs/screenshots/) for dark and light theme previews.

Read more about Omarchy itself at [omarchy.org](https://omarchy.org).

> **Note**
> Omadora installs almost everything from the official Arch repositories. A few packages (`xfce-polkit`, `yaru-icon-theme`) come from the AUR and are built with `yay`, which the installer bootstraps from `yay-bin`.
> Users should perform their own due diligence with regard to accepting the risk of installing AUR packages.

## What's different on this branch

- **Quickshell shell**: one Quickshell config provides the top bar and its panels (audio, network, Bluetooth, weather, calendar, display, agents), notifications, OSD, launcher and menus, lock screen, and the theme and wallpaper switchers. It replaces Waybar, wofi, mako and hyprlock.
- **SDDM login**: SDDM is the display manager, with an `omadora` theme whose colors and wallpaper follow the active Omadora theme. Pick the login theme from the Style menu (Login Screen), or run `omactl theme login sync`. Syncing needs sudo; the automatic sync on theme change only runs when sudo needs no password.
- **Default agent and crash diagnosis**: set a default coding agent with `omadora-default-agent`, and get notified with a diagnosis when an app crashes.
- **More themes**: Catppuccin, Gruvbox, Nord, Tokyo Night, Rose Pine and others (see [themes/THIRD_PARTY.md](themes/THIRD_PARTY.md)).

## Installation

Install Arch Linux with `archinstall`: a minimal profile with **no desktop environment and no display manager**, `NetworkManager` as the network backend, a privileged (sudo/wheel) user, and drive encryption if you want it. The installer's guard aborts on a non-Arch system, as root, or when GDM, LightDM or Plasma Login is already enabled.

To install, run the following:

```
curl -fsSL https://raw.githubusercontent.com/FernandoJVideira/omadora/arch/boot.sh | bash
```

Or install manually:

Install git (`sudo pacman -S git`) and shallow clone this branch to the `~/.local/share/omadora` directory.

```
git clone --depth 1 -b arch https://github.com/FernandoJVideira/omadora ~/.local/share/omadora
```

Run `~/.local/share/omadora/install.sh` to install; it reboots at the end.

> **Not done yet on Arch**
> The Plymouth boot splash and NVIDIA driver packages are not set up (NVIDIA only gets its environment variables), and update advisories (security counts) are always zero. Bluetooth, fingerprint, FIDO2 and GPU acceleration have not been tested on real hardware.

> **Tip**
> For a WiFi only install, see the [FAQ](FAQ.md) for help.

## Usage

Log in at SDDM and keep the **Hyprland (uwsm-managed)** session selected.

Open the menu with `omactl menu` (or its keybinding) to change the theme, wallpaper, login screen, defaults and more. Everything is also available from the CLI: run `omactl` for the list of commands.

Update with `omactl update`. Updates pull over HTTPS, so they work without an SSH agent.

Stop Omadora by using the power menu or executing `omactl session logout`.

## Frequently Asked Questions

Check out the [FAQ.md](FAQ.md).

## Contribution

Please feel free to submit issues and PRs for improvement.

## Credits

Omadora is created by [elpritchos](https://github.com/elpritchos), based on [Omarchy](https://omarchy.org). This branch adapts it for Arch Linux.

## License

Omadora is released under the [MIT License](https://opensource.org/licenses/MIT).
