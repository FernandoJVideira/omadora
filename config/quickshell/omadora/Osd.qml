import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Volume, brightness and microphone popup (replaces SwayOSD).
// qs -c omadora ipc call osd display <glyph> <label> <value 0-100, or -1 for none>
Scope {
  id: root

  property string glyph: ""
  property string label: ""
  property real value: -1
  property bool shown: false

  IpcHandler {
    target: "osd"

    function display(glyph: string, label: string, value: real): void {
      root.glyph = glyph;
      root.label = label;
      root.value = value;
      root.shown = true;
      hide.restart();
    }
  }

  Timer {
    id: hide

    interval: 1500
    onTriggered: root.shown = false
  }

  PanelWindow {
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: root.shown
    anchors.bottom: true
    margins.bottom: 80
    implicitWidth: 300
    implicitHeight: 56
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "omadora-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    Rectangle {
      anchors.fill: parent
      color: Qt.alpha(Omadora.background, 0.95)
      border.width: 1
      border.color: Qt.alpha(Omadora.accent, 0.5)

      Row {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.glyph
          color: Omadora.accent
          font.family: Omadora.fontFamily
          font.pointSize: Omadora.pt(18)
        }

        Item {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 30 - 12
          height: 28

          Text {
            visible: root.value < 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: Omadora.foreground
            font.family: Omadora.fontFamily
            font.pointSize: Omadora.pt(11)
          }

          Column {
            visible: root.value >= 0
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Text {
              text: `${root.label}  ${Math.round(root.value)}%`
              color: Omadora.foreground
              font.family: Omadora.fontFamily
              font.pointSize: Omadora.pt(10)
            }

            Rectangle {
              width: parent.width
              height: 4
              color: Qt.alpha(Omadora.foreground, 0.2)

              Rectangle {
                width: parent.width * Math.min(root.value, 100) / 100
                height: parent.height
                color: Omadora.accent
              }
            }
          }
        }
      }
    }
  }
}
