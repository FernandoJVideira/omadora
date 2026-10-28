import QtQuick

// A small rounded button for rows of controls.
Rectangle {
  id: button

  property string text: ""
  property bool enabled: true
  property bool highlighted: false

  signal clicked

  width: Math.max(Math.round(26 * Skein.textScale), label.implicitWidth + 16)
  height: Math.round(24 * Skein.textScale)
  radius: 6
  opacity: enabled ? 1 : 0.35
  color: highlighted ? Qt.alpha(Skein.accent, 0.4) : (area.containsMouse && enabled ? Qt.alpha(Skein.accent, 0.25) : Qt.alpha(Skein.foreground, 0.06))

  Behavior on color {
    ColorAnimation {
      duration: 100
    }
  }
  border.width: 1
  border.color: Qt.alpha(Skein.accent, highlighted ? 0.9 : 0.6)

  Text {
    id: label

    anchors.centerIn: parent
    text: button.text
    color: Skein.foreground
    font.family: Skein.fontFamily
    font.pointSize: Skein.fontSize - 0.5
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    enabled: button.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: button.clicked()
  }
}
