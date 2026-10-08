//@ pragma UseQApplication

// Omadora shell: top bar, launcher/menus, notifications, OSD and lock screen.
// Run with `qs -c omadora` (started by omadora-bar.service).

import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root

  property bool barVisible: true

  Variants {
    model: Quickshell.screens

    Bar {
      visible: root.barVisible
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

    // Hide/show the bar
    function toggle(): void {
      root.barVisible = !root.barVisible;
    }

    // Re-run a script module: update, weather, idle, notification-silencing, screenrecording or all
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
