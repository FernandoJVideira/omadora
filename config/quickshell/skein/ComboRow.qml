import QtQuick

// Label with the current choice; clicking it lists `options` ({label, value}) underneath.
// chosen(value) fires with the picked option's value.
Column {
  id: root

  property string label: ""
  property string description: ""
  property var options: []
  property string current: ""
  property bool open: false

  readonly property string currentLabel: options.find(o => o.value === current)?.label ?? current

  signal chosen(string value)

  width: parent ? parent.width : 0

  SettingsRow {
    label: root.label
    description: root.description

    Rectangle {
      width: Math.max(Math.round(120 * Skein.textScale), currentText.implicitWidth + 36)
      height: Math.round(24 * Skein.textScale)
      radius: 6
      color: head.containsMouse || root.open ? Qt.alpha(Skein.accent, 0.25) : Qt.alpha(Skein.foreground, 0.06)

      Behavior on color {
        ColorAnimation {
          duration: 100
        }
      }
      border.width: 1
      border.color: Qt.alpha(Skein.accent, 0.6)

      Text {
        id: currentText

        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentLabel
        color: Skein.foreground
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize - 0.5
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.open ? "▴" : "▾"
        color: Qt.alpha(Skein.foreground, 0.7)
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize - 1
      }

      MouseArea {
        id: head

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.open = true;
          Skein.dropdownRequested(root, head.parent, root.options, root.current);
        }
      }
    }
  }
}
