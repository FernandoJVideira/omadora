import QtQuick
import Quickshell.Hyprland

// Display settings: click opens the display panel.
BarItem {
  id: root

  required property var barWindow

  text: Skein.glyph(0xf0379)
  onLeftClicked: panel.toggle()

  Connections {
    target: Skein

    function onPanelRequested(name) {
      if (name === "display" && (panel.open || root.barWindow.screen.name === Hyprland.focusedMonitor?.name)) {
        panel.toggle();
      }
    }
  }

  DisplayPanel {
    id: panel

    barWindow: root.barWindow
  }
}
