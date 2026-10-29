import QtQuick
import Quickshell.Bluetooth

// Settings > Bluetooth: power switch, scanning and paired or nearby devices.
SettingsPage {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var devices: {
    const list = adapter ? adapter.devices.values.filter(device => device.name !== "" && device.name !== device.address.replace(/:/g, "-")) : [];
    return list.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name));
  }
  property var pairing: null

  Connections {
    target: root.pairing

    function onPairedChanged(): void {
      if (root.pairing?.paired) {
        root.pairing.connect();
        root.pairing = null;
      }
    }
  }

  SettingsSection {
    title: "Bluetooth"

    SwitchRow {
      label: "Bluetooth"
      description: root.adapter === null ? "No Bluetooth adapter" : ""
      checked: root.adapter?.enabled ?? false
      enabled: root.adapter !== null
      onToggled: value => root.adapter.enabled = value
    }

    SwitchRow {
      label: "Scan for devices"
      checked: root.adapter?.discovering ?? false
      enabled: root.adapter?.enabled ?? false
      onToggled: value => root.adapter.discovering = value
    }
  }

  SettingsSection {
    title: "Devices"
    visible: root.adapter?.enabled ?? false

    SettingsRow {
      visible: root.devices.length === 0
      label: "No devices found"
      description: root.adapter?.discovering ? "Looking for nearby devices…" : "Turn on Scan for devices to look for new ones"
    }

    Repeater {
      model: root.devices

      SettingsRow {
        required property var modelData

        label: modelData.name
        description: modelData.connected ? (modelData.batteryAvailable ? `Connected · ${Math.round(modelData.battery * 100)}%` : "Connected") : (modelData.paired ? "Paired" : "")

        Row {
          spacing: 6

          Rectangle {
            visible: modelData.paired
            width: forgetText.implicitWidth + 24
            height: Math.round(24 * Skein.textScale)
            radius: Skein.radiusInner
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Skein.foreground, 0.3)

            Text {
              id: forgetText

              anchors.centerIn: parent
              text: "Forget"
              color: Skein.foreground
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize - 0.5
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: modelData.forget()
            }
          }

          Rectangle {
            width: actionText.implicitWidth + 24
            height: Math.round(24 * Skein.textScale)
            radius: Skein.radiusInner
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Skein.accent, 0.7)

            Text {
              id: actionText

              anchors.centerIn: parent
              text: modelData.connected ? "Disconnect" : (modelData.paired ? "Connect" : "Pair")
              color: Skein.foreground
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize - 0.5
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (modelData.connected) {
                  modelData.disconnect();
                } else if (modelData.paired) {
                  modelData.connect();
                } else {
                  root.pairing = modelData;
                  modelData.pair();
                }
              }
            }
          }
        }
      }
    }
  }
}
