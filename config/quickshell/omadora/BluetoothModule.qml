import QtQuick
import Quickshell.Bluetooth

// Bluetooth adapter state; hidden when there is no controller.
BarItem {
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property int connections: adapter ? adapter.devices.values.filter(device => device.connected).length : 0

  text: {
    if (!adapter) {
      return "";
    }
    if (!adapter.enabled) {
      return Omadora.glyph(0xf00b2);
    }
    return Omadora.glyph(connections > 0 ? 0xf00b1 : 0xf294);
  }
  tooltip: `Devices connected: ${connections}`
  onLeftClicked: Omadora.run("omadora-exec omadora-launch-bluetooth")
}
