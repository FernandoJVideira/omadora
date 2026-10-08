import QtQuick
import Quickshell.Hyprland

// Display settings: click opens the display panel.
BarItem {
  id: root

  required property var barWindow

  text: Omadora.glyph(0xf0379)
  onLeftClicked: panel.toggle()

  Connections {
    target: Omadora

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
