import QtQuick
import Quickshell.Bluetooth

// Bluetooth power, scanning and devices: pair, connect, disconnect, forget.
Panel {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  property var pairing: null // device we asked to pair, to connect it once paired
  property int sortTick: 0 // re-sort the list each time the panel opens

  readonly property var devices: {
    sortTick;
    const list = adapter ? adapter.devices.values.filter(device => device.name !== "" && device.name !== device.address.replace(/:/g, "-")) : [];
    return list.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name));
  }

  function status(device: var): string {
    if (device.state === BluetoothDeviceState.Connecting) {
      return "connecting…";
    }
    if (device.pairing) {
      return "pairing…";
    }
    if (device.connected) {
      return device.batteryAvailable ? `${Math.round(device.battery * 100)}%` : "connected";
    }
    return device.paired ? "paired" : "";
  }

  function glyph(device: var): string {
    if (device.connected) {
      return Omadora.glyph(0xf00b1);
    }
    return Omadora.glyph(0xf00af);
  }

  function activate(device: var): void {
    if (device.connected) {
      device.disconnect();
    } else if (device.paired) {
      device.connect();
    } else {
      root.pairing = device;
      device.pair();
    }
  }

  onOpenChanged: {
    sortTick++;
    if (adapter && adapter.enabled) {
      adapter.discovering = open;
    }
  }

  PanelHeading {
    text: "Bluetooth"
  }

  PanelRow {
    visible: root.adapter !== null
    glyph: root.adapter?.enabled ? Omadora.glyph(0xf00b1) : Omadora.glyph(0xf00b2)
    text: root.adapter?.enabled ? "Bluetooth on" : "Bluetooth off"
    highlighted: root.adapter?.enabled ?? false
    onClicked: {
      if (root.adapter) {
        root.adapter.enabled = !root.adapter.enabled;
        if (root.adapter.enabled) {
          root.adapter.discovering = root.open;
        }
      }
    }
  }

  Text {
    visible: root.adapter === null
    text: "No Bluetooth adapter"
    color: Qt.alpha(Omadora.foreground, 0.6)
    font.family: Omadora.fontFamily
    font.pointSize: Omadora.fontSize
  }

  PanelHeading {
    visible: root.adapter?.enabled ?? false
    text: root.adapter?.discovering ? "Devices (scanning…)" : "Devices"
  }

  Flickable {
    visible: root.adapter?.enabled ?? false
    width: parent.width
    height: Math.min(list.implicitHeight, 280)
    contentHeight: list.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: list

      width: parent.width

      Repeater {
        model: root.devices

        Column {
          id: entry

          required property var modelData

          width: list.width

          PanelRow {
            glyph: root.glyph(entry.modelData)
            text: entry.modelData.name
            trailing: root.status(entry.modelData)
            highlighted: entry.modelData.connected
            onClicked: root.activate(entry.modelData)
          }

          PanelRow {
            visible: entry.modelData.paired && !entry.modelData.connected
            glyph: Omadora.glyph(0xf1f8)
            text: "Forget this device"
            dimmed: true
            height: visible ? 24 : 0
            onClicked: entry.modelData.forget()
          }

          // Trust and connect right after our own pairing succeeds
          Connections {
            target: entry.modelData

            function onPairedChanged() {
              if (entry.modelData.paired && root.pairing === entry.modelData) {
                entry.modelData.trusted = true;
                entry.modelData.connect();
                root.pairing = null;
              }
            }
          }
        }
      }
    }
  }

  Text {
    visible: (root.adapter?.enabled ?? false) && root.devices.length === 0
    text: "No devices found"
    color: Qt.alpha(Omadora.foreground, 0.6)
    font.family: Omadora.fontFamily
    font.pointSize: Omadora.fontSize
  }
}
