import QtQuick
import Quickshell

// A row for an installed app: its icon and name on the left, the controls on the right.
Item {
  id: root

  property var entry: null
  property string fallbackName: ""
  default property alias control: slot.data

  width: parent ? parent.width : 0
  height: Math.round(46 * Skein.textScale)

  Image {
    id: icon

    anchors.left: parent.left
    anchors.leftMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    width: Math.round(26 * Skein.textScale)
    height: width
    source: root.entry ? Quickshell.iconPath(root.entry.icon, true) ?? "" : ""
    sourceSize: Qt.size(64, 64)
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    visible: status === Image.Ready
  }

  Rectangle {
    anchors.fill: icon
    visible: !icon.visible
    radius: Skein.radiusInner
    color: Qt.alpha(Skein.accent, 0.6)

    Text {
      anchors.centerIn: parent
      text: (root.entry?.name ?? root.fallbackName).charAt(0).toUpperCase()
      color: Skein.background
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 1
      font.bold: true
    }
  }

  Text {
    anchors.left: icon.right
    anchors.leftMargin: 10
    anchors.right: slot.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    elide: Text.ElideRight
    text: root.entry?.name ?? root.fallbackName
    textFormat: Text.PlainText
    color: Skein.foreground
    font.family: Skein.fontFamily
    font.pointSize: Skein.fontSize
  }

  Item {
    id: slot

    anchors.right: parent.right
    anchors.rightMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    width: childrenRect.width
    height: childrenRect.height
  }

  Rectangle {
    anchors.left: parent.left
    anchors.leftMargin: 14
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    color: Qt.alpha(Skein.foreground, 0.08)
  }
}
