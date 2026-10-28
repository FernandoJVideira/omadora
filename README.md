# Skein

This is a minimal install of Hyprland for Fedora 44 and Nobara 44, based on the Omarchy implementation and patterns.
It provides a more stable release cycle with tested and curated packages.

Skein is a fork of [elpritchos/omadora](https://github.com/elpritchos/omadora) (itself based on [Omarchy](https://omarchy.org) by David Heinemeier Hansson), renamed because the same theming now runs on more than one OS. This branch (`nobara`) runs on Nobara next to the stock KDE desktop, or instead of it: it installs a Quickshell login screen in place of Plasma Login Manager, and `skein-remove-kde` can drop KDE altogether.

Skein purposely does not include all the apps and features included with Omarchy, as it's intended to be a minimal install that provides core desktop functionality to allow users to build from.
However, as the implementation closely matches Omarchy, adding the extra features from Omarchy should be simple if you wish to do so.

## Preview

[![Skein desktop using the dark theme](docs/screenshots/desktop-dark.png)](docs/screenshots/)

See the [screenshot gallery](docs/screenshots/) for dark and light theme previews.

Read more about Omarchy itself at [omarchy.org](https://omarchy.org).

> **Note**
> Skein attempts to install only packages from the official Fedora and Nobara repositories, currently with the exception of Hyprland and related packages provided from COPR.
> Users should perform their own due diligence with regard to accepting the risk of installing packages from this third-party repository.

## What's different on this branch

- **Quickshell shell**: one Quickshell config provides the top bar and its panels (audio, network, Bluetooth, weather, calendar, display, agents), notifications, OSD, launcher and menus, lock screen, and the theme and wallpaper switchers. It replaces Waybar, wofi, mako and hyprlock.
- **Quickshell login screen**: greetd with a Quickshell greeter styled after Omarchy's login (the Skein logo, a lock and an entry box that fills with bullets), in `default/greeter`. It runs in cage, lays the monitors out itself (the form goes on the main one), takes the active theme's colors and follows theme changes, and unlocks the keyring at login.
- **Dropping KDE**: `skein-remove-kde schedule` queues the removal of Plasma, its apps and the default apps Nobara ships for the next boot, before the login screen (removing Plasma Login Manager from inside a Plasma session would end that session). `skein-remove-kde remove` does it by hand from a session greetd started, with a `dnf` preview and a typed confirmation; either way the preview must not touch `nobara-*`, Hyprland, Quickshell, the gaming stack or KWallet. `skein-remove-kde clean` removes what Plasma left in your home (the scheduled run does that too).
- **Default agent and crash diagnosis**: set a default coding agent with `skein-default-agent`, and get notified with a diagnosis when an app crashes.
- **More themes**: Catppuccin, Gruvbox, Nord, Tokyo Night, Rose Pine and others (see [themes/THIRD_PARTY.md](themes/THIRD_PARTY.md)).

## Installation

Install Nobara 44 (KDE edition recommended) or a Fedora 44 Custom Operating System base install using the [Everything Network Installer](https://download.fedoraproject.org/pub/fedora/linux/releases/44/Everything).
On Fedora, it is recommended to use drive encryption, disable root, and add a privileged user.

To install, run the following:

```
curl -fsSL https://raw.githubusercontent.com/FernandoJVideira/skein/nobara/boot.sh | SKEIN_REPO=FernandoJVideira/skein SKEIN_REF=nobara bash
```

Or install manually:

Install git (`sudo dnf install -y git`) and shallow clone this branch to the `~/.local/share/skein` directory.

```
git clone --depth 1 -b nobara https://github.com/FernandoJVideira/skein ~/.local/share/skein
```

Run `~/.local/share/skein/install.sh` to install, then reboot.

> **Tip**
> For a WiFi only install, see the [FAQ](FAQ.md) for help.

## Usage

Log in through the greeter; it starts the **Skein** session.

Open the menu with `skeinctl menu` (or its keybinding) to change the theme, wallpaper, defaults and more. Everything is also available from the CLI: run `skeinctl` for the list of commands.

Update with `skeinctl update`. Updates pull over HTTPS, so they work without an SSH agent.

Stop Skein by using the power menu or executing `skeinctl session logout`.

## Frequently Asked Questions

Check out the [FAQ.md](FAQ.md).

## Contribution

Please feel free to submit issues and PRs for improvement.

## Credits

Skein started as [Omadora](https://github.com/elpritchos/omadora), created by [elpritchos](https://github.com/elpritchos), which is based on [Omarchy](https://omarchy.org) by David Heinemeier Hansson. This fork keeps their copyright notices in [LICENSE](LICENSE). It adds the Nobara branch, the Quickshell shell and login screen, the macOS side and the renaming.

## License

Skein is released under the [MIT License](https://opensource.org/licenses/MIT). The upstream copyright notices stay in LICENSE, next to this fork's.
