import QtQuick

// Label with a push button on the right.
SettingsRow {
  id: root

  property string buttonText: ""
  property bool enabled: true

  signal clicked

  dimmed: !enabled

  Rectangle {
    width: btnText.implicitWidth + 24
    height: Math.round(24 * Skein.textScale)
    radius: height / 2
    color: mouse.containsMouse ? Qt.alpha(Skein.foreground, 0.14) : Qt.alpha(Skein.foreground, 0.07)

    Behavior on color {
      ColorAnimation {
        duration: 100
      }
    }
    border.width: 1
    border.color: Qt.alpha(Skein.foreground, 0.16)

    Text {
      id: btnText

      anchors.centerIn: parent
      text: root.buttonText
      color: Skein.foreground
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 0.5
    }

    MouseArea {
      id: mouse

      anchors.fill: parent
      hoverEnabled: true
      enabled: root.enabled
      cursorShape: Qt.PointingHandCursor
      onClicked: root.clicked()
    }
  }
}
