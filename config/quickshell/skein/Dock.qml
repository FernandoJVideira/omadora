import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// A macOS-style dock: pinned and running apps, magnification, auto-hide and a right-click menu.
// Settings live in DockConfig. qs -c skein ipc call dock toggle|enable|disable
Scope {
  id: root

  readonly property var dockScreen: Quickshell.screens.find(s => s.x === 0 && s.y === 0) ?? Quickshell.screens[0]

  function lookup(appId: string): var {
    return DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId);
  }

  function keyOf(text: string): string {
    return text.toLowerCase().replace(/\.desktop$/, "");
  }

  function iconFor(entry: var, appId: string): string {
    return (entry ? Quickshell.iconPath(entry.icon, true) : "") || Quickshell.iconPath(appId.toLowerCase(), true) || "";
  }

  // Pinned apps first, then other running apps (with a divider between)
  readonly property var items: {
    const toplevels = ToplevelManager.toplevels.values;
    DesktopEntries.applications.values; // lookups are empty until the entries are scanned
    const result = [];
    const byKey = {};
    for (const id of DockConfig.pinned) {
      const entry = root.lookup(id);
      const item = {
        key: root.keyOf(entry?.id ?? id),
        id: entry?.id ?? id,
        entry: entry,
        name: entry?.name ?? id,
        icon: root.iconFor(entry, id),
        windows: [],
        pinned: true
      };
      result.push(item);
      byKey[item.key] = item;
    }
    let divided = false;
    for (const toplevel of toplevels) {
      const appId = toplevel.appId;
      if (!appId) {
        continue;
      }
      const entry = root.lookup(appId);
      const key = root.keyOf(entry?.id ?? appId);
      let item = byKey[key];
      if (!item) {
        if (!DockConfig.showRunning) {
          continue;
        }
        if (!divided && result.length > 0) {
          result.push({
            separator: true
          });
          divided = true;
        }
        item = {
          key: key,
          id: entry?.id ?? appId,
          entry: entry,
          name: entry?.name ?? appId,
          icon: root.iconFor(entry, appId),
          windows: [],
          pinned: false
        };
        result.push(item);
        byKey[key] = item;
      }
      item.windows.push(toplevel);
    }
    return result;
  }

  IpcHandler {
    target: "dock"

    function toggle(): void {
      DockConfig.set("enabled", !DockConfig.enabled);
    }

    function enable(): void {
      DockConfig.set("enabled", true);
    }

    function disable(): void {
      DockConfig.set("enabled", false);
    }
  }

  // Changing the edge swaps the anchors of a live window, which Qt leaves half-updated:
  // rebuild the window instead
  property bool rebuilding: false

  Connections {
    target: DockConfig

    function onPositionChanged(): void {
      root.rebuilding = true;
      rebuild.restart();
    }
  }

  Timer {
    id: rebuild

    interval: 60
    onTriggered: root.rebuilding = false
  }

  LazyLoader {
    active: DockConfig.enabled && !root.rebuilding

    PanelWindow {
      id: win

      readonly property string edge: DockConfig.position
      readonly property bool vertical: edge !== "bottom"
      readonly property int base: DockConfig.iconSize
      readonly property int peak: DockConfig.magnify ? Math.max(DockConfig.magnifySize, base) : base
      readonly property int gap: 8
      readonly property int frameThickness: base + 20
      // Room for the magnified icons and the name label above the frame
      readonly property int areaThickness: gap + frameThickness + (peak - base) + 34
      readonly property int menuRoom: 190

      property bool hovered: false
      property real hoverPos: -1 // continuous index of the app under the pointer
      // Smoothed copies of it, so the icons and the frame around them grow together
      property real focus: 0
      property real strength: 0
      property bool menuOpen: false
      property var menuItem: null
      property real menuAnchor: 0 // along the dock, in window coordinates
      readonly property bool revealed: !DockConfig.autoHide || hovered || menuOpen

      onHoverPosChanged: {
        if (hoverPos >= 0) {
          focus = hoverPos;
          strength = DockConfig.magnify ? 1 : 0;
        } else {
          strength = 0;
        }
      }

      Behavior on focus {
        enabled: win.strength > 0.01
        NumberAnimation {
          duration: 70
        }
      }

      Behavior on strength {
        NumberAnimation {
          duration: 130
        }
      }

      function cellSize(index: int, separator: bool): real {
        if (separator) {
          return 12;
        }
        const distance = index - focus;
        return base + (peak - base) * strength * Math.exp(-(distance * distance) / 1.6);
      }

      function hover(value: bool): void {
        if (value) {
          hideTimer.stop();
          hovered = true;
        } else {
          // The pointer moves onto the menu: keep the icons as they are until it closes
          if (!menuOpen) {
            hoverPos = -1;
          }
          hideTimer.restart();
        }
      }

      onMenuOpenChanged: if (!menuOpen) {
        hoverPos = -1;
        hideTimer.restart();
      }

      function openMenu(item: var, anchor: real): void {
        menuItem = item;
        menuAnchor = anchor;
        menuOpen = true;
      }

      screen: root.dockScreen
      visible: DockConfig.enabled
      color: "transparent"
      anchors {
        bottom: win.edge === "bottom" || win.vertical
        left: win.edge !== "right"
        right: win.edge !== "left"
        top: win.vertical
      }
      // Room for the menu is always allocated, so opening it never resizes the window
      implicitWidth: vertical ? areaThickness + menuRoom : 0
      implicitHeight: vertical ? 0 : areaThickness + menuRoom
      exclusionMode: ExclusionMode.Normal
      // Floating over windows while hiding; pushing them aside otherwise
      exclusiveZone: DockConfig.autoHide ? 0 : gap + frameThickness + 4
      WlrLayershell.namespace: "skein-dock"
      WlrLayershell.layer: WlrLayer.Top
      mask: Region {
        item: win.menuOpen ? scene : (win.revealed ? area : hotStrip)
      }

      Timer {
        id: hideTimer

        interval: 450
        onTriggered: win.hovered = false
      }

      Item {
        id: scene

        anchors.fill: parent

        // Closes the menu when you click anywhere else
        MouseArea {
          anchors.fill: parent
          enabled: win.menuOpen
          acceptedButtons: Qt.AllButtons
          onClicked: win.menuOpen = false
        }

        // A thin strip at the screen edge that brings a hidden dock back
        Item {
          id: hotStrip

          width: win.vertical ? 2 : parent.width
          height: win.vertical ? parent.height : 2
          x: win.edge === "right" ? parent.width - 2 : 0
          y: win.edge === "bottom" ? parent.height - 2 : 0

          HoverHandler {
            enabled: DockConfig.autoHide
            onHoveredChanged: win.hover(hovered)
          }
        }

        // The dock and the room around it for magnified icons and labels
        Item {
          id: area

          property real hidden: win.revealed ? 0 : win.areaThickness + 4

          // Sized from the icons, not from the frame, which is centred inside this item
          width: win.vertical ? win.areaThickness : cells.childrenRect.width + 24
          height: win.vertical ? cells.childrenRect.height + 24 : win.areaThickness
          anchors.bottom: win.edge === "bottom" ? parent.bottom : undefined
          anchors.bottomMargin: win.edge === "bottom" ? -hidden : 0
          anchors.horizontalCenter: win.vertical ? undefined : parent.horizontalCenter
          anchors.left: win.edge === "left" ? parent.left : undefined
          anchors.leftMargin: win.edge === "left" ? -hidden : 0
          anchors.right: win.edge === "right" ? parent.right : undefined
          anchors.rightMargin: win.edge === "right" ? -hidden : 0
          anchors.verticalCenter: win.vertical ? parent.verticalCenter : undefined

          Behavior on hidden {
            NumberAnimation {
              duration: 200
              easing.type: Easing.OutCubic
            }
          }

          HoverHandler {
            onHoveredChanged: win.hover(hovered)
          }

          Rectangle {
            id: frame

            width: win.vertical ? win.frameThickness : cells.childrenRect.width + 24
            height: win.vertical ? cells.childrenRect.height + 24 : win.frameThickness
            anchors.bottom: win.edge === "bottom" ? parent.bottom : undefined
            anchors.bottomMargin: win.gap
            anchors.left: win.edge === "left" ? parent.left : undefined
            anchors.leftMargin: win.gap
            anchors.right: win.edge === "right" ? parent.right : undefined
            anchors.rightMargin: win.gap
            anchors.horizontalCenter: win.vertical ? undefined : parent.horizontalCenter
            anchors.verticalCenter: win.vertical ? parent.verticalCenter : undefined
            radius: 16
            color: Qt.alpha(Skein.background, 0.88)
            border.width: 1
            border.color: Qt.alpha(Skein.accent, 0.5)

            // The icons sit on the screen-side edge and grow into the room above the frame
            Grid {
              id: cells

              columns: win.vertical ? 1 : 1000
              anchors.bottom: win.edge === "bottom" ? parent.bottom : undefined
              anchors.bottomMargin: 4
              anchors.left: win.edge === "left" ? parent.left : undefined
              anchors.leftMargin: 4
              anchors.right: win.edge === "right" ? parent.right : undefined
              anchors.rightMargin: 4
              anchors.horizontalCenter: win.vertical ? undefined : parent.horizontalCenter
              anchors.verticalCenter: win.vertical ? parent.verticalCenter : undefined

              Repeater {
                model: root.items

                Item {
                  id: cell

                  required property var modelData
                  required property int index

                  readonly property bool isSeparator: modelData.separator === true
                  readonly property real size: win.cellSize(index, isSeparator)
                  readonly property bool running: !isSeparator && modelData.windows.length > 0
                  property real bounce: 0

                  // Along the dock the cell is as wide as the icon, across it as tall as the biggest
                  width: win.vertical ? win.peak + 8 : size
                  height: win.vertical ? size : win.peak + 8

                  Rectangle {
                    visible: cell.isSeparator
                    anchors.centerIn: win.vertical ? undefined : parent
                    width: win.vertical ? win.base : 1
                    height: win.vertical ? 1 : win.base
                    x: win.vertical ? 4 : 0
                    y: win.vertical ? 5 : 0
                    color: Qt.alpha(Skein.foreground, 0.25)
                  }

                  Item {
                    id: icon

                    visible: !cell.isSeparator
                    width: cell.size
                    height: cell.size
                    x: win.edge === "left" ? 8 + cell.bounce : (win.edge === "right" ? parent.width - width - 8 - cell.bounce : 0)
                    y: win.edge === "bottom" ? parent.height - height - 8 - cell.bounce : 0

                    Image {
                      id: picture

                      anchors.fill: parent
                      source: cell.modelData.icon ?? ""
                      sourceSize: Qt.size(160, 160)
                      fillMode: Image.PreserveAspectFit
                      smooth: true
                      asynchronous: true
                      visible: status === Image.Ready
                    }

                    // No icon found: the first letter on the accent colour
                    Rectangle {
                      anchors.fill: parent
                      visible: picture.status !== Image.Ready
                      radius: width * 0.22
                      color: Qt.alpha(Skein.accent, 0.7)

                      Text {
                        anchors.centerIn: parent
                        text: (cell.modelData.name ?? "?").charAt(0).toUpperCase()
                        color: Skein.background
                        font.family: Skein.fontFamily
                        font.pointSize: cell.size * 0.28
                        font.bold: true
                      }
                    }
                  }

                  // Open-window dot, on the edge side of the icon
                  Rectangle {
                    visible: cell.running && DockConfig.showIndicators
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Skein.accent
                    x: win.edge === "left" ? 1 : (win.edge === "right" ? parent.width - 6 : (parent.width - 5) / 2)
                    y: win.edge === "bottom" ? parent.height - 6 : (parent.height - 5) / 2
                  }

                  // Name label while the pointer is over the icon
                  Rectangle {
                    id: label

                    visible: !cell.isSeparator && win.hoverPos >= 0 && Math.abs(win.hoverPos - cell.index) < 0.5 && !win.menuOpen
                    z: 5
                    radius: 8
                    color: Qt.alpha(Skein.background, 0.95)
                    border.width: 1
                    border.color: Qt.alpha(Skein.accent, 0.5)
                    width: labelText.implicitWidth + 20
                    height: labelText.implicitHeight + 10
                    x: win.edge === "left" ? icon.x + icon.width + 12 : (win.edge === "right" ? icon.x - width - 12 : (parent.width - width) / 2)
                    y: win.edge === "bottom" ? icon.y - height - 8 : icon.y + (icon.height - height) / 2

                    Text {
                      id: labelText

                      anchors.centerIn: parent
                      text: cell.modelData.name ?? ""
                      color: Skein.foreground
                      font.family: Skein.fontFamily
                      font.pointSize: Skein.fontSize
                    }
                  }

                  SequentialAnimation {
                    id: bounceAnimation

                    NumberAnimation {
                      target: cell
                      property: "bounce"
                      to: 18
                      duration: 160
                      easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                      target: cell
                      property: "bounce"
                      to: 0
                      duration: 200
                      easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                      target: cell
                      property: "bounce"
                      to: 12
                      duration: 140
                      easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                      target: cell
                      property: "bounce"
                      to: 0
                      duration: 160
                      easing.type: Easing.InQuad
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    enabled: !cell.isSeparator
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: mouse => {
                      const along = win.vertical ? mouse.y : mouse.x;
                      win.hoverPos = cell.index + Math.max(0, Math.min(1, along / Math.max(1, cell.size)));
                    }
                    onEntered: win.hover(true)
                    onClicked: mouse => {
                      const item = cell.modelData;
                      if (mouse.button !== Qt.RightButton) {
                        win.menuOpen = false;
                      }
                      if (mouse.button === Qt.RightButton) {
                        const point = cell.mapToItem(scene, cell.width / 2, cell.height / 2);
                        win.openMenu(item, win.vertical ? point.y : point.x);
                      } else if (mouse.button === Qt.MiddleButton || item.windows.length === 0) {
                        if (item.entry) {
                          item.entry.execute();
                          bounceAnimation.restart();
                        }
                      } else {
                        // One window: raise it. Several: step through them.
                        const windows = item.windows;
                        const current = windows.findIndex(w => w.activated);
                        windows[(current + 1) % windows.length].activate();
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Right-click menu
        Rectangle {
          id: menu

          opacity: win.menuOpen && win.menuItem !== null ? 1 : 0
          visible: opacity > 0.01
          width: 210

          Behavior on opacity {
            NumberAnimation {
              duration: 130
              easing.type: Easing.OutCubic
            }
          }

          transform: Translate {
            x: win.edge === "left" ? (1 - menu.opacity) * -8 : (win.edge === "right" ? (1 - menu.opacity) * 8 : 0)
            y: win.edge === "bottom" ? (1 - menu.opacity) * 8 : 0
          }
          height: menuColumn.implicitHeight + 12
          radius: 12
          color: Qt.alpha(Skein.background, 0.97)
          border.width: 1
          border.color: Qt.alpha(Skein.accent, 0.5)
          x: win.edge === "left" ? win.areaThickness + 6 : (win.edge === "right" ? parent.width - win.areaThickness - width - 6 : Math.max(8, Math.min(parent.width - width - 8, win.menuAnchor - width / 2)))
          y: win.edge === "bottom" ? parent.height - win.areaThickness - height - 6 : Math.max(8, Math.min(parent.height - height - 8, win.menuAnchor - height / 2))

          Column {
            id: menuColumn

            x: 6
            y: 6
            width: parent.width - 12

            Text {
              width: parent.width
              leftPadding: 8
              topPadding: 4
              bottomPadding: 6
              elide: Text.ElideRight
              text: win.menuItem?.name ?? ""
              color: Qt.alpha(Skein.foreground, 0.6)
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize - 1
              font.bold: true
            }

            Repeater {
              model: {
                const item = win.menuItem;
                if (!item) {
                  return [];
                }
                const entries = [];
                entries.push({
                  text: item.windows.length > 0 ? "New window" : "Open",
                  action: "open",
                  enabled: !!item.entry
                });
                if (item.windows.length > 0) {
                  entries.push({
                    text: "Quit",
                    action: "quit",
                    enabled: true
                  });
                }
                entries.push({
                  text: item.pinned ? "Remove from Dock" : "Keep in Dock",
                  action: item.pinned ? "unpin" : "pin",
                  enabled: true
                });
                entries.push({
                  text: "Dock settings…",
                  action: "settings",
                  enabled: true
                });
                return entries;
              }

              Rectangle {
                id: entry

                required property var modelData

                width: menuColumn.width
                height: 30
                radius: 8
                color: entryMouse.containsMouse && modelData.enabled ? Qt.alpha(Skein.accent, 0.25) : "transparent"
                opacity: modelData.enabled ? 1 : 0.4

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  text: entry.modelData.text
                  color: Skein.foreground
                  font.family: Skein.fontFamily
                  font.pointSize: Skein.fontSize
                }

                MouseArea {
                  id: entryMouse

                  anchors.fill: parent
                  hoverEnabled: true
                  enabled: entry.modelData.enabled
                  onClicked: {
                    const item = win.menuItem;
                    win.menuOpen = false;
                    switch (entry.modelData.action) {
                    case "open":
                      item.entry.execute();
                      break;
                    case "quit":
                      item.windows.forEach(w => w.close());
                      break;
                    case "pin":
                      DockConfig.pin(item.id);
                      break;
                    case "unpin":
                      DockConfig.unpin(item.id);
                      break;
                    case "settings":
                      Quickshell.execDetached(["qs", "-c", "skein", "ipc", "call", "settings", "page", "dock"]);
                      break;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
