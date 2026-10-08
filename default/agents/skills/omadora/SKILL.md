---
name: omadora
description: >
  Work on this machine's Omadora desktop: a Fedora/Nobara port of Omarchy built on
  Hyprland (Lua config) and a Quickshell shell. Use for anything about the desktop:
  the top bar and its panels, notifications, launcher and menus, lock screen, themes,
  wallpapers, keybindings, monitors, defaults (agent, browser, terminal, editor),
  updates, toggles, or changing how Omadora behaves. Triggers: omadora, omactl,
  quickshell, qs, hyprland config, bar, theme, wallpaper, keybind, "set my default".
---

# Omadora

Omadora lives in `~/.local/share/omadora` (`$OMADORA_PATH`, a git repo). Everything
you may change for the user goes into their config, not the repo, unless they are
developing Omadora itself.

## Where things are

| What | Where |
|---|---|
| Commands | `libexec/omadora-*`, driven by `omactl <group> <command>` (`omactl` lists them) |
| Hyprland config | `~/.config/hypr/*.lua` (user) over `default/hypr/*.lua` (Omadora's defaults) |
| Shell (bar, panels, notifications, OSD, lock, launcher, switchers) | `config/quickshell/omadora/*.qml`, deployed to `~/.config/quickshell/omadora/`, run as `omadora-bar.service` |
| Themes | `themes/<name>/colors.toml` + `backgrounds/` + `preview.png`; user themes in `~/.config/omadora/themes/` |
| Theme templates | `default/themed/*.tpl`, rendered into `~/.config/omadora/current/theme/` |
| Toggles | flag files in `~/.local/state/omadora/toggles/` (`omactl toggle ...`) |
| Hooks | `~/.config/omadora/hooks/<name>` (theme-set, post-boot, ...) |
| Defaults | `~/.config/omadora/defaults/agent`, `~/.local/state/omadora/defaults/editor`, `xdg-settings` for the browser, `~/.config/xdg-terminals.list` |
| Migrations | `migrations/<timestamp>.sh`, run once by `omadora-update` |

## The shell

The whole shell is one Quickshell config (`qs -c omadora`). Talk to it over IPC:

```bash
qs -c omadora ipc show                          # every target and function
qs -c omadora ipc call bar panel audio          # open a bar panel: agents, audio, network, bluetooth, weather, calendar, display
qs -c omadora ipc call themes open              # theme carousel
qs -c omadora ipc call wallpapers open          # wallpaper carousel
qs -c omadora ipc call notifications dismissAll
```

After editing a QML file, copy it to `~/.config/quickshell/omadora/`; Quickshell reloads
on its own. A reload that fails to parse keeps the old shell running, so check
`journalctl --user -u omadora-bar.service -n 20`. Text uses `Omadora.pt(n)` and
`Omadora.fontSize` so it follows the text size setting.

## Common jobs

- **Theme**: `omactl theme set <name>`, list with `omadora-theme-list`. New themes only need a `colors.toml`.
- **Wallpaper**: `omadora-theme-bg-next`, or `omadora-theme-bg-set <image>`.
- **Defaults**: `omadora-default-agent|browser|terminal|editor <name>`; with no argument they print the current one.
- **Brightness / scale / text size**: `omadora-brightness-display`, `omadora-hyprland-monitor-scaling <1-4>`, `omadora-display-text-size <9-20>`.
- **Keybindings**: `default/hypr/bindings/*.lua`; the user's own go in `~/.config/hypr/bindings.lua`. Reload with `hyprctl reload`.
- **Diagnostics**: `omadora-debug --print --no-sudo` writes a system report; crashes are handled by the `diagnose-crash` skill.

## Rules

- Read before you change, and keep changes minimal and reversible. Back up a user file before replacing it.
- Never run `sudo` yourself. When a step needs it, say so and give the exact command.
- Do not delete or reinstall packages the user did not ask about.
- Prefer the `omadora-*` commands over editing state files by hand; they keep the shell, services and configs in sync.
- Do not send logs or system details to a third party without the user's explicit yes.
