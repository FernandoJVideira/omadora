import QtQuick

// Label with a checkbox; toggled(bool) fires with the requested state.
SettingsRow {
  id: root

  property bool checked: false
  property bool enabled: true

  signal toggled(bool value)

  dimmed: !enabled

  Rectangle {
    width: Math.round(16 * Skein.textScale)
    height: width
    radius: 4
    color: root.checked ? Skein.accent : "transparent"
    border.width: 1
    border.color: root.checked ? Skein.accent : Qt.alpha(Skein.foreground, 0.5)

    Text {
      anchors.centerIn: parent
      visible: root.checked
      text: "✓"
      color: Skein.background
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 1
      font.bold: true
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.enabled
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggled(!root.checked)
    }
  }
}
