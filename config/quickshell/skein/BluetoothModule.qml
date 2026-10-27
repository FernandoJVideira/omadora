import QtQuick
import Quickshell.Bluetooth
import Quickshell.Hyprland

// Bluetooth adapter state; hidden when there is no controller.
BarItem {
  id: root

  required property var barWindow
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property int connections: adapter ? adapter.devices.values.filter(device => device.connected).length : 0

  text: {
    if (!adapter) {
      return "";
    }
    if (!adapter.enabled) {
      return Skein.glyph(0xf00b2);
    }
    return Skein.glyph(connections > 0 ? 0xf00b1 : 0xf294);
  }
  tooltip: `Devices connected: ${connections}`
  onLeftClicked: panel.toggle()

  Connections {
    target: Skein

    function onPanelRequested(name) {
      if (name === "bluetooth" && (panel.open || root.barWindow.screen.name === Hyprland.focusedMonitor?.name)) {
        panel.toggle();
      }
    }
  }

  BluetoothPanel {
    id: panel

    barWindow: root.barWindow
  }
}
