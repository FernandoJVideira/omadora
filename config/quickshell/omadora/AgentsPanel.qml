import QtQuick
import Quickshell.Io

// Usage of the coding agents found on this machine: rate limits and tokens by day and by model.
// Data comes from libexec/agents/omadora-agents-data.
Panel {
  id: root

  property var providers: []
  property int selected: 0

  readonly property string mono: "JetBrainsMono Nerd Font"
  readonly property bool hasLimits: (provider?.limits ?? []).length > 0 || (provider?.limitsNote ?? "") !== ""
  readonly property var provider: providers[Math.min(selected, providers.length - 1)] ?? null
  readonly property real maxDay: Math.max(1, ...(provider?.days ?? []).map(day => day.tokens))
  readonly property real maxModel: Math.max(1, ...(provider?.models ?? []).map(model => model.tokens))
  readonly property string summary: {
    const first = providers[0];
    if (!first) {
      return "";
    }
    const limits = first.limits.map(limit => `${limit.label} ${Math.round(limit.percent)}%`).join(" · ");
    return limits ? `${first.name}\n${limits}` : first.name;
  }

  function refresh(): void {
    if (!load.running) {
      load.running = true;
    }
  }

  function formatTokens(tokens: real): string {
    if (tokens >= 1e9) {
      return `${(tokens / 1e9).toFixed(1)}B`;
    }
    if (tokens >= 1e6) {
      return `${(tokens / 1e6).toFixed(1)}M`;
    }
    if (tokens >= 1e3) {
      return `${(tokens / 1e3).toFixed(1)}K`;
    }
    return `${tokens}`;
  }

  function formatReset(epoch: real): string {
    const minutes = Math.max(0, Math.round((epoch * 1000 - Date.now()) / 60000));
    const days = Math.floor(minutes / 1440);
    const hours = Math.floor((minutes % 1440) / 60);
    if (days > 0) {
      return `Resets in ${days}d ${hours}h`;
    }
    return hours > 0 ? `Resets in ${hours}h ${minutes % 60}m` : `Resets in ${minutes}m`;
  }

  function glyphFor(id: string): string {
    const glyphs = {
      "claude": 0xf069,
      "codex": 0xf121,
      "opencode": 0xf120,
      "gemini": 0xf005
    };
    return Omadora.glyph(glyphs[id] ?? 0xf06a9);
  }

  panelWidth: 440
  onOpenChanged: if (open) {
    refresh()
  }
  Component.onCompleted: refresh()

  Process {
    id: load

    command: [`${Omadora.omadoraPath}/libexec/agents/omadora-agents-data`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.providers = JSON.parse(text.trim());
        } catch (e) {
          root.providers = [];
        }
      }
    }
  }

  Timer {
    interval: root.open ? 15000 : 120000
    running: true
    repeat: true
    onTriggered: root.refresh()
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

  component Track: Rectangle {
    property real fraction: 0
    property real fillOpacity: 0.8

    height: 4
    color: Qt.alpha(Omadora.foreground, 0.15)

    Rectangle {
      width: parent.width * Math.max(0, Math.min(1, parent.fraction))
      height: parent.height
      color: Qt.alpha(Omadora.foreground, parent.fillOpacity)
    }
  }

  // Provider tabs
  Row {
    visible: root.providers.length > 0
    width: parent.width
    spacing: 8

    Repeater {
      model: root.providers

      Rectangle {
        id: tab

        required property var modelData
        required property int index

        readonly property bool active: index === root.selected

        width: (parent.width - (root.providers.length - 1) * 8) / root.providers.length
        height: 32
        color: active ? Qt.alpha(Omadora.foreground, 0.14) : (tabMouse.containsMouse ? Qt.alpha(Omadora.foreground, 0.06) : "transparent")
        border.width: 1
        border.color: Qt.alpha(Omadora.foreground, active ? 0.5 : 0.25)

        Text {
          anchors.centerIn: parent
          width: parent.width - 12
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
          text: tab.modelData.name
          color: Omadora.foreground
          font.family: root.mono
          font.pointSize: Omadora.fontSize - 1.5
        }

        MouseArea {
          id: tabMouse

          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.selected = tab.index
        }
      }
    }
  }

  Caption {
    visible: root.providers.length === 0
    text: "NO AGENTS FOUND"
  }

  // Header
  Item {
    visible: root.provider !== null
    width: parent.width
    height: visible ? 40 : 0

    Text {
      id: headIcon

      anchors.verticalCenter: parent.verticalCenter
      text: root.provider ? root.glyphFor(root.provider.id) : ""
      color: Omadora.accent
      font.family: Omadora.fontFamily
      font.pointSize: Omadora.fontSize + 8
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      x: headIcon.width + 14
      spacing: 2

      Text {
        text: root.provider?.name ?? ""
        color: Omadora.foreground
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.fontSize + 1.5
        font.bold: true
      }

      Caption {
        visible: text !== ""
        text: root.provider?.plan ?? ""
      }
    }
  }

  Flickable {
    visible: root.provider !== null
    width: parent.width
    height: Math.min(content.implicitHeight, 620)
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: content

      width: parent.width
      spacing: 12

      Divider {
        visible: root.hasLimits
      }

      Caption {
        visible: root.hasLimits
        text: "LIMITS"
      }

      Repeater {
        model: root.provider?.limits ?? []

        Column {
          id: limit

          required property var modelData

          width: content.width
          spacing: 6

          Item {
            width: parent.width
            height: label.implicitHeight

            Text {
              id: label

              text: limit.modelData.label
              color: Omadora.foreground
              font.family: Omadora.fontFamily
              font.pointSize: Omadora.fontSize + 0.5
            }

            Text {
              anchors.right: parent.right
              text: `${Math.round(limit.modelData.percent)}%`
              color: Omadora.foreground
              font.family: root.mono
              font.pointSize: Omadora.fontSize - 1
            }
          }

          Track {
            width: parent.width
            fraction: limit.modelData.percent / 100
          }

          Caption {
            text: root.formatReset(limit.modelData.resetsAt)
          }
        }
      }

      Text {
        visible: (root.provider?.limits ?? []).length === 0
        width: parent.width
        text: root.provider?.limitsNote ?? ""
        wrapMode: Text.Wrap
        color: Qt.alpha(Omadora.foreground, 0.6)
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.fontSize - 1
      }

      Divider {}

      Caption {
        text: "TOKENS BY DAY"
      }

      Column {
        width: parent.width
        spacing: 8

        Repeater {
          model: root.provider?.days ?? []

          Item {
            id: day

            required property var modelData

            readonly property bool today: modelData.label === "Today"

            width: content.width
            height: 18

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: day.modelData.label
              color: day.today ? Omadora.foreground : Qt.alpha(Omadora.foreground, 0.6)
              font.family: Omadora.fontFamily
              font.pointSize: Omadora.fontSize - 1
              font.bold: day.today
            }

            Track {
              anchors.verticalCenter: parent.verticalCenter
              x: 70
              width: parent.width - 70 - 80
              fraction: day.modelData.tokens / root.maxDay
              fillOpacity: day.today ? 0.95 : 0.55
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.right: parent.right
              text: root.formatTokens(day.modelData.tokens)
              color: Omadora.foreground
              font.family: root.mono
              font.pointSize: Omadora.fontSize - 1
              font.bold: day.today
            }
          }
        }
      }

      Divider {}

      Caption {
        text: "TOKENS BY MODEL"
      }

      Column {
        width: parent.width
        spacing: 6

        Repeater {
          model: root.provider?.models ?? []

          Rectangle {
            id: model

            required property var modelData

            width: content.width
            height: 32
            color: Qt.alpha(Omadora.foreground, 0.06)

            Rectangle {
              width: parent.width * model.modelData.tokens / root.maxModel
              height: parent.height
              color: Qt.alpha(Omadora.foreground, 0.14)
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              x: 10
              text: model.modelData.name
              color: Omadora.foreground
              font.family: Omadora.fontFamily
              font.pointSize: Omadora.fontSize
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.right: parent.right
              anchors.rightMargin: 10
              text: root.formatTokens(model.modelData.tokens)
              color: Omadora.foreground
              font.family: root.mono
              font.pointSize: Omadora.fontSize - 1
            }
          }
        }
      }

      Caption {
        visible: (root.provider?.models ?? []).length === 0
        text: "NO USAGE IN THE LAST 7 DAYS"
      }
    }
  }
}
