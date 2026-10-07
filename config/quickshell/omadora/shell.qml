//@ pragma UseQApplication

// Omadora top bar, a Quickshell port of the Waybar config.
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

  // qs -c omadora ipc call bar <function> [args]
  IpcHandler {
    target: "bar"

    // Hide/show the bar (Waybar's SIGUSR1)
    function toggle(): void {
      root.barVisible = !root.barVisible;
    }

    // Re-run a script module: update, weather, idle, notification-silencing, screenrecording or all
    // (Waybar's SIGRTMIN+N)
    function refresh(module: string): void {
      Omadora.refreshRequested(module);
    }

    // Re-read the current theme colors
    function reloadTheme(): void {
      Omadora.reloadTheme();
    }
  }
}
