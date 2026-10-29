import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// The screen-share picker, shown when an app asks to share the screen. It is opened by
// skein-share-picker (the portal's custom picker), which captures the previews and waits on a FIFO
// for the choice: "<remember 0|1><TAB><screen:NAME | window:HANDLE | region>", or nothing for cancel.
Scope {
  id: root

  property bool active: false
  property string outFile: ""
  property var outputs: []
  property var windows: []
  property string tab: "monitors"
  property int selected: 0
  property bool remember: false

  readonly property var tabs: [
    {
      id: "monitors",
      label: "Monitors"
    },
    {
      id: "windows",
      label: "Windows"
    },
    {
      id: "region",
      label: "Region"
    }
  ]
  readonly property var items: tab === "monitors" ? outputs : (tab === "windows" ? windows : [])
  readonly property int columns: 3

  function reply(text: string): void {
    if (root.outFile !== "") {
      Quickshell.execDetached(["bash", "-c", 'printf %s "$1" > "$2"', "_", text, root.outFile]);
      root.outFile = "";
    }
  }

  function close(): void {
    root.reply("");
    root.active = false;
  }

  function share(): void {
    let choice = "";
    if (root.tab === "region") {
      choice = "region";
    } else {
      const item = root.items[root.selected];
      if (!item) {
        return;
      }
      choice = root.tab === "monitors" ? `screen:${item.name}` : `window:${item.handle}`;
    }
    root.reply(`${root.remember ? 1 : 0}\t${choice}`);
    root.active = false;
  }

  function setTab(id: string): void {
    root.tab = id;
    root.selected = 0;
  }

  function move(delta: int): void {
    if (root.items.length > 0) {
      root.selected = Math.max(0, Math.min(root.items.length - 1, root.selected + delta));
    }
  }

  function iconFor(windowClass: string): string {
    const entry = DesktopEntries.heuristicLookup(windowClass);
    return entry ? (Quickshell.iconPath(entry.icon, true) ?? "") : "";
  }

  FileView {
    id: dataView

    blockLoading: true
    printErrors: false
  }

  IpcHandler {
    target: "sharepicker"

    function open(dataFile: string, outFile: string): void {
      if (root.active) {
        root.reply("");
      }
      dataView.path = "";
      dataView.path = dataFile;
      try {
        const data = JSON.parse(dataView.text());
        root.outputs = data.outputs ?? [];
        root.windows = data.windows ?? [];
      } catch (e) {
        root.outputs = [];
        root.windows = [];
      }
      root.outFile = outFile;
      root.tab = "monitors";
      root.selected = 0;
      root.remember = false;
      root.active = true;
    }

    function close(): void {
      if (root.active) {
        root.close();
      }
    }

    function isOpen(): bool {
      return root.active;
    }

    // Switch to monitors, windows or region while it is open (handy for testing from a terminal)
    function tab(name: string): void {
      if (root.active && root.tabs.some(t => t.id === name)) {
        root.setTab(name);
      }
    }
  }

  PanelWindow {
    id: window

    visible: root.active
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "skein-share-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
      if (visible) {
        card.forceActiveFocus();
        cardFade.restart();
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }

    Rectangle {
      id: card

      anchors.centerIn: parent
      width: Math.min(Math.round(940 * Skein.textScale), parent.width - 80)
      height: Math.min(Math.round(640 * Skein.textScale), parent.height - 80)
      radius: 26
      color: Qt.alpha(Skein.background, Skein.glass ? 0.6 : 0.97)
      border.width: 1
      border.color: Qt.alpha(Skein.foreground, 0.12)
      focus: true


      NumberAnimation on opacity {
        id: cardFade

        running: false
        from: 0
        to: 1
        duration: 140
        easing.type: Easing.OutCubic
      }

      Keys.onEscapePressed: root.close()
      Keys.onReturnPressed: root.share()
      Keys.onEnterPressed: root.share()
      Keys.onLeftPressed: root.move(-1)
      Keys.onRightPressed: root.move(1)
      Keys.onUpPressed: root.move(-root.columns)
      Keys.onDownPressed: root.move(root.columns)
      Keys.onTabPressed: root.setTab(root.tabs[(root.tabs.findIndex(t => t.id === root.tab) + 1) % root.tabs.length].id)

      MouseArea {
        anchors.fill: parent
      }

      Column {
        id: header

        x: 28
        y: 24
        width: parent.width - 56
        spacing: 6

        Text {
          text: "Share your screen"
          color: Skein.foreground
          font.family: Skein.fontFamily
          font.pointSize: Skein.fontSize + 5
          font.weight: Font.DemiBold
        }

        Text {
          text: "Choose a monitor, a window or an area to share."
          color: Qt.alpha(Skein.foreground, 0.55)
          font.family: Skein.fontFamily
          font.pointSize: Skein.fontSize
        }
      }

      // Monitors / Windows / Region
      Rectangle {
        id: tabBar

        anchors.top: header.bottom
        anchors.topMargin: 18
        x: 28
        width: tabRow.implicitWidth + 8
        height: 38
        radius: 16
        color: Qt.alpha(Skein.foreground, 0.06)
        border.width: 1
        border.color: Qt.alpha(Skein.foreground, 0.12)

        Row {
          id: tabRow

          x: 4
          y: 4
          spacing: 2

          Repeater {
            model: root.tabs

            Rectangle {
              id: tabButton

              required property var modelData

              readonly property bool current: root.tab === modelData.id

              width: tabLabel.implicitWidth + 36
              height: 30
              radius: height / 2
              color: current ? Qt.alpha(Skein.accent, 0.9) : (tabMouse.containsMouse ? Qt.alpha(Skein.foreground, 0.08) : "transparent")

              Text {
                id: tabLabel

                anchors.centerIn: parent
                text: tabButton.modelData.label
                color: tabButton.current ? Skein.background : Skein.foreground
                font.family: Skein.fontFamily
                font.pointSize: Skein.fontSize
              }

              MouseArea {
                id: tabMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setTab(tabButton.modelData.id)
              }
            }
          }
        }
      }

      // The things to pick from
      Flickable {
        id: grid

        anchors.top: tabBar.bottom
        anchors.topMargin: 16
        anchors.bottom: footer.top
        anchors.bottomMargin: 12
        x: 28
        width: parent.width - 56
        contentHeight: tiles.implicitHeight + 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Flow {
          id: tiles

          readonly property real tileWidth: (grid.width - 2 * spacing) / root.columns

          width: grid.width
          spacing: 14

          Repeater {
            model: root.items

            Rectangle {
              id: tile

              required property var modelData
              required property int index

              readonly property bool current: root.selected === index
              readonly property bool isMonitor: root.tab === "monitors"

              width: tiles.tileWidth
              height: Math.round(tiles.tileWidth * 0.5625) + 52
              radius: 16
              color: current ? Qt.alpha(Skein.accent, 0.14) : (tileMouse.containsMouse ? Qt.alpha(Skein.foreground, 0.07) : Qt.alpha(Skein.foreground, 0.04))
              border.width: current ? 2 : 1
              border.color: current ? Skein.accent : Qt.alpha(Skein.foreground, 0.12)

              Rectangle {
                id: shot

                x: 8
                y: 8
                width: parent.width - 16
                height: Math.round(tiles.tileWidth * 0.5625) - 8
                radius: 8
                color: Qt.alpha(Skein.foreground, 0.06)
                clip: true

                Image {
                  anchors.fill: parent
                  visible: (tile.modelData.preview ?? "") !== "" && status === Image.Ready
                  source: (tile.modelData.preview ?? "") !== "" ? `file://${tile.modelData.preview}` : ""
                  fillMode: tile.isMonitor ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                  smooth: true
                  cache: false
                }

                // A window that is not on screen cannot be photographed: show its icon instead
                Image {
                  anchors.centerIn: parent
                  visible: !tile.isMonitor && (tile.modelData.preview ?? "") === "" && source !== ""
                  width: 56
                  height: 56
                  source: root.iconFor(tile.modelData.class ?? "")
                  sourceSize: Qt.size(112, 112)
                  fillMode: Image.PreserveAspectFit
                }

                Text {
                  anchors.centerIn: parent
                  visible: !tile.isMonitor && (tile.modelData.preview ?? "") === "" && root.iconFor(tile.modelData.class ?? "") === ""
                  text: "On another workspace"
                  color: Qt.alpha(Skein.foreground, 0.45)
                  font.family: Skein.fontFamily
                  font.pointSize: Skein.fontSize - 1
                }
              }

              Column {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.top: shot.bottom
                anchors.topMargin: 6
                spacing: 1

                Text {
                  width: parent.width
                  elide: Text.ElideRight
                  text: tile.isMonitor ? tile.modelData.name : (tile.modelData.title ?? "")
                  textFormat: Text.PlainText
                  color: Skein.foreground
                  font.family: Skein.fontFamily
                  font.pointSize: Skein.fontSize
                  font.weight: Font.Medium
                }

                Text {
                  width: parent.width
                  elide: Text.ElideRight
                  text: tile.isMonitor ? `${tile.modelData.main ? "Main · " : ""}${tile.modelData.w} × ${tile.modelData.h}` : (tile.modelData.class ?? "")
                  textFormat: Text.PlainText
                  color: Qt.alpha(Skein.foreground, 0.55)
                  font.family: Skein.fontFamily
                  font.pointSize: Skein.fontSize - 1.5
                }
              }

              MouseArea {
                id: tileMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected = tile.index
                onDoubleClicked: {
                  root.selected = tile.index;
                  root.share();
                }
              }
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          y: 90
          visible: root.tab !== "region" && root.items.length === 0
          text: root.tab === "windows" ? "No windows to share" : "No monitors found"
          color: Qt.alpha(Skein.foreground, 0.5)
          font.family: Skein.fontFamily
          font.pointSize: Skein.fontSize + 1
        }

        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          y: 60
          visible: root.tab === "region"
          spacing: 8

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\uf065"
            color: Qt.alpha(Skein.foreground, 0.7)
            font.family: "JetBrainsMono Nerd Font"
            font.pointSize: Skein.fontSize + 18
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Select an area of the screen"
            color: Skein.foreground
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize + 2
            font.weight: Font.Medium
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "This window hides while you draw it."
            color: Qt.alpha(Skein.foreground, 0.55)
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize
          }
        }
      }

      Item {
        id: footer

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 22
        x: 28
        width: parent.width - 56
        height: 38

        // Remember this choice
        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Rectangle {
            width: 22
            height: 22
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            color: root.remember ? Qt.alpha(Skein.accent, 0.9) : Qt.alpha(Skein.foreground, 0.07)
            border.width: 1
            border.color: root.remember ? Qt.alpha(Skein.accent, 0.9) : Qt.alpha(Skein.foreground, 0.2)

            Text {
              anchors.centerIn: parent
              visible: root.remember
              text: "✓"
              color: Skein.background
              font.pointSize: Skein.fontSize - 1
              font.weight: Font.Bold
            }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Remember this choice for future requests"
            color: Qt.alpha(Skein.foreground, 0.8)
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize
          }
        }

        MouseArea {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: 360
          height: 30
          cursorShape: Qt.PointingHandCursor
          onClicked: root.remember = !root.remember
        }

        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Rectangle {
            width: cancelLabel.implicitWidth + 40
            height: 38
            radius: height / 2
            color: cancelMouse.containsMouse ? Qt.alpha(Skein.foreground, 0.14) : Qt.alpha(Skein.foreground, 0.07)
            border.width: 1
            border.color: Qt.alpha(Skein.foreground, 0.16)

            Text {
              id: cancelLabel

              anchors.centerIn: parent
              text: "Cancel"
              color: Skein.foreground
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize
            }

            MouseArea {
              id: cancelMouse

              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.close()
            }
          }

          Rectangle {
            width: shareLabel.implicitWidth + 44
            height: 38
            radius: height / 2
            opacity: root.tab === "region" || root.items.length > 0 ? 1 : 0.4
            color: shareMouse.containsMouse ? Qt.lighter(Skein.accent, 1.1) : Qt.alpha(Skein.accent, 0.95)

            Text {
              id: shareLabel

              anchors.centerIn: parent
              text: root.tab === "region" ? "Select area…" : "Share"
              color: Skein.background
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize
              font.weight: Font.DemiBold
            }

            MouseArea {
              id: shareMouse

              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.share()
            }
          }
        }
      }
    }
  }
}
