import QtQuick
import Quickshell
import Quickshell.Io
import "DisplayModel.js" as Model

// Brightness, text size, scale and display selection (ported from Omarchy's monitor panel).
Panel {
  id: root

  property var monitors: ({
      focused: "",
      brightness: null,
      displays: []
    })
  property int brightnessLive: -1 // while dragging or waiting for the display to confirm
  property int queuedBrightness: -1

  readonly property string mono: "JetBrainsMono Nerd Font"
  readonly property string scripts: `${Omadora.omadoraPath}/libexec`
  readonly property var textSizeStops: [9, 10, 11, 12, 14, 16, 20]
  readonly property var scalePresets: [1, 1.25, 1.6, 2, 3, 4]
  readonly property var focusedDisplay: monitors.displays.find(display => display.focused) ?? null
  readonly property var scales: focusedDisplay ? Model.availableScales(scalePresets, focusedDisplay.width, focusedDisplay.height) : scalePresets
  readonly property int currentScaleIndex: focusedDisplay ? Model.matchingScaleIndex(scales, focusedDisplay.scale, focusedDisplay.width, focusedDisplay.height) : -1
  readonly property bool hasBrightness: monitors.brightness !== null && monitors.brightness !== undefined
  readonly property int brightness: brightnessLive >= 0 ? brightnessLive : (hasBrightness ? monitors.brightness : 0)
  readonly property int textStopIndex: {
    let best = 0;
    for (let i = 1; i < textSizeStops.length; i++) {
      if (Math.abs(textSizeStops[i] - Omadora.textSize) < Math.abs(textSizeStops[best] - Omadora.textSize)) {
        best = i;
      }
    }
    return best;
  }

  function refresh(): void {
    if (!stateProc.running) {
      stateProc.running = true;
    }
  }

  function formatScale(scale: string): string {
    return `${Number(scale).toFixed(2).replace(/\.?0+$/, "")}x`;
  }

  function setBrightness(percent: int): void {
    brightnessLive = Model.clampBrightness(percent);
    queuedBrightness = brightnessLive;
    if (!brightnessProc.running) {
      applyBrightness();
    }
  }

  function applyBrightness(): void {
    const target = queuedBrightness;
    queuedBrightness = -1;
    brightnessProc.command = [`${scripts}/omadora-brightness-display`, "--no-osd", "--monitor", monitors.focused, `${target}%`];
    brightnessProc.running = true;
  }

  function setScale(scale: string): void {
    Quickshell.execDetached([`${scripts}/omadora-hyprland-monitor-scaling`, scale]);
    refreshTimer.restart();
  }

  function focusDisplay(name: string): void {
    Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ monitor = "${name}" })`]);
    brightnessLive = -1;
    refreshTimer.restart();
  }

  panelWidth: 440
  onOpenChanged: if (open) {
    brightnessLive = -1;
    refresh();
  }

  Process {
    id: stateProc

    command: [`${root.scripts}/omadora-monitor-state`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.monitors = JSON.parse(text.trim());
          if (!brightnessProc.running && root.queuedBrightness < 0) {
            root.brightnessLive = -1;
          }
        } catch (e) {
          // keep the last state
        }
      }
    }
  }

  // Brightness is set one request at a time; only the latest value matters
  Process {
    id: brightnessProc

    onExited: {
      if (root.queuedBrightness >= 0) {
        root.applyBrightness();
      }
    }
  }

  Timer {
    id: refreshTimer

    interval: 1500
    onTriggered: root.refresh()
  }

  component Divider: Item {
    width: parent.width
    height: 1
  }

  component Caption: Text {
    color: Qt.alpha(Omadora.foreground, 0.6)
    font.family: root.mono
    font.pointSize: Omadora.fontSize - 2.5
    font.letterSpacing: 1
  }

  // Header
  Item {
    width: parent.width
    height: 44

    Text {
      id: headIcon

      anchors.verticalCenter: parent.verticalCenter
      text: Omadora.glyph(0xf0379)
      color: Qt.alpha(Omadora.foreground, 0.8)
      font.family: Omadora.fontFamily
      font.pointSize: Omadora.fontSize + 7
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      x: headIcon.width + 14
      spacing: 2

      Text {
        text: "Display"
        color: Omadora.foreground
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.fontSize + 2
        font.bold: true
      }

      Caption {
        text: root.hasBrightness ? Model.brightnessName(root.brightness).toUpperCase() : (root.focusedDisplay ? root.focusedDisplay.name : "")
      }
    }
  }

  Rectangle {
    width: parent.width
    height: 1
    color: Qt.alpha(Omadora.foreground, 0.1)
  }

  // Brightness
  Column {
    visible: root.hasBrightness
    width: parent.width
    spacing: 8

    Item {
      width: parent.width
      height: brightnessCaption.implicitHeight

      Caption {
        id: brightnessCaption

        text: "BRIGHTNESS"
      }

      Caption {
        anchors.right: parent.right
        text: `${root.brightness}%`
      }
    }

    PanelSlider {
      width: parent.width
      value: root.brightness / 100
      onMoved: value => root.setBrightness(Math.round(value * 100))
    }
  }

  // Text size
  Column {
    width: parent.width
    spacing: 8

    Item {
      width: parent.width
      height: textCaption.implicitHeight

      Caption {
        id: textCaption

        text: "TEXT SIZE"
      }

      Caption {
        anchors.right: parent.right
        text: `${textSlider.dragging ? root.textSizeStops[textSlider.liveIndex] : Omadora.textSize}px`
      }
    }

    StepSlider {
      id: textSlider

      width: parent.width
      stops: root.textSizeStops.length
      index: root.textStopIndex
      onReleased: index => Quickshell.execDetached([`${root.scripts}/omadora-display-text-size`, `${root.textSizeStops[index]}`])
    }
  }

  // Scale of the focused display
  Column {
    visible: root.focusedDisplay !== null
    width: parent.width
    spacing: 8

    Caption {
      text: "SCALE"
    }

    Row {
      width: parent.width
      spacing: 6

      Repeater {
        model: root.scales

        Rectangle {
          id: scaleButton

          required property var modelData
          required property int index

          readonly property bool active: index === root.currentScaleIndex

          width: (parent.width - (root.scales.length - 1) * 6) / root.scales.length
          height: 32
          color: active ? Qt.alpha(Omadora.foreground, 0.16) : (scaleMouse.containsMouse ? Qt.alpha(Omadora.foreground, 0.06) : "transparent")
          border.width: 1
          border.color: Qt.alpha(Omadora.foreground, active ? 0.5 : 0.25)

          Text {
            anchors.centerIn: parent
            text: root.formatScale(scaleButton.modelData)
            color: Omadora.foreground
            font.family: root.mono
            font.pointSize: Omadora.fontSize - 1.5
          }

          MouseArea {
            id: scaleMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.setScale(scaleButton.modelData)
          }
        }
      }
    }
  }

  // Displays: click one to move focus there
  Column {
    visible: root.monitors.displays.length > 0
    width: parent.width
    spacing: 8

    Caption {
      text: "DISPLAYS"
    }

    Column {
      width: parent.width

      Repeater {
        model: root.monitors.displays

        Rectangle {
          id: display

          required property var modelData

          width: parent.width
          height: 36
          color: modelData.focused ? Qt.alpha(Omadora.foreground, 0.1) : (displayMouse.containsMouse ? Qt.alpha(Omadora.foreground, 0.05) : "transparent")

          Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            spacing: 12

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Omadora.glyph(0xf0379)
              color: Omadora.foreground
              opacity: display.modelData.enabled ? 0.8 : 0.4
              font.family: Omadora.fontFamily
              font.pointSize: Omadora.fontSize
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: display.modelData.focused ? `${display.modelData.name} · focused` : display.modelData.name
              color: Omadora.foreground
              opacity: display.modelData.enabled ? 1 : 0.5
              font.family: Omadora.fontFamily
              font.pointSize: Omadora.fontSize
            }
          }

          Text {
            visible: display.modelData.focused
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 12
            text: Omadora.glyph(0xf00c)
            color: Qt.alpha(Omadora.foreground, 0.7)
            font.family: Omadora.fontFamily
            font.pointSize: Omadora.fontSize - 1
          }

          MouseArea {
            id: displayMouse

            anchors.fill: parent
            hoverEnabled: true
            enabled: !display.modelData.focused
            onClicked: root.focusDisplay(display.modelData.name)
          }
        }
      }
    }
  }
}
