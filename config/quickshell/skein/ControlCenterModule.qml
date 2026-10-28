import QtQuick
import Quickshell.Hyprland

// The Control Center button of the unified menu bar; hidden in the classic layout.
BarItem {
  id: root

  required property var barWindow

  text: Skein.controlCenter ? Skein.glyph(0xf0521) : ""
  tooltip: "Control Center"
  onLeftClicked: panel.toggle()
  onRightClicked: Skein.run("skein-exec qs -c skein ipc call settings page menubar")

  Connections {
    target: Skein

    function onPanelRequested(name) {
      if (name === "controlcenter" && (panel.open || root.barWindow.screen.name === Hyprland.focusedMonitor?.name)) {
        panel.toggle();
      }
    }
  }

  ControlCenterPanel {
    id: panel

    barWindow: root.barWindow
  }
}
