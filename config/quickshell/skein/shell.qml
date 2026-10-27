//@ pragma UseQApplication

// Skein shell: top bar, launcher/menus, notifications, OSD and lock screen.
// Run with `qs -c skein` (started by skein-bar.service).

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
    dataCommand: `${Skein.skeinPath}/libexec/skein-themes-data`
    applyCommand: [`${Skein.skeinPath}/libexec/skein-theme-set`]
  }

  ImageSwitcher {
    target: "wallpapers"
    dataCommand: `${Skein.skeinPath}/libexec/skein-backgrounds-data`
    applyCommand: [`${Skein.skeinPath}/libexec/skein-theme-bg-set`]
  }

  Notifications {}

  Osd {}

  Lock {}

  // qs -c skein ipc call bar <function> [args]
  IpcHandler {
    target: "bar"

    // Hide/show the bar
    function toggle(): void {
      root.barVisible = !root.barVisible;
    }

    // Re-run a script module: update, weather, idle, notification-silencing, screenrecording or all
    function refresh(module: string): void {
      Skein.refreshRequested(module);
    }

    // Toggle a bar dropdown: agents, audio, network, bluetooth, weather, calendar or display
    function panel(name: string): void {
      Skein.panelRequested(name);
    }

    // Re-read the current theme colors
    function reloadTheme(): void {
      Skein.reloadTheme();
    }
  }
}
