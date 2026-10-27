# Skein

This is a minimal install of Hyprland for Arch Linux, based on the Omarchy implementation and patterns.

Skein is a fork of [elpritchos/omadora](https://github.com/elpritchos/omadora) (itself based on [Omarchy](https://omarchy.org) by David Heinemeier Hansson), renamed because the same theming now runs on more than one OS. This branch (`arch`) is branched from this fork's `nobara` branch and converted from dnf/COPR to pacman and the AUR. It targets a minimal Arch install with no desktop environment. The Nobara branch is `nobara`; keep shared changes (the shell, themes, `skeinctl`) in step between the two.

Skein purposely does not include all the apps and features included with Omarchy, as it's intended to be a minimal install that provides core desktop functionality to allow users to build from.
However, as the implementation closely matches Omarchy, adding the extra features from Omarchy should be simple if you wish to do so.

## Preview

[![Skein desktop using the dark theme](docs/screenshots/desktop-dark.png)](docs/screenshots/)

See the [screenshot gallery](docs/screenshots/) for dark and light theme previews.

Read more about Omarchy itself at [omarchy.org](https://omarchy.org).

> **Note**
> Skein installs almost everything from the official Arch repositories. A few packages (`xfce-polkit`, `yaru-icon-theme`) come from the AUR and are built with `yay`, which the installer bootstraps from `yay-bin`.
> Users should perform their own due diligence with regard to accepting the risk of installing AUR packages.

## What's different on this branch

- **Quickshell shell**: one Quickshell config provides the top bar and its panels (audio, network, Bluetooth, weather, calendar, display, agents), notifications, OSD, launcher and menus, lock screen, and the theme and wallpaper switchers. It replaces Waybar, wofi, mako and hyprlock.
- **Quickshell login screen**: greetd with a Quickshell greeter styled after Omarchy's login (the Skein logo, a lock and an entry box that fills with bullets), in `default/greeter`. It runs in cage, lays the monitors out itself (the form goes on the main one), takes the active theme's colors and follows theme changes, and unlocks the GNOME Keyring at login. SDDM stays installed but disabled; `skein-greeter rollback` switches back, and `SKEIN_KEEP_LOGIN_MANAGER=1` at install time keeps SDDM with its `skein` theme as the login screen (Style menu, Login Screen, or `skeinctl theme login sync`).
- **Default agent and crash diagnosis**: set a default coding agent with `skein-default-agent`, and get notified with a diagnosis when an app crashes.
- **More themes**: Catppuccin, Gruvbox, Nord, Tokyo Night, Rose Pine and others (see [themes/THIRD_PARTY.md](themes/THIRD_PARTY.md)).

## Installation

Install Arch Linux with `archinstall`: a minimal profile with **no desktop environment and no display manager**, `NetworkManager` as the network backend, a privileged (sudo/wheel) user, and drive encryption if you want it. The installer's guard aborts on a non-Arch system, as root, or when GDM, LightDM or Plasma Login is already enabled.

To install, run the following:

```
curl -fsSL https://raw.githubusercontent.com/FernandoJVideira/skein/arch/boot.sh | bash
```

Or install manually:

Install git (`sudo pacman -S git`) and shallow clone this branch to the `~/.local/share/skein` directory.

```
git clone --depth 1 -b arch https://github.com/FernandoJVideira/skein ~/.local/share/skein
```

Run `~/.local/share/skein/install.sh` to install; it reboots at the end.

> **Not done yet on Arch**
> The Plymouth boot splash and NVIDIA driver packages are not set up (NVIDIA only gets its environment variables), and update advisories (security counts) are always zero. Bluetooth, fingerprint, FIDO2 and GPU acceleration have not been tested on real hardware.

> **Tip**
> For a WiFi only install, see the [FAQ](FAQ.md) for help.

## Usage

Log in at the Quickshell greeter (it starts the **Hyprland (uwsm-managed)** session itself; with SDDM kept, keep that session selected).

Open the menu with `skeinctl menu` (or its keybinding) to change the theme, wallpaper, login screen, defaults and more. Everything is also available from the CLI: run `skeinctl` for the list of commands.

Update with `skeinctl update`. Updates pull over HTTPS, so they work without an SSH agent.

Stop Skein by using the power menu or executing `skeinctl session logout`.

## Frequently Asked Questions

Check out the [FAQ.md](FAQ.md).

## Contribution

Please feel free to submit issues and PRs for improvement.

## Credits

Skein started as [Omadora](https://github.com/elpritchos/omadora), created by [elpritchos](https://github.com/elpritchos), which is based on [Omarchy](https://omarchy.org) by David Heinemeier Hansson. This fork keeps their copyright notices in [LICENSE](LICENSE). It adds the Nobara and Arch branches, the Quickshell shell and login screen, the macOS side and the renaming.

## License

Skein is released under the [MIT License](https://opensource.org/licenses/MIT). The upstream copyright notices stay in LICENSE, next to this fork's.
