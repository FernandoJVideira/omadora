import QtQuick

// Base of every settings row: a label with an optional description on the left, the control on the right.
Item {
  id: root

  property string label: ""
  property string description: ""
  property bool dimmed: false
  default property alias control: slot.data
  // Something at the far left of the row, such as a drag handle
  property alias leading: leadSlot.data

  width: parent ? parent.width : 0
  implicitHeight: Math.max(Math.round(48 * Skein.textScale), texts.implicitHeight + 30, slot.height + 30)
  height: implicitHeight
  opacity: dimmed ? 0.5 : 1

  Column {
    id: texts

    anchors.left: leadSlot.right
    anchors.leftMargin: leadSlot.width > 0 ? 10 : 0
    anchors.right: slot.left
    anchors.rightMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Text {
      width: parent.width
      elide: Text.ElideRight
      text: root.label
      textFormat: Text.PlainText
      color: Skein.foreground
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize
    }

    Text {
      visible: root.description !== ""
      width: parent.width
      wrapMode: Text.WordWrap
      text: root.description
      textFormat: Text.PlainText
      color: Qt.alpha(Skein.foreground, 0.6)
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 1.5
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.leftMargin: 14
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    color: Qt.alpha(Skein.foreground, 0.08)
  }

  Item {
    id: leadSlot

    anchors.left: parent.left
    anchors.leftMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    width: childrenRect.width
    height: childrenRect.height
  }

  Item {
    id: slot

    anchors.right: parent.right
    anchors.rightMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    width: childrenRect.width
    height: childrenRect.height
  }
}
