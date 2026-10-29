import QtQuick

// A titled card of settings rows separated by hairlines.
Column {
  id: root

  property string title: ""
  default property alias rows: list.data

  width: parent ? parent.width : 0
  spacing: 8

  Text {
    visible: root.title !== ""
    leftPadding: 4
    topPadding: 8
    text: root.title
    color: Qt.alpha(Skein.foreground, 0.55)
    font.family: Skein.fontFamily
    font.pointSize: Skein.fontSize - 0.5
    font.weight: Font.Medium
  }

  Rectangle {
    width: parent.width
    // One pixel short and clipped: hides the last row's divider, which would sit on the card's edge
    height: list.implicitHeight - 1
    radius: Skein.radiusInner
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
      border.color: Qt.alpha(Skein.foreground, 0.12)
    }
  }
}
