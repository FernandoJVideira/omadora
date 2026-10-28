import QtQuick

// A small rounded button for rows of controls.
Rectangle {
  id: button

  property string text: ""
  property bool enabled: true
  property bool highlighted: false

  signal clicked

  width: Math.max(Math.round(30 * Skein.textScale), label.implicitWidth + 24)
  height: Math.round(26 * Skein.textScale)
  radius: height / 2
  opacity: enabled ? 1 : 0.35
  color: highlighted ? Qt.alpha(Skein.accent, 0.9) : (area.containsMouse && enabled ? Qt.alpha(Skein.foreground, 0.14) : Qt.alpha(Skein.foreground, 0.07))

  Behavior on color {
    ColorAnimation {
      duration: 100
    }
  }
  border.width: 1
  border.color: highlighted ? Qt.alpha(Skein.accent, 0.9) : Qt.alpha(Skein.foreground, 0.16)

  Text {
    id: label

    anchors.centerIn: parent
    text: button.text
    color: button.highlighted ? Skein.background : Skein.foreground
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
