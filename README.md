# Omadora

This is a minimal install of Hyprland for Fedora 44 and Nobara 44, based on the Omarchy implementation and patterns.
It provides a more stable release cycle with tested and curated packages.

This branch (`nobara`) is a fork of [elpritchos/omadora](https://github.com/elpritchos/omadora) that runs alongside the stock Nobara desktop: it keeps KDE Plasma and adds Omadora as a second login session.

Omadora purposely does not include all the apps and features included with Omarchy, as it's intended to be a minimal install that provides core desktop functionality to allow users to build from.
However, as the implementation closely matches Omarchy, adding the extra features from Omarchy should be simple if you wish to do so.

## Preview

[![Omadora desktop using the dark theme](docs/screenshots/desktop-dark.png)](docs/screenshots/)

See the [screenshot gallery](docs/screenshots/) for dark and light theme previews.

Read more about Omarchy itself at [omarchy.org](https://omarchy.org).

> **Note**
> Omadora attempts to install only packages from the official Fedora and Nobara repositories, currently with the exception of Hyprland and related packages provided from COPR.
> Users should perform their own due diligence with regard to accepting the risk of installing packages from this third-party repository.

## What's different on this branch

- **Quickshell shell**: one Quickshell config provides the top bar and its panels (audio, network, Bluetooth, weather, calendar, display, agents), notifications, OSD, launcher and menus, lock screen, and the theme and wallpaper switchers. It replaces Waybar, wofi, mako and hyprlock.
- **Plasma Login Manager**: Plasma Login Manager (Nobara's login screen) is enabled by default, and only two sessions are offered: **Plasma** and **Omadora**.
- **Login screen theme**: choose the login wallpaper from the Style menu (Login Screen), including an `omadora` wallpaper that follows the active Omadora theme.
- **Default agent and crash diagnosis**: set a default coding agent with `omadora-default-agent`, and get notified with a diagnosis when an app crashes.
- **More themes**: Catppuccin, Gruvbox, Nord, Tokyo Night, Rose Pine and others (see [themes/THIRD_PARTY.md](themes/THIRD_PARTY.md)).

## Installation

Install Nobara 44 (KDE edition recommended) or a Fedora 44 Custom Operating System base install using the [Everything Network Installer](https://download.fedoraproject.org/pub/fedora/linux/releases/44/Everything).
On Fedora, it is recommended to use drive encryption, disable root, and add a privileged user.

To install, run the following:

```
curl -fsSL https://raw.githubusercontent.com/FernandoJVideira/omadora/nobara/boot.sh | OMADORA_REPO=FernandoJVideira/omadora OMADORA_REF=nobara bash
```

Or install manually:

Install git (`sudo dnf install -y git`) and shallow clone this branch to the `~/.local/share/omadora` directory.

```
git clone --depth 1 -b nobara https://github.com/FernandoJVideira/omadora ~/.local/share/omadora
```

Run `~/.local/share/omadora/install.sh` to install, then reboot.

> **Tip**
> For a WiFi only install, see the [FAQ](FAQ.md) for help.

## Usage

Pick **Omadora** from the session menu on the login screen. Pick **Plasma** to use the regular Nobara desktop.

Open the menu with `omactl menu` (or its keybinding) to change the theme, wallpaper, login screen, defaults and more. Everything is also available from the CLI: run `omactl` for the list of commands.

Update with `omactl update`. Updates pull over HTTPS, so they work without an SSH agent.

Stop Omadora by using the power menu or executing `omactl session logout`.

## Frequently Asked Questions

Check out the [FAQ.md](FAQ.md).

## Contribution

Please feel free to submit issues and PRs for improvement.

## Credits

Omadora is created by [elpritchos](https://github.com/elpritchos), based on [Omarchy](https://omarchy.org). This branch adapts it for Nobara.

## License

Omadora is released under the [MIT License](https://opensource.org/licenses/MIT).
