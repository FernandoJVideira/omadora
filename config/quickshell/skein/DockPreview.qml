import QtQuick
import Quickshell

// A small picture of the dock for a set of settings (a preset), with the apps you keep in it.
Item {
  id: root

  // {position, iconSize, magnify, magnifySize, autoHide, showRunning, showIndicators, showTrash, showDownloads}
  property var settings: ({})

  readonly property string position: settings.position ?? "bottom"
  readonly property bool vertical: position !== "bottom"
  readonly property real unit: (settings.iconSize ?? 48) * 0.4
  readonly property real bigUnit: settings.magnify ? Math.max(unit, (settings.magnifySize ?? 72) * 0.4) : unit
  readonly property bool hides: settings.autoHide === true

  // Up to four of your pinned apps, then what else the dock would show
  readonly property var entries: {
    const list = [];
    const pinned = DockConfig.pinned.slice(0, 4);
    for (let i = 0; i < 4; i++) {
      list.push({
        kind: "app",
        id: pinned[i] ?? ""
      });
    }
    if (settings.showRunning) {
      list.push({
        kind: "divider"
      });
      list.push({
        kind: "app",
        id: "",
        running: true
      });
    }
    if (settings.showDownloads || settings.showTrash) {
      list.push({
        kind: "divider"
      });
    }
    if (settings.showDownloads) {
      list.push({
        kind: "folder",
        text: "↓"
      });
    }
    if (settings.showTrash) {
      list.push({
        kind: "folder",
        text: "▯"
      });
    }
    return list;
  }

  width: parent ? parent.width : 0
  height: 120

  // The "desktop" behind the dock
  Rectangle {
    anchors.fill: parent
    radius: 8
    color: Qt.alpha(Skein.accent, 0.18)
    clip: true

    Rectangle {
      anchors.centerIn: parent
      width: parent.width * 0.4
      height: parent.height * 0.4
      radius: 4
      color: Qt.alpha(Skein.foreground, 0.08)
    }

    Rectangle {
      id: dock

      readonly property int pad: 5

      opacity: root.hides ? 0.55 : 1
      radius: 8
      color: Qt.alpha(Skein.background, 0.85)
      border.width: 1
      border.color: Qt.alpha(Skein.foreground, 0.18)
      width: grid.width + 2 * pad
      height: grid.height + 2 * pad
      x: root.position === "left" ? 6 : (root.position === "right" ? parent.width - width - 6 : (parent.width - width) / 2)
      y: root.vertical ? (parent.height - height) / 2 : parent.height - height - 6

      Grid {
        id: grid

        x: dock.pad
        y: dock.pad
        spacing: 3
        flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
        rows: root.vertical ? root.entries.length : 1
        columns: root.vertical ? 1 : root.entries.length

        Repeater {
          model: root.entries

          Item {
            id: cell

            required property var modelData
            required property int index

            readonly property var entry: modelData.id !== "" ? (DesktopEntries.byId(modelData.id) ?? DesktopEntries.heuristicLookup(modelData.id)) : null
            // With magnification the second icon stands for the one under the pointer
            readonly property real size: modelData.kind === "app" && index === 1 ? root.bigUnit : root.unit

            width: modelData.kind === "divider" && !root.vertical ? 1 : (root.vertical ? root.bigUnit : size)
            height: modelData.kind === "divider" && root.vertical ? 1 : (root.vertical ? size : root.bigUnit)

            Rectangle {
              visible: cell.modelData.kind === "divider"
              anchors.fill: parent
              anchors.margins: root.vertical ? 0 : -0
              color: Qt.alpha(Skein.foreground, 0.3)
            }

            Rectangle {
              visible: cell.modelData.kind !== "divider"
              width: cell.size
              height: cell.size
              x: root.vertical ? (position === "right" ? cell.width - width : 0) : 0
              y: root.vertical ? 0 : cell.height - height
              radius: cell.size * 0.22
              color: cell.modelData.kind === "folder" ? Qt.alpha(Skein.foreground, 0.15) : Qt.alpha(Skein.accent, cell.modelData.running ? 0.4 : 0.65)

              Image {
                anchors.fill: parent
                anchors.margins: 1
                visible: status === Image.Ready
                source: cell.entry ? Quickshell.iconPath(cell.entry.icon, true) ?? "" : ""
                sourceSize: Qt.size(64, 64)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
              }

              Text {
                visible: cell.modelData.kind === "folder"
                anchors.centerIn: parent
                text: cell.modelData.text ?? ""
                color: Skein.foreground
                font.pointSize: Math.max(6, Skein.fontSize - 4)
              }
            }

            // Open apps carry a dot
            Rectangle {
              visible: root.settings.showIndicators === true && cell.modelData.kind === "app" && (cell.index === 0 || cell.index === 1 || cell.modelData.running === true)
              width: 3
              height: 3
              radius: 1.5
              color: Skein.foreground
              x: root.vertical ? (root.position === "right" ? cell.width + 1 : -4) : (cell.width - 3) / 2
              y: root.vertical ? (cell.height - 3) / 2 : cell.height + 0
            }
          }
        }
      }
    }

    Text {
      visible: root.hides
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 6
      text: "hides"
      color: Qt.alpha(Skein.foreground, 0.6)
      font.family: Skein.fontFamily
      font.pointSize: Math.max(6, Skein.fontSize - 4)
    }
  }
}
