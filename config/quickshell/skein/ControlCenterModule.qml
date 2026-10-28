import QtQuick
import Quickshell.Hyprland

// The Control Center button of the unified menu bar. In the classic layout it is the quick way in:
// one click switches to the Control Center menu bar (the panel's "Classic bar" button switches back).
BarItem {
  id: root

  required property var barWindow

  text: Skein.glyph(0xf0521)
  tooltip: Skein.controlCenter ? "Control Center" : "Switch to the Control Center"
  onLeftClicked: {
    if (Skein.controlCenter) {
      panel.toggle();
    } else {
      Skein.setBar("controlCenter", true);
    }
  }
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
