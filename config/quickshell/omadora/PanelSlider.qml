import QtQuick

// Horizontal slider for 0..1 values; emits moved() while dragging.
Item {
  id: root

  property real value: 0
  property real maximum: 1

  signal moved(real value)

  height: 20

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 4
    color: Qt.alpha(Omadora.foreground, 0.2)

    Rectangle {
      width: parent.width * Math.min(root.value, root.maximum) / root.maximum
      height: parent.height
      color: Omadora.accent
    }
  }

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    x: (root.width - width) * Math.min(root.value, root.maximum) / root.maximum
    width: 12
    height: 12
    color: Omadora.foreground
  }

  MouseArea {
    anchors.fill: parent
    onPressed: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / width)) * root.maximum)
    onPositionChanged: mouse => {
      if (pressed) {
        root.moved(Math.max(0, Math.min(1, mouse.x / width)) * root.maximum);
      }
    }
  }
}
