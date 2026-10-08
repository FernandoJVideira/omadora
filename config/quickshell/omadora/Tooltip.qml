import QtQuick
import Quickshell
import "Markup.js" as Markup

// Hover tooltip shown below a bar item.
PopupWindow {
  id: root

  required property Item target
  property string text: ""
  property bool shown: false

  anchor.item: target
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  anchor.margins.top: 4

  visible: shown && text !== ""
  implicitWidth: body.implicitWidth + 20
  implicitHeight: body.implicitHeight + 12
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    color: Omadora.background
    border.width: 1
    border.color: Qt.alpha(Omadora.foreground, 0.3)

    Text {
      id: body

      anchors.centerIn: parent
      text: Markup.toHtml(root.text)
      textFormat: Text.RichText
      color: Omadora.foreground
      font.family: Omadora.fontFamily
      font.pointSize: Omadora.fontSize
    }
  }
}
