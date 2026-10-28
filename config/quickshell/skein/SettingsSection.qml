import QtQuick

// A titled card of settings rows separated by hairlines.
Column {
  id: root

  property string title: ""
  default property alias rows: list.data

  width: parent ? parent.width : 0
  spacing: 6

  Text {
    visible: root.title !== ""
    leftPadding: 4
    topPadding: 8
    text: root.title.toUpperCase()
    color: Qt.alpha(Skein.foreground, 0.6)
    font.family: Skein.fontFamily
    font.pointSize: Skein.fontSize - 1.5
    font.bold: true
    font.letterSpacing: 0.6
  }

  Rectangle {
    width: parent.width
    height: list.implicitHeight
    radius: 8
    color: Qt.alpha(Skein.foreground, 0.05)
    clip: true

    Column {
      id: list

      width: parent.width
    }

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      color: "transparent"
      border.width: 1
      border.color: Qt.alpha(Skein.accent, 0.3)
    }
  }
}
