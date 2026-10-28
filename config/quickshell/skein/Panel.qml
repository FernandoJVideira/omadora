import QtQuick
import Quickshell
import Quickshell.Wayland

// Dropdown panel under the bar's right-hand modules. A transparent full-screen
// layer catches clicks outside the panel, and Escape closes it.
PanelWindow {
  id: root

  required property var barWindow
  property bool open: false
  property int panelWidth: 340
  property bool centered: false // under the middle of the bar instead of its right edge
  default property alias content: body.data

  function toggle(): void {
    open = !open;
  }

  screen: barWindow.screen
  visible: open
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "skein-panel"
  WlrLayershell.layer: WlrLayer.Overlay
  // Not Exclusive: that would take over the pointer, and clicks on other monitors would never arrive
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onClicked: root.open = false
  }

  // Clicks on the other monitors close the panel too
  Variants {
    model: Quickshell.screens.filter(screen => screen !== root.barWindow.screen)

    PanelWindow {
      required property var modelData

      screen: modelData
      visible: root.open
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "skein-panel-dismiss"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.open = false
      }
    }
  }

  Rectangle {
    id: frame

    anchors.top: parent.top
    anchors.right: root.centered ? undefined : parent.right
    anchors.horizontalCenter: root.centered ? parent.horizontalCenter : undefined
    anchors.topMargin: Skein.barHeight + Skein.barInset + 4
    anchors.rightMargin: 8
    width: root.panelWidth
    height: body.implicitHeight + 24
    color: Qt.alpha(Skein.background, 0.97)
    radius: 22
    border.width: 1
    border.color: Qt.alpha(Skein.foreground, 0.16)
    focus: true

    Keys.onEscapePressed: root.open = false

    // Fade and slide in when the panel opens
    transform: Translate {
      id: slide
    }

    ParallelAnimation {
      id: openAnimation

      NumberAnimation {
        target: frame
        property: "opacity"
        from: 0
        to: 1
        duration: 150
        easing.type: Easing.OutCubic
      }

      NumberAnimation {
        target: slide
        property: "y"
        from: -10
        to: 0
        duration: 180
        easing.type: Easing.OutCubic
      }
    }

    Connections {
      target: root

      function onOpenChanged(): void {
        if (root.open) {
          Skein.panelOpening(root);
          openAnimation.restart();
        }
      }
    }

    Connections {
      target: Skein

      function onPanelOpening(panel): void {
        if (panel !== root) {
          root.open = false;
        }
      }
    }

    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: body

      x: 12
      y: 12
      width: parent.width - 24
      spacing: 10
    }
  }
}
