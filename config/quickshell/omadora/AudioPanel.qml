import QtQuick
import Quickshell.Services.Pipewire

// Output and input devices with volume, mute, default-device selection and an input level meter.
Panel {
  id: root

  readonly property var nodes: Pipewire.nodes.values
  readonly property var sinks: nodes.filter(n => !n.isStream && (n.type & PwNodeType.AudioSink) === PwNodeType.AudioSink)
  readonly property var sources: nodes.filter(n => !n.isStream && (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource)
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property string mono: "JetBrainsMono Nerd Font"

  function label(node: var): string {
    return node.description || node.nickname || node.name;
  }

  PwObjectTracker {
    objects: root.nodes
  }

  PwNodePeakMonitor {
    node: root.source
    enabled: root.open && root.source !== null
    id: inputPeak
  }

  component Divider: Rectangle {
    width: parent.width
    height: 1
    color: Qt.alpha(Omadora.foreground, 0.1)
  }

  component Caption: Text {
    color: Qt.alpha(Omadora.foreground, 0.6)
    font.family: root.mono
    font.pointSize: Omadora.fontSize - 2.5
    font.letterSpacing: 1
  }

  component DeviceRow: Rectangle {
    id: row

    required property var node
    required property var current
    required property string glyph

    signal chosen

    readonly property bool selected: node === current

    width: parent.width
    height: 30
    color: selected ? Qt.alpha(Omadora.foreground, 0.12) : (mouse.containsMouse ? Qt.alpha(Omadora.foreground, 0.06) : "transparent")

    Row {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      spacing: 12

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: row.glyph
        color: Omadora.foreground
        opacity: row.selected ? 1 : 0.8
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.fontSize
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 28 - 12
        elide: Text.ElideRight
        text: root.label(row.node)
        textFormat: Text.PlainText
        color: Omadora.foreground
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.fontSize
        font.bold: row.selected
      }
    }

    MouseArea {
      id: mouse

      anchors.fill: parent
      hoverEnabled: true
      onClicked: row.chosen()
    }
  }

  component Section: Column {
    id: section

    required property string title
    required property var devices
    required property var current
    required property string glyph
    property bool meter: false
    property real level: 0

    signal chosen(var node)

    width: parent.width
    spacing: 8

    Item {
      width: parent.width
      height: caption.implicitHeight

      Caption {
        id: caption

        text: section.title
      }

      Caption {
        anchors.right: parent.right
        text: `${Math.round((section.current?.audio?.volume ?? 0) * 100)}%`
      }
    }

    PanelSlider {
      width: parent.width
      value: section.current?.audio?.volume ?? 0
      onMoved: value => {
        if (section.current?.audio) {
          section.current.audio.volume = value;
        }
      }
    }

    Rectangle {
      visible: section.meter
      width: parent.width
      height: 4
      color: Qt.alpha(Omadora.foreground, 0.15)

      Rectangle {
        width: parent.width * Math.min(1, Math.sqrt(section.level))
        height: parent.height
        color: Qt.alpha(Omadora.foreground, 0.8)
      }
    }

    Flickable {
      width: parent.width
      height: Math.min(list.implicitHeight, 150)
      contentHeight: list.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: list

        width: parent.width

        Repeater {
          model: section.devices

          DeviceRow {
            required property var modelData

            node: modelData
            current: section.current
            glyph: section.glyph
            onChosen: section.chosen(modelData)
          }
        }
      }
    }
  }

  Item {
    width: parent.width
    height: 40

    Text {
      id: headIcon

      anchors.verticalCenter: parent.verticalCenter
      text: root.sink?.audio?.muted ? Omadora.glyph(0xeee8) : Omadora.glyph(0xf028)
      color: Qt.alpha(Omadora.foreground, 0.7)
      font.family: Omadora.fontFamily
      font.pointSize: Omadora.fontSize + 6
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      x: headIcon.width + 14
      width: parent.width - x - 60
      spacing: 2

      Text {
        text: "Audio"
        color: Omadora.foreground
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.fontSize + 1.5
        font.bold: true
      }

      Caption {
        width: parent.width
        elide: Text.ElideRight
        text: root.sink ? root.label(root.sink).toUpperCase() : "NO OUTPUT"
      }
    }

    // Master switch: on while the default output is not muted
    Rectangle {
      id: toggle

      readonly property bool on: root.sink?.audio ? !root.sink.audio.muted : false

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 44
      height: 22
      color: on ? Qt.alpha(Omadora.accent, 0.35) : Qt.alpha(Omadora.foreground, 0.12)
      border.width: 1
      border.color: Qt.alpha(Omadora.foreground, 0.25)

      Rectangle {
        x: toggle.on ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        color: Omadora.foreground
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (root.sink?.audio) {
            root.sink.audio.muted = !root.sink.audio.muted;
          }
        }
      }
    }
  }

  Divider {}

  Section {
    title: "OUTPUT"
    devices: root.sinks
    current: root.sink
    glyph: Omadora.glyph(0xf04c3)
    onChosen: node => Pipewire.preferredDefaultAudioSink = node
  }

  Divider {}

  Section {
    title: "INPUT"
    devices: root.sources
    current: root.source
    glyph: Omadora.glyph(0xf036c)
    meter: true
    level: inputPeak.peak
    onChosen: node => Pipewire.preferredDefaultAudioSource = node
  }
}
