---
name: skein
description: >
  Work on this machine's Skein desktop: a Fedora/Nobara port of Omarchy built on
  Hyprland (Lua config) and a Quickshell shell. Use for anything about the desktop:
  the top bar and its panels, notifications, launcher and menus, lock screen, themes,
  wallpapers, keybindings, monitors, defaults (agent, browser, terminal, editor),
  updates, toggles, or changing how Skein behaves. Triggers: skein, skeinctl,
  quickshell, qs, hyprland config, bar, theme, wallpaper, keybind, "set my default".
---

# Skein

Skein lives in `~/.local/share/skein` (`$SKEIN_PATH`, a git repo). Everything
you may change for the user goes into their config, not the repo, unless they are
developing Skein itself.

## Where things are

| What | Where |
|---|---|
| Commands | `libexec/skein-*`, driven by `skeinctl <group> <command>` (`skeinctl` lists them) |
| Hyprland config | `~/.config/hypr/*.lua` (user) over `default/hypr/*.lua` (Skein's defaults) |
| Shell (bar, panels, notifications, OSD, lock, launcher, switchers) | `config/quickshell/skein/*.qml`, deployed to `~/.config/quickshell/skein/`, run as `skein-bar.service` |
| Themes | `themes/<name>/colors.toml` + `backgrounds/` + `preview.png`; user themes in `~/.config/skein/themes/` |
| Theme templates | `default/themed/*.tpl`, rendered into `~/.config/skein/current/theme/` |
| Toggles | flag files in `~/.local/state/skein/toggles/` (`skeinctl toggle ...`) |
| Hooks | `~/.config/skein/hooks/<name>` (theme-set, post-boot, ...) |
| Defaults | `~/.config/skein/defaults/agent`, `~/.local/state/skein/defaults/editor`, `xdg-settings` for the browser, `~/.config/xdg-terminals.list` |
| Migrations | `migrations/<timestamp>.sh`, run once by `skein-update` |

## The shell

The whole shell is one Quickshell config (`qs -c skein`). Talk to it over IPC:

```bash
qs -c skein ipc show                          # every target and function
qs -c skein ipc call bar panel audio          # open a bar panel: agents, audio, network, bluetooth, weather, calendar, display
qs -c skein ipc call themes open              # theme carousel
qs -c skein ipc call wallpapers open          # wallpaper carousel
qs -c skein ipc call notifications dismissAll
```

After editing a QML file, copy it to `~/.config/quickshell/skein/`; Quickshell reloads
on its own. A reload that fails to parse keeps the old shell running, so check
`journalctl --user -u skein-bar.service -n 20`. Text uses `Skein.pt(n)` and
`Skein.fontSize` so it follows the text size setting.

## Common jobs

- **Theme**: `skeinctl theme set <name>`, list with `skein-theme-list`. New themes only need a `colors.toml`.
- **Wallpaper**: `skein-theme-bg-next`, or `skein-theme-bg-set <image>`.
- **Defaults**: `skein-default-agent|browser|terminal|editor <name>`; with no argument they print the current one.
- **Brightness / scale / text size**: `skein-brightness-display`, `skein-hyprland-monitor-scaling <1-4>`, `skein-display-text-size <9-20>`.
- **Keybindings**: `default/hypr/bindings/*.lua`; the user's own go in `~/.config/hypr/bindings.lua`. Reload with `hyprctl reload`.
- **Diagnostics**: `skein-debug --print --no-sudo` writes a system report; crashes are handled by the `diagnose-crash` skill.

## Rules

- Read before you change, and keep changes minimal and reversible. Back up a user file before replacing it.
- Never run `sudo` yourself. When a step needs it, say so and give the exact command.
- Do not delete or reinstall packages the user did not ask about.
- Prefer the `skein-*` commands over editing state files by hand; they keep the shell, services and configs in sync.
- Do not send logs or system details to a third party without the user's explicit yes.
