import QtQuick

// Slider with a fixed number of stops, drawn as segments; released() fires with the chosen stop.
Item {
  id: root

  property int stops: 2
  property int index: 0 // selected stop
  property bool dragging: false
  property int liveIndex: index

  signal released(int index)

  height: 24

  function stopAt(x: real): int {
    return Math.max(0, Math.min(root.stops - 1, Math.round(x / width * (root.stops - 1))));
  }

  Row {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    spacing: 3

    Repeater {
      model: root.stops - 1

      Rectangle {
        required property int index

        width: (parent.width - (root.stops - 2) * 3) / (root.stops - 1)
        height: 4
        color: index < (root.dragging ? root.liveIndex : root.index) ? Omadora.foreground : Qt.alpha(Omadora.foreground, 0.2)
      }
    }
  }

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    x: (root.width - width) * (root.dragging ? root.liveIndex : root.index) / (root.stops - 1)
    width: 12
    height: 14
    color: Omadora.foreground
  }

  MouseArea {
    anchors.fill: parent
    onPressed: mouse => {
      root.dragging = true;
      root.liveIndex = root.stopAt(mouse.x);
    }
    onPositionChanged: mouse => {
      if (pressed) {
        root.liveIndex = root.stopAt(mouse.x);
      }
    }
    onReleased: {
      root.dragging = false;
      root.released(root.liveIndex);
    }
  }
}
