import QtQuick
import "MonitorLayout.js" as Layout

// Drag monitors next to each other; a drop emits every monitor's position.
Item {
  id: root

  property var displays: []
  property string dragName: ""
  property var dragPos: null // snapped {x, y} in logical pixels while dragging

  signal committed(var placements)

  readonly property var rects: Layout.logicalRects(displays)
  readonly property int margin: 12
  readonly property real pad: rects.reduce((m, r) => Math.max(m, r.w, r.h), 0) / 2
  readonly property real minX: rects.reduce((m, r) => Math.min(m, r.x), Infinity) - pad
  readonly property real minY: rects.reduce((m, r) => Math.min(m, r.y), Infinity) - pad
  readonly property real spanX: rects.reduce((m, r) => Math.max(m, r.x + r.w), -Infinity) + pad - minX
  readonly property real spanY: rects.reduce((m, r) => Math.max(m, r.y + r.h), -Infinity) + pad - minY
  readonly property real ratio: Math.max(0.0001, Math.min((canvas.width - 2 * margin) / Math.max(1, spanX), (canvas.height - 2 * margin) / Math.max(1, spanY)))
  readonly property real offsetX: (canvas.width - spanX * ratio) / 2
  readonly property real offsetY: (canvas.height - spanY * ratio) / 2

  width: parent ? parent.width : 0
  implicitHeight: canvas.height + hint.implicitHeight + 28
  height: implicitHeight

  Rectangle {
    id: canvas

    x: 14
    y: 14
    width: parent.width - 28
    height: Math.round(180 * Skein.textScale)
    radius: Skein.radiusInner
    color: Qt.alpha(Skein.foreground, 0.04)
    border.width: 1
    border.color: Qt.alpha(Skein.foreground, 0.08)
    clip: true

    Repeater {
      model: root.rects

      Rectangle {
        id: tile

        required property var modelData
        readonly property bool dragging: root.dragName === modelData.name
        readonly property var pos: dragging && root.dragPos ? root.dragPos : modelData
        readonly property var display: root.displays.find(d => d.name === modelData.name)

        x: root.offsetX + (pos.x - root.minX) * root.ratio
        y: root.offsetY + (pos.y - root.minY) * root.ratio
        width: modelData.w * root.ratio
        height: modelData.h * root.ratio
        radius: Skein.radiusInner
        color: Qt.alpha(Skein.accent, dragging ? 0.4 : 0.22)
        border.width: 1
        border.color: Qt.alpha(Skein.accent, dragging ? 1 : 0.6)
        z: dragging ? 1 : 0

        Column {
          anchors.centerIn: parent
          width: parent.width - 8
          spacing: 1

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: `${tile.display?.main ? "● " : ""}${tile.modelData.name}`
            textFormat: Text.PlainText
            color: Skein.foreground
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize - 0.5
            font.bold: true
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: tile.display ? `${tile.display.width}×${tile.display.height}` : ""
            color: Qt.alpha(Skein.foreground, 0.6)
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize - 1.5
          }
        }
      }
    }

    MouseArea {
      id: drag

      property real grabX: 0
      property real grabY: 0

      anchors.fill: parent
      preventStealing: root.dragName !== "" // keeps the page Flickable from taking the drag
      cursorShape: root.dragName !== "" ? Qt.ClosedHandCursor : Qt.OpenHandCursor

      function logicalX(px: real): real {
        return (px - root.offsetX) / root.ratio + root.minX;
      }

      function logicalY(py: real): real {
        return (py - root.offsetY) / root.ratio + root.minY;
      }

      function update(mouse: var): void {
        root.dragPos = Layout.snap(root.rects, root.dragName, logicalX(mouse.x) - grabX, logicalY(mouse.y) - grabY, 12 / root.ratio);
      }

      onPressed: mouse => {
        const lx = logicalX(mouse.x);
        const ly = logicalY(mouse.y);
        const hit = root.rects.find(r => lx >= r.x && lx < r.x + r.w && ly >= r.y && ly < r.y + r.h);
        if (!hit) {
          return;
        }
        grabX = lx - hit.x;
        grabY = ly - hit.y;
        root.dragName = hit.name;
        root.dragPos = {
          x: hit.x,
          y: hit.y
        };
      }
      onPositionChanged: mouse => {
        if (root.dragName !== "") {
          update(mouse);
        }
      }
      onReleased: {
        const name = root.dragName;
        const pos = root.dragPos;
        const rect = root.rects.find(r => r.name === name);
        root.dragName = "";
        root.dragPos = null;
        if (rect && pos && (pos.x !== rect.x || pos.y !== rect.y)) {
          root.committed(Layout.placements(root.rects, name, pos));
        }
      }
      onCanceled: {
        root.dragName = "";
        root.dragPos = null;
      }
    }
  }

  Text {
    id: hint

    anchors.left: canvas.left
    anchors.top: canvas.bottom
    anchors.topMargin: 8
    anchors.right: canvas.right
    wrapMode: Text.WordWrap
    text: "Drag a display next to another. It applies immediately."
    color: Qt.alpha(Skein.foreground, 0.6)
    font.family: Skein.fontFamily
    font.pointSize: Skein.fontSize - 1.5
  }
}
