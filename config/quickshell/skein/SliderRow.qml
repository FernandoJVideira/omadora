import QtQuick

// Label with a value readout and a 0..maximum slider underneath; moved(v) fires while dragging.
Item {
  id: root

  property string label: ""
  property string valueText: ""
  property real value: 0
  property real maximum: 1

  signal moved(real value)

  width: parent ? parent.width : 0
  height: Math.round(70 * Skein.textScale)

  // hairline under the row, like the other settings rows
  Rectangle {
    anchors.left: parent.left
    anchors.leftMargin: 14
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    color: Qt.alpha(Skein.foreground, 0.08)
  }

  Text {
    anchors.left: parent.left
    anchors.leftMargin: 14
    anchors.top: parent.top
    anchors.topMargin: 13
    text: root.label
    color: Skein.foreground
    font.family: Skein.fontFamily
    font.pointSize: Skein.fontSize
  }

  Text {
    anchors.right: parent.right
    anchors.rightMargin: 14
    anchors.top: parent.top
    anchors.topMargin: 13
    text: root.valueText
    color: Qt.alpha(Skein.foreground, 0.6)
    font.family: Skein.fontFamily
    font.pointSize: Skein.fontSize - 1
  }

  PanelSlider {
    anchors.left: parent.left
    anchors.leftMargin: 14
    anchors.right: parent.right
    anchors.rightMargin: 14
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 13
    value: root.value
    maximum: root.maximum
    onMoved: v => root.moved(v)
  }
}
