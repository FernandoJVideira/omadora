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

          // Themed icons the icon theme lacks would draw as a magenta placeholder
          readonly property string iconName: modelData.icon.startsWith("image://icon/") ? modelData.icon.slice(13).split("?")[0] : ""
          readonly property bool missingIcon: iconName !== "" && Quickshell.iconPath(iconName, true) === ""

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
            id: trayIcon

            anchors.fill: parent
            visible: !trayItem.missingIcon
            source: trayItem.modelData.icon
          }

          // Icons the theme doesn't have (like the keyboard layout's symbolic one) get a glyph instead
          Text {
            visible: trayItem.missingIcon
            anchors.centerIn: parent
            text: trayItem.modelData.id.toLowerCase().includes("fcitx") ? Omadora.glyph(0xf030c) : Omadora.glyph(0xf08c6)
            color: Omadora.foreground
            font.family: Omadora.fontFamily
            font.pointSize: Omadora.fontSize + 1
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
