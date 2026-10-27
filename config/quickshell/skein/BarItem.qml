import QtQuick

// One bar module: a label with click/scroll actions and a tooltip,
// styled like the Waybar modules it replaces. Hidden when text is empty.
MouseArea {
  id: root

  property string text: ""
  property string tooltip: ""
  property bool alert: false // red, like Waybar's .active/.error classes
  property bool dimmed: false // half opacity, like .stale/.empty
  property bool padded: false // text modules get side padding instead of a minimum width

  signal leftClicked
  signal rightClicked
  signal scrolled(int delta)

  visible: text !== ""
  width: visible ? Math.max(label.implicitWidth + (padded ? 2 * Skein.modulePadding : 0), Skein.minModuleWidth) : 0
  height: parent ? parent.height : Skein.barHeight
  hoverEnabled: true
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: mouse => mouse.button === Qt.RightButton ? rightClicked() : leftClicked()
  onWheel: wheel => scrolled(wheel.angleDelta.y)

  Text {
    id: label

    anchors.centerIn: parent
    text: root.text
    textFormat: Text.PlainText
    color: root.alert ? Skein.alert : Skein.foreground
    opacity: root.dimmed ? 0.5 : 1
    font.family: Skein.fontFamily
    font.pointSize: Skein.fontSize
  }

  Tooltip {
    target: root
    text: root.tooltip
    shown: root.containsMouse
  }
}
