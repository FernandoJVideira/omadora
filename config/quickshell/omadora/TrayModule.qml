import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// Expander arrow that slides out the system tray on hover (Waybar's tray drawer).
Item {
  id: root

  required property var barWindow

  readonly property bool expanded: hover.hovered

  height: parent ? parent.height : Omadora.barHeight
  width: expander.width + drawer.width

  HoverHandler {
    id: hover
  }

  Item {
    id: drawer

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: root.expanded && SystemTray.items.values.length > 0 ? icons.implicitWidth + 2 * Omadora.modulePadding : 0
    clip: true

    Behavior on width {
      NumberAnimation {
        duration: 300
        easing.type: Easing.OutCubic
      }
    }

    Row {
      id: icons

      anchors.right: parent.right
      anchors.rightMargin: Omadora.modulePadding
      anchors.verticalCenter: parent.verticalCenter
      spacing: 12

      Repeater {
        model: SystemTray.items

        MouseArea {
          id: trayItem

          required property var modelData

          width: 12
          height: 12
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
              modelData.secondaryActivate();
            } else if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
              if (modelData.hasMenu) {
                const pos = trayItem.mapToItem(root.barWindow.contentItem, 0, 0);
                modelData.display(root.barWindow, pos.x, root.barWindow.height);
              }
            } else {
              modelData.activate();
            }
          }
          onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)

          IconImage {
            anchors.fill: parent
            source: trayItem.modelData.icon
          }

          Tooltip {
            target: trayItem
            text: trayItem.modelData.tooltipTitle || trayItem.modelData.title
            shown: trayItem.containsMouse
          }
        }
      }
    }
  }

  BarItem {
    id: expander

    anchors.right: parent.right
    text: Omadora.glyph(0xf053)
  }
}
