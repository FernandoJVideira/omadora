import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire

// Control Center: the quick switches and sliders from the bar's indicators in one panel.
Panel {
  id: root

  readonly property string scripts: `${Skein.skeinPath}/libexec`
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null

  property var net: ({})
  property bool nightLight: false
  property bool stayAwake: false
  property var monitors: ({
      focused: "",
      brightness: null
    })
  property int brightnessLive: -1
  readonly property bool hasBrightness: monitors.brightness !== null && monitors.brightness !== undefined
  // Apps that are playing sound, each with its own volume
  readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio && (n.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream)
  property bool appsOpen: false

  // Coding agent usage, from the same data as the Agents page
  property var providers: []
  property string defaultAgent: ""
  property real now: Date.now()
  // Only the default agent is shown (skein-default-agent); nothing if it reports no usage data
  readonly property var shownProviders: providers.filter(p => p.id === defaultAgent)

  function formatReset(epoch: real): string {
    const minutes = Math.max(0, Math.round((epoch * 1000 - now) / 60000));
    const days = Math.floor(minutes / 1440);
    const hours = Math.floor((minutes % 1440) / 60);
    if (days > 0) {
      return `${days}d ${hours}h`;
    }
    return hours > 0 ? `${hours}h ${minutes % 60}m` : `${minutes}m`;
  }

  function limitColor(percent: real): color {
    return percent >= 95 ? "#ff453a" : (percent >= 80 ? "#ff9f0a" : Skein.accent);
  }

  function appName(node: var): string {
    const props = node.properties ?? {};
    return props["application.name"] || node.description || node.name;
  }

  function appIcon(node: var): string {
    const props = node.properties ?? {};
    const name = props["application.icon-name"] || (props["application.name"] ?? "").toLowerCase();
    return name ? Quickshell.iconPath(name, true) ?? "" : "";
  }

  readonly property string connectedDevice: adapter ? (adapter.devices.values.find(device => device.connected)?.name ?? "") : ""

  function openSettings(page: string): void {
    root.open = false;
    Quickshell.execDetached(["qs", "-c", "skein", "ipc", "call", "settings", "page", page]);
  }

  function probe(): void {
    if (!stateProc.running) {
      stateProc.running = true;
    }
    if (!netProc.running) {
      netProc.running = true;
    }
    if (!monitorProc.running) {
      monitorProc.running = true;
    }
    if (!agentsProc.running) {
      agentsProc.running = true;
    }
    if (!defaultAgentProc.running) {
      defaultAgentProc.running = true;
    }
  }

  function toggleScript(script: string): void {
    Quickshell.execDetached([`${scripts}/${script}`]);
    recheck.restart();
  }

  panelWidth: 372
  onOpenChanged: if (open) {
    brightnessLive = -1;
    probe();
  }

  Process {
    id: stateProc

    command: ["bash", "-c", `
      systemctl --user is-active --quiet hypridle.service && echo awake=0 || echo awake=1
      echo night=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+' | head -1)
    `]
    stdout: StdioCollector {
      onStreamFinished: {
        const values = {};
        for (const line of text.split("\n")) {
          const [key, value] = line.split("=");
          values[key] = value;
        }
        root.stayAwake = values.awake === "1";
        root.nightLight = !!values.night && values.night !== "6000";
      }
    }
  }

  Process {
    id: netProc

    command: [`${root.scripts}/bar/skein-network-info`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.net = JSON.parse(text.trim());
        } catch (e) {
          root.net = {};
        }
      }
    }
  }

  Process {
    id: monitorProc

    command: [`${root.scripts}/skein-monitor-state`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.monitors = JSON.parse(text.trim());
        } catch (e) {
          // keep the last reading
        }
      }
    }
  }

  Process {
    id: brightnessProc
  }

  Process {
    id: defaultAgentProc

    command: [`${root.scripts}/skein-default-agent`]
    stdout: StdioCollector {
      onStreamFinished: root.defaultAgent = text.trim()
    }
  }

  Process {
    id: agentsProc

    command: [`${root.scripts}/agents/skein-agents-data`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.providers = JSON.parse(text.trim());
          root.now = Date.now();
        } catch (e) {
          root.providers = [];
        }
      }
    }
  }

  Timer {
    id: recheck

    interval: 1300
    onTriggered: root.probe()
  }

  // A switch tile: round glyph, title and a second line; lit with the accent colour when on
  component Tile: Rectangle {
    id: tile

    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false

    signal clicked
    signal rightClicked

    width: (parent.width - parent.spacing) / 2
    height: 58
    radius: 14
    color: tileMouse.containsMouse ? Qt.alpha(Skein.foreground, 0.12) : Qt.alpha(Skein.foreground, 0.07)

    Behavior on color {
      ColorAnimation {
        duration: 100
      }
    }
    border.width: 1
    border.color: Qt.alpha(Skein.accent, active ? 0.7 : 0.25)

    Rectangle {
      id: disc

      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      width: 36
      height: 36
      radius: 18
      color: tile.active ? Skein.accent : Qt.alpha(Skein.foreground, 0.15)

      Behavior on color {
        ColorAnimation {
          duration: 140
        }
      }

      Text {
        anchors.centerIn: parent
        text: tile.glyph
        color: tile.active ? Skein.background : Skein.foreground
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize + 1
      }
    }

    Column {
      anchors.left: disc.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      spacing: 1

      Text {
        width: parent.width
        elide: Text.ElideRight
        text: tile.title
        color: Skein.foreground
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize
        font.bold: true
      }

      Text {
        width: parent.width
        elide: Text.ElideRight
        text: tile.subtitle
        color: Qt.alpha(Skein.foreground, 0.6)
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize - 1.5
      }
    }

    MouseArea {
      id: tileMouse

      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: mouse => mouse.button === Qt.RightButton ? tile.rightClicked() : tile.clicked()
    }
  }

  // A card with a heading and a slider
  component SliderCard: Rectangle {
    id: card

    property string title: ""
    property string glyph: ""
    property real value: 0
    property string valueText: ""

    property bool chevron: false
    property bool expanded: false

    signal moved(real value)
    signal glyphClicked
    signal chevronClicked

    width: parent.width
    height: 64
    radius: 14
    color: Qt.alpha(Skein.foreground, 0.07)
    border.width: 1
    border.color: Qt.alpha(Skein.accent, 0.25)

    Text {
      x: 14
      y: 9
      text: card.title
      color: Skein.foreground
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize
      font.bold: true
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: card.chevron ? 40 : 14
      y: 10
      text: card.valueText
      color: Qt.alpha(Skein.foreground, 0.6)
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 1
    }

    // Opens the list of apps below
    Rectangle {
      visible: card.chevron
      anchors.right: parent.right
      anchors.rightMargin: 10
      y: 6
      width: 26
      height: 22
      radius: 7
      color: chevronMouse.containsMouse || card.expanded ? Qt.alpha(Skein.accent, 0.3) : Qt.alpha(Skein.foreground, 0.08)

      Text {
        anchors.centerIn: parent
        text: card.expanded ? "▴" : "▾"
        color: Skein.foreground
        font.pointSize: Skein.fontSize - 1
      }

      MouseArea {
        id: chevronMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.chevronClicked()
      }
    }

    Text {
      id: icon

      x: 14
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 10
      text: card.glyph
      color: Skein.foreground
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize + 2

      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        onClicked: card.glyphClicked()
      }
    }

    PanelSlider {
      anchors.left: icon.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.verticalCenter: icon.verticalCenter
      value: card.value
      onMoved: v => card.moved(v)
    }
  }

  Row {
    width: parent.width
    spacing: 8

    Tile {
      glyph: root.wifiDevice ? Skein.glyph(0xf1eb) : Skein.glyph(0xf0002)
      title: root.wifiDevice ? "Wi-Fi" : "Network"
      subtitle: {
        if (root.wifiDevice && !Networking.wifiEnabled) {
          return "Off";
        }
        return root.net.connection || (root.net.iface ? "Connected" : "Not connected");
      }
      active: root.wifiDevice ? Networking.wifiEnabled : !!root.net.iface
      onClicked: {
        if (root.wifiDevice && Networking.wifiHardwareEnabled) {
          Networking.wifiEnabled = !Networking.wifiEnabled;
        } else {
          root.openSettings("network");
        }
      }
      onRightClicked: root.openSettings("network")
    }

    Tile {
      visible: root.adapter !== null
      glyph: root.adapter?.enabled ? Skein.glyph(0xf00af) : Skein.glyph(0xf00b2)
      title: "Bluetooth"
      subtitle: !root.adapter?.enabled ? "Off" : (root.connectedDevice || "On")
      active: root.adapter?.enabled ?? false
      onClicked: root.adapter.enabled = !root.adapter.enabled
      onRightClicked: root.openSettings("bluetooth")
    }
  }

  Row {
    width: parent.width
    spacing: 8

    Tile {
      glyph: Skein.silenced ? Skein.glyph(0xf009b) : Skein.glyph(0xf009a)
      title: "Do Not Disturb"
      subtitle: Skein.silenced ? "On" : "Off"
      active: Skein.silenced
      onClicked: Skein.silenced = !Skein.silenced
    }

    Tile {
      glyph: Skein.glyph(0xf050e)
      title: "Night Light"
      subtitle: root.nightLight ? "On" : "Off"
      active: root.nightLight
      onClicked: {
        root.nightLight = !root.nightLight;
        root.toggleScript("skein-toggle-nightlight");
      }
    }
  }

  Row {
    width: parent.width
    spacing: 8

    Tile {
      glyph: Skein.glyph(0xf0176)
      title: "Stay Awake"
      subtitle: root.stayAwake ? "No idle lock" : "Locks when idle"
      active: root.stayAwake
      onClicked: {
        root.stayAwake = !root.stayAwake;
        root.toggleScript("skein-toggle-idle");
      }
    }

    Tile {
      glyph: Skein.glyph(0xf0e4)
      title: "Dock"
      subtitle: DockConfig.enabled ? "On" : "Off"
      active: DockConfig.enabled
      onClicked: DockConfig.set("enabled", !DockConfig.enabled)
      onRightClicked: root.openSettings("dock")
    }
  }

  SliderCard {
    visible: root.hasBrightness
    title: "Display"
    glyph: Skein.glyph(0xf00df)
    value: (root.brightnessLive >= 0 ? root.brightnessLive : (root.monitors.brightness ?? 0)) / 100
    valueText: `${root.brightnessLive >= 0 ? root.brightnessLive : (root.monitors.brightness ?? 0)}%`
    onMoved: v => {
      root.brightnessLive = Math.max(1, Math.min(100, Math.round(v * 100)));
      if (!brightnessProc.running) {
        brightnessProc.command = [`${root.scripts}/skein-brightness-display`, "--no-osd", "--monitor", root.monitors.focused, `${root.brightnessLive}%`];
        brightnessProc.running = true;
      }
    }
  }

  SliderCard {
    visible: root.sink !== null
    title: "Sound"
    glyph: root.sink?.audio?.muted ? Skein.glyph(0xeee8) : Skein.glyph(0xf028)
    value: root.sink?.audio?.volume ?? 0
    valueText: root.sink?.audio?.muted ? "Muted" : `${Math.round((root.sink?.audio?.volume ?? 0) * 100)}%`
    chevron: true
    expanded: root.appsOpen
    onChevronClicked: root.appsOpen = !root.appsOpen
    onMoved: v => {
      if (root.sink?.audio) {
        root.sink.audio.volume = v;
      }
    }
    onGlyphClicked: {
      if (root.sink?.audio) {
        root.sink.audio.muted = !root.sink.audio.muted;
      }
    }
  }

  // Volume per app: one slider for each program that is playing sound
  Rectangle {
    visible: root.appsOpen
    width: parent.width
    height: root.streams.length === 0 ? 46 : Math.min(appList.implicitHeight + 16, 250)
    radius: 14
    color: Qt.alpha(Skein.foreground, 0.05)
    border.width: 1
    border.color: Qt.alpha(Skein.accent, 0.25)
    clip: true

    Text {
      visible: root.streams.length === 0
      anchors.centerIn: parent
      text: "No app is playing sound"
      color: Qt.alpha(Skein.foreground, 0.5)
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 0.5
    }

    Flickable {
      anchors.fill: parent
      anchors.margins: 8
      contentHeight: appList.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: appList

        width: parent.width
        spacing: 6

        Repeater {
          model: root.streams

          Item {
            id: appRow

            required property var modelData

            width: appList.width
            height: 40

            Image {
              id: appIcon

              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: 28
              height: 28
              source: root.appIcon(appRow.modelData)
              sourceSize: Qt.size(56, 56)
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              visible: status === Image.Ready
            }

            Rectangle {
              anchors.fill: appIcon
              visible: !appIcon.visible
              radius: 7
              color: Qt.alpha(Skein.accent, 0.6)

              Text {
                anchors.centerIn: parent
                text: root.appName(appRow.modelData).charAt(0).toUpperCase()
                color: Skein.background
                font.family: Skein.fontFamily
                font.pointSize: Skein.fontSize - 1
                font.bold: true
              }
            }

            Text {
              id: appLabel

              anchors.left: appIcon.right
              anchors.leftMargin: 10
              anchors.right: appPercent.left
              anchors.rightMargin: 8
              y: 2
              elide: Text.ElideRight
              text: root.appName(appRow.modelData)
              textFormat: Text.PlainText
              color: Skein.foreground
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize - 0.5
              font.bold: true
            }

            Text {
              id: appPercent

              anchors.right: appMute.left
              anchors.rightMargin: 8
              y: 2
              text: appRow.modelData.audio.muted ? "Muted" : `${Math.round(appRow.modelData.audio.volume * 100)}%`
              color: Qt.alpha(Skein.foreground, 0.6)
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize - 1.5
            }

            Text {
              id: appMute

              anchors.right: parent.right
              y: 1
              width: 22
              horizontalAlignment: Text.AlignHCenter
              text: appRow.modelData.audio.muted ? Skein.glyph(0xeee8) : Skein.glyph(0xf028)
              color: Skein.foreground
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize

              MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: appRow.modelData.audio.muted = !appRow.modelData.audio.muted
              }
            }

            PanelSlider {
              anchors.left: appIcon.right
              anchors.leftMargin: 10
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              value: appRow.modelData.audio.volume
              onMoved: v => appRow.modelData.audio.volume = v
            }
          }
        }
      }
    }
  }

  // Agent usage: session and weekly limits for each agent that reports them
  Rectangle {
    visible: root.shownProviders.length > 0
    width: parent.width
    height: agentsColumn.implicitHeight + 20
    radius: 14
    color: Qt.alpha(Skein.foreground, 0.07)
    border.width: 1
    border.color: Qt.alpha(Skein.accent, 0.25)

    Column {
      id: agentsColumn

      x: 14
      y: 10
      width: parent.width - 28
      spacing: 8

      Text {
        text: "Agents"
        color: Skein.foreground
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize
        font.bold: true
      }

      Repeater {
        model: root.shownProviders

        Column {
          id: provider

          required property var modelData

          width: agentsColumn.width
          spacing: 5

          Text {
            width: parent.width
            elide: Text.ElideRight
            text: provider.modelData.plan ? `${provider.modelData.name} · ${provider.modelData.plan}` : provider.modelData.name
            color: Qt.alpha(Skein.foreground, 0.7)
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize - 1
          }

          Repeater {
            model: provider.modelData.limits

            Item {
              id: limitRow

              required property var modelData

              width: provider.width
              height: 18

              Text {
                id: limitLabel

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 56
                text: limitRow.modelData.label
                color: Skein.foreground
                font.family: Skein.fontFamily
                font.pointSize: Skein.fontSize - 1
              }

              Rectangle {
                anchors.left: limitLabel.right
                anchors.right: limitPercent.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 5
                radius: 2.5
                color: Qt.alpha(Skein.foreground, 0.15)

                Rectangle {
                  width: parent.width * Math.max(0, Math.min(1, limitRow.modelData.percent / 100))
                  height: parent.height
                  radius: 2.5
                  color: root.limitColor(limitRow.modelData.percent)
                }
              }

              Text {
                id: limitPercent

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 78
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(limitRow.modelData.percent)}% · ${root.formatReset(limitRow.modelData.resetsAt)}`
                color: Qt.alpha(Skein.foreground, 0.7)
                font.family: Skein.fontFamily
                font.pointSize: Skein.fontSize - 1.5
              }
            }
          }

          Text {
            visible: provider.modelData.limits.length === 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: provider.modelData.limitsNote || "No limits reported"
            color: Qt.alpha(Skein.foreground, 0.5)
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize - 1.5
          }
        }
      }
    }
  }

  Row {
    width: parent.width
    spacing: 8

    Repeater {
      model: [
        {
          text: "Settings…",
          action: "settings"
        },
        {
          text: "Classic bar",
          action: "classic"
        }
      ]

      Rectangle {
        required property var modelData

        width: (parent.width - parent.spacing) / 2
        height: 32
        radius: 10
        color: buttonMouse.containsMouse ? Qt.alpha(Skein.accent, 0.25) : Qt.alpha(Skein.foreground, 0.06)
        border.width: 1
        border.color: Qt.alpha(Skein.accent, 0.5)

        Text {
          anchors.centerIn: parent
          text: modelData.text
          color: Skein.foreground
          font.family: Skein.fontFamily
          font.pointSize: Skein.fontSize - 0.5
        }

        MouseArea {
          id: buttonMouse

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (modelData.action === "settings") {
              root.openSettings("menubar");
            } else {
              // Back to the row of indicators
              root.open = false;
              Skein.setBar("controlCenter", false);
            }
          }
        }
      }
    }
  }

  PwObjectTracker {
    objects: [root.sink, ...root.streams]
  }
}
