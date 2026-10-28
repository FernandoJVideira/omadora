import QtQuick
import Quickshell.Hyprland

// The bell of the unified menu bar, with the number of notifications waiting; hidden in the classic layout.
BarItem {
  id: root

  required property var barWindow

  readonly property int count: Skein.notifications.filter(n => n.appName !== "Spotify").length

  text: Skein.controlCenter && Skein.notificationCenter ? `${Skein.glyph(Skein.silenced ? 0xf009b : 0xf009a)}${count > 0 ? ` ${count}` : ""}` : ""
  padded: count > 0
  alert: false
  tooltip: Skein.silenced ? "Do Not Disturb" : (count > 0 ? `${count} notification${count === 1 ? "" : "s"}` : "No notifications")
  onLeftClicked: panel.toggle()
  onRightClicked: Skein.silenced = !Skein.silenced

  Connections {
    target: Skein

    function onPanelRequested(name) {
      if (name === "notifications" && (panel.open || root.barWindow.screen.name === Hyprland.focusedMonitor?.name)) {
        panel.toggle();
      }
    }
  }

  NotificationCenterPanel {
    id: panel

    barWindow: root.barWindow
  }
}
