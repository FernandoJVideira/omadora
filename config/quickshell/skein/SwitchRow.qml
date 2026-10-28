import QtQuick

// Label with a toggle switch; toggled(bool) fires with the requested state, the owner updates `checked`.
SettingsRow {
  id: root

  property bool checked: false
  property bool enabled: true

  signal toggled(bool value)

  dimmed: !enabled

  Rectangle {
    width: Math.round(36 * Skein.textScale)
    height: Math.round(20 * Skein.textScale)
    radius: height / 2
    color: root.checked ? Skein.accent : Qt.alpha(Skein.foreground, 0.22)

    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }

    Rectangle {
      width: parent.height - 4
      height: width
      radius: width / 2
      y: 2
      x: root.checked ? parent.width - width - 2 : 2
      color: "white"

      Behavior on x {
        NumberAnimation {
          duration: 120
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.enabled
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggled(!root.checked)
    }
  }
}
