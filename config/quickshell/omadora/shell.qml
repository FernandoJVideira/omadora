//@ pragma UseQApplication

// Omadora shell: top bar, launcher/menus, notifications, OSD and lock screen.
// Run with `qs -c omadora` (started by omadora-bar.service).

import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root

  property bool barVisible: true
  property bool waybarSelected: false // Waybar replaces the Quickshell bar when this flag file exists

  Process {
    command: ["test", "-f", `${Omadora.home}/.local/state/omadora/toggles/bar-waybar`]
    running: true
    onExited: code => root.waybarSelected = code === 0
  }

  Variants {
    model: Quickshell.screens

    Bar {
      visible: root.barVisible && !root.waybarSelected
    }
  }

  Picker {}

  ImageSwitcher {
    target: "themes"
    dataCommand: `${Omadora.omadoraPath}/libexec/omadora-themes-data`
    applyCommand: [`${Omadora.omadoraPath}/libexec/omadora-theme-set`]
  }

  ImageSwitcher {
    target: "wallpapers"
    dataCommand: `${Omadora.omadoraPath}/libexec/omadora-backgrounds-data`
    applyCommand: [`${Omadora.omadoraPath}/libexec/omadora-theme-bg-set`]
  }

  Notifications {}

  Osd {}

  Lock {}

  // qs -c omadora ipc call bar <function> [args]
  IpcHandler {
    target: "bar"

    // Hide/show the bar (Waybar's SIGUSR1)
    function toggle(): void {
      root.barVisible = !root.barVisible;
    }

    // Switch between this bar and Waybar
    function useWaybar(selected: bool): void {
      root.waybarSelected = selected;
    }

    // Re-run a script module: update, weather, idle, notification-silencing, screenrecording or all
    // (Waybar's SIGRTMIN+N)
    function refresh(module: string): void {
      Omadora.refreshRequested(module);
    }

    // Toggle a bar dropdown: agents, audio, network, bluetooth, weather, calendar or display
    function panel(name: string): void {
      Omadora.panelRequested(name);
    }

    // Re-read the current theme colors
    function reloadTheme(): void {
      Omadora.reloadTheme();
    }
  }
}
