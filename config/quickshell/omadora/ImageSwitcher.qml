import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Full-screen carousel of images (themes, wallpapers): arrows or scroll to browse, Enter or a click on
// the middle card to apply. Items are {key, label, preview, background, current}.
//   qs -c omadora ipc call <target> open|close|apply <key>|select <key>
Scope {
  id: root

  required property string target // IPC target name
  required property string dataCommand // prints the items as JSON
  required property var applyCommand // run with the chosen item's key appended

  property bool active: false
  property var themes: []
  property int index: 0

  readonly property var item: themes[index] ?? null
  readonly property string mono: "JetBrainsMono Nerd Font"

  function open(): void {
    if (!load.running) {
      load.running = true;
    }
  }

  function close(): void {
    active = false;
  }

  function apply(key: string): void {
    active = false;
    Quickshell.execDetached([...applyCommand, key]);
  }

  function move(step: int): void {
    index = Math.max(0, Math.min(themes.length - 1, index + step));
  }

  IpcHandler {
    target: root.target

    function open(): void {
      root.open();
    }

    function close(): void {
      root.close();
    }

    function apply(key: string): void {
      root.apply(key);
    }

    // Move the selection to an item while the switcher is open
    function select(key: string): void {
      const found = root.themes.findIndex(item => item.key === key);
      if (found >= 0) {
        root.index = found;
      }
    }
  }

  Process {
    id: load

    command: [root.dataCommand]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.themes = JSON.parse(text.trim());
        } catch (e) {
          root.themes = [];
        }
        const current = root.themes.findIndex(item => item.current);
        root.index = Math.max(0, current);
        root.active = root.themes.length > 0;
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
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: `omadora-${root.target}`
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    FocusScope {
      anchors.fill: parent
      focus: true

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_A || event.key === Qt.Key_Up) {
          root.move(-1);
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_D || event.key === Qt.Key_Down) {
          root.move(1);
        } else if (event.key === Qt.Key_PageUp) {
          root.move(-3);
        } else if (event.key === Qt.Key_PageDown) {
          root.move(3);
        } else if (event.key === Qt.Key_Home) {
          root.index = 0;
        } else if (event.key === Qt.Key_End) {
          root.index = root.themes.length - 1;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
          if (root.item) {
            root.apply(root.item.key);
          }
        } else if (event.key === Qt.Key_Escape) {
          root.close();
        } else {
          return;
        }
        event.accepted = true;
      }

      // The selected theme's wallpaper behind everything
      Image {
        anchors.fill: parent
        source: root.item?.background ? `file://${root.item.background}` : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: 1920
      }

      Rectangle {
        anchors.fill: parent
        color: Qt.alpha("black", 0.35)
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.close()
        onWheel: wheel => root.move(wheel.angleDelta.y > 0 ? -1 : 1)
      }

      Item {
        id: stage

        readonly property real cardWidth: Math.min(parent.width * 0.5, 980)
        readonly property real cardHeight: cardWidth * 0.64

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -30
        width: cardWidth
        height: cardHeight

        Repeater {
          model: root.themes

          Item {
            id: card

            required property var modelData
            required property int index

            readonly property int rel: index - root.index
            readonly property real distance: Math.abs(rel)

            visible: distance <= 3
            width: stage.cardWidth
            height: stage.cardHeight
            x: rel === 0 ? 0 : (rel > 0 ? 1 : -1) * stage.cardWidth * (0.78 + (distance - 1) * 0.3)
            scale: 1 / (1 + 0.2 * distance)
            opacity: distance === 0 ? 1 : Math.max(0, 0.8 - 0.25 * (distance - 1))
            z: 10 - distance

            property real angle: rel === 0 ? 0 : (rel > 0 ? -38 : 38)

            Behavior on x {
              NumberAnimation {
                duration: 260
                easing.type: Easing.InOutCubic
              }
            }
            Behavior on scale {
              NumberAnimation {
                duration: 260
                easing.type: Easing.InOutCubic
              }
            }
            Behavior on opacity {
              NumberAnimation {
                duration: 260
              }
            }
            Behavior on angle {
              NumberAnimation {
                duration: 260
                easing.type: Easing.InOutCubic
              }
            }

            transform: Rotation {
              origin.x: card.width / 2
              origin.y: card.height / 2
              axis {
                x: 0
                y: 1
                z: 0
              }
              angle: card.angle
            }

            Rectangle {
              anchors.fill: parent
              color: "#101014"
              border.width: card.rel === 0 ? 2 : 0
              border.color: Omadora.accent

              Image {
                anchors.fill: parent
                anchors.margins: card.rel === 0 ? 2 : 0
                source: card.modelData.preview ? `file://${card.modelData.preview}` : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 1100
              }
            }

            MouseArea {
              anchors.fill: parent
              onClicked: card.rel === 0 ? root.apply(card.modelData.key) : root.index = card.index
            }
          }
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: stage.bottom
        anchors.topMargin: 40
        text: root.item?.label ?? ""
        color: "white"
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.pt(24)
      }
    }
  }
}
