import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Connection details, DNS provider, Wi-Fi band and Wi-Fi networks.
Panel {
  id: root

  required property var module // the bar module: live link state and rates

  property var info: ({}) // from omadora-network-info
  property string pingText: "…"
  property string lossText: "…"
  property string speedText: ""
  property bool testing: false
  property string qrPath: ""
  property bool customDns: false
  property var pending: null // secured network waiting for a password
  property string failure: ""

  readonly property string mono: "JetBrainsMono Nerd Font"
  readonly property bool isWifi: info.type === "wifi"
  readonly property var net: module.net
  readonly property var wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null
  readonly property var networks: {
    const list = wifiDevice ? [...wifiDevice.networks.values] : [];
    return list.sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength));
  }
  readonly property var knownNetworks: networks.filter(n => n.known || n.connected)
  readonly property var otherNetworks: networks.filter(n => !n.known && !n.connected)
  readonly property string title: net.type === "wifi" ? (net.essid || info.connection || "Wi-Fi") : (info.connection || (net.type === "ethernet" ? "Ethernet" : "Disconnected"))

  function secured(network: var): bool {
    return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
  }

  function signalGlyph(strength: real): string {
    const icons = [0xf092f, 0xf091f, 0xf0922, 0xf0925, 0xf0928];
    return Omadora.glyph(icons[Math.min(icons.length - 1, Math.floor(strength * icons.length))]);
  }

  function formatBytes(bytes: real): string {
    const units = ["B", "kB", "MB", "GB", "TB"];
    let unit = 0;
    while (bytes >= 1000 && unit < units.length - 1) {
      bytes /= 1000;
      unit++;
    }
    return `${bytes.toFixed(unit < 2 ? 0 : 2)} ${units[unit]}`;
  }

  function activate(network: var): void {
    root.failure = "";
    if (network.connected) {
      network.disconnect();
    } else if (!network.known && secured(network)) {
      root.pending = network;
    } else {
      network.connect();
    }
  }

  function script(name: string, args: var): void {
    Quickshell.execDetached([`${Omadora.omadoraPath}/libexec/${name}`, ...args]);
    refresh.restart();
  }

  function setDns(provider: string, servers: string): void {
    script("omadora-network-dns", [info.connection, provider, ...(servers ? [servers] : [])]);
  }

  onOpenChanged: {
    if (open) {
      info = {};
      pingText = "…";
      lossText = "…";
      infoProc.running = true;
      pingProc.running = true;
    } else {
      pending = null;
      failure = "";
      customDns = false;
      speedText = "";
      qrPath = "";
      Quickshell.execDetached(["rm", "-f", `${Quickshell.env("XDG_RUNTIME_DIR")}/omadora-wifi-qr.png`]);
    }
  }

  Process {
    id: infoProc

    command: [`${Omadora.omadoraPath}/libexec/bar/omadora-network-info`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.info = JSON.parse(text.trim());
        } catch (e) {
          root.info = {};
        }
      }
    }
  }

  Process {
    id: pingProc

    command: ["ping", "-n", "-c", "4", "-i", "0.25", "-W", "1", "1.1.1.1"]
    stdout: StdioCollector {
      onStreamFinished: {
        const loss = text.match(/([\d.]+)% packet loss/);
        const rtt = text.match(/= [\d.]+\/([\d.]+)\//);
        root.lossText = loss ? `${loss[1]}%` : "—";
        root.pingText = rtt ? `${Math.round(Number(rtt[1]))} ms` : "—";
      }
    }
  }

  Process {
    id: speedProc

    command: [`${Omadora.omadoraPath}/libexec/omadora-network-speedtest`]
    stdout: StdioCollector {
      onStreamFinished: {
        root.testing = false;
        try {
          const result = JSON.parse(text.trim());
          root.speedText = `Speed test  ↓ ${result.down.toFixed(1)} Mb/s   ↑ ${result.up.toFixed(1)} Mb/s`;
        } catch (e) {
          root.speedText = "Speed test failed";
        }
      }
    }
  }

  Process {
    id: qrProc

    command: [`${Omadora.omadoraPath}/libexec/omadora-network-qr`, root.info.connection ?? ""]
    stdout: StdioCollector {
      onStreamFinished: root.qrPath = text.trim() !== "" ? `file://${text.trim()}?${Date.now()}` : ""
    }
  }

  // Re-read details and ping while open, and shortly after a change is applied
  Timer {
    interval: 5000
    running: root.open
    repeat: true
    onTriggered: {
      infoProc.running = true;
      pingProc.running = true;
    }
  }

  Timer {
    id: refresh

    interval: 1500
    onTriggered: infoProc.running = true
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

  component Stat: Item {
    property string label
    property string value

    width: (parent.width - parent.columnSpacing) / 2
    height: 20

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: parent.label
      color: Qt.alpha(Omadora.foreground, 0.6)
      font.family: Omadora.fontFamily
      font.pointSize: Omadora.fontSize - 1
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      text: parent.value
      color: Omadora.foreground
      font.family: root.mono
      font.pointSize: Omadora.fontSize - 1
    }
  }

  component Switch: Rectangle {
    id: sw

    property bool on: false

    signal toggled

    width: 44
    height: 22
    color: on ? Qt.alpha(Omadora.accent, 0.35) : Qt.alpha(Omadora.foreground, 0.12)
    border.width: 1
    border.color: Qt.alpha(Omadora.foreground, 0.25)

    Rectangle {
      x: sw.on ? parent.width - width - 3 : 3
      anchors.verticalCenter: parent.verticalCenter
      width: 14
      height: 14
      color: Omadora.foreground
    }

    MouseArea {
      anchors.fill: parent
      onClicked: sw.toggled()
    }
  }

  component IconButton: Text {
    signal clicked

    color: Omadora.foreground
    opacity: mouse.containsMouse ? 1 : 0.7
    font.family: Omadora.fontFamily
    font.pointSize: Omadora.fontSize + 3

    MouseArea {
      id: mouse

      anchors.fill: parent
      anchors.margins: -4
      hoverEnabled: true
      onClicked: parent.clicked()
    }
  }

  component ProviderButton: Rectangle {
    id: button

    property string text
    property bool active: false

    signal clicked

    width: (parent.width - 3 * parent.spacing) / 4
    height: 32
    color: active ? Qt.alpha(Omadora.foreground, 0.14) : (mouse.containsMouse ? Qt.alpha(Omadora.foreground, 0.06) : "transparent")
    border.width: 1
    border.color: Qt.alpha(Omadora.foreground, active ? 0.5 : 0.25)

    Text {
      anchors.centerIn: parent
      text: button.text
      color: Omadora.foreground
      font.family: root.mono
      font.pointSize: Omadora.fontSize - 1.5
    }

    MouseArea {
      id: mouse

      anchors.fill: parent
      hoverEnabled: true
      onClicked: button.clicked()
    }
  }

  component NetworkRow: Column {
    id: entry

    required property var network
    property bool known: false

    width: parent.width

    Rectangle {
      width: parent.width
      height: 38
      color: entry.network.connected ? Qt.alpha(Omadora.foreground, 0.12) : (mouse.containsMouse ? Qt.alpha(Omadora.foreground, 0.06) : "transparent")

      Text {
        id: icon

        anchors.verticalCenter: parent.verticalCenter
        x: 8
        text: root.signalGlyph(entry.network.signalStrength)
        color: Omadora.foreground
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.fontSize + 1
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        x: icon.x + 32
        width: parent.width - x - 60

        Text {
          width: parent.width
          elide: Text.ElideRight
          text: entry.network.name
          textFormat: Text.PlainText
          color: Omadora.foreground
          font.family: Omadora.fontFamily
          font.pointSize: Omadora.fontSize
        }

        Text {
          visible: text !== ""
          text: entry.network.connected ? "Connected" : (entry.network.state === ConnectionState.Connecting ? "Connecting…" : "")
          color: Qt.alpha(Omadora.foreground, 0.6)
          font.family: Omadora.fontFamily
          font.pointSize: Omadora.fontSize - 2
        }
      }

      Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 10
        spacing: 10

        Text {
          visible: entry.known && !entry.network.connected
          text: Omadora.glyph(0xf1f8)
          color: Qt.alpha(Omadora.foreground, 0.6)
          font.family: Omadora.fontFamily
          font.pointSize: Omadora.fontSize - 1

          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            onClicked: entry.network.forget()
          }
        }

        Text {
          visible: root.secured(entry.network)
          text: Omadora.glyph(0xf023)
          color: Qt.alpha(Omadora.foreground, 0.6)
          font.family: Omadora.fontFamily
          font.pointSize: Omadora.fontSize - 1
        }
      }

      MouseArea {
        id: mouse

        anchors.fill: parent
        z: -1
        hoverEnabled: true
        onClicked: root.activate(entry.network)
      }
    }

    Rectangle {
      visible: root.pending === entry.network
      width: parent.width
      height: visible ? 32 : 0
      color: "transparent"
      border.width: 1
      border.color: Qt.alpha(Omadora.accent, 0.5)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        x: 8
        visible: password.text === ""
        text: "Password"
        color: Qt.alpha(Omadora.foreground, 0.5)
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.fontSize
      }

      TextInput {
        id: password

        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        verticalAlignment: TextInput.AlignVCenter
        echoMode: TextInput.Password
        color: Omadora.foreground
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.fontSize
        focus: visible
        onVisibleChanged: if (visible) {
          text = "";
          forceActiveFocus();
        }
        onAccepted: {
          if (text !== "") {
            entry.network.connectWithPsk(text);
            root.pending = null;
          }
        }
      }
    }

    Connections {
      target: entry.network

      function onConnectionFailed(reason) {
        root.failure = reason === ConnectionFailReason.NoSecrets ? `Wrong password for ${entry.network.name}` : `Could not connect to ${entry.network.name}`;
      }
    }
  }

  // Header
  Item {
    width: parent.width
    height: 40

    Text {
      id: headIcon

      anchors.verticalCenter: parent.verticalCenter
      text: root.net.type === "wifi" ? root.signalGlyph((root.net.signal ?? 0) / 100) : (root.net.type === "ethernet" ? Omadora.glyph(0xf0002) : Omadora.glyph(0xf092e))
      color: Qt.alpha(Omadora.foreground, 0.7)
      font.family: Omadora.fontFamily
      font.pointSize: Omadora.fontSize + 6
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      x: headIcon.width + 14
      width: parent.width - x - actions.width - 8
      spacing: 2

      Text {
        width: parent.width
        elide: Text.ElideRight
        text: root.title
        textFormat: Text.PlainText
        color: Omadora.foreground
        font.family: Omadora.fontFamily
        font.pointSize: Omadora.fontSize + 1.5
        font.bold: true
      }

      Caption {
        width: parent.width
        elide: Text.ElideRight
        text: (root.speedText !== "" ? root.speedText : (root.testing ? "Testing…" : [root.info.iface, root.info.band].filter(part => part).join("  ·  "))).toUpperCase()
      }
    }

    Row {
      id: actions

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 14

      IconButton {
        visible: root.info.qr === true
        anchors.verticalCenter: parent.verticalCenter
        text: Omadora.glyph(0xf0432)
        onClicked: {
          if (root.qrPath !== "") {
            root.qrPath = "";
          } else {
            qrProc.running = true;
          }
        }
      }

      IconButton {
        visible: root.net.type !== "disconnected"
        anchors.verticalCenter: parent.verticalCenter
        text: Omadora.glyph(0xf04c5)
        onClicked: {
          if (!root.testing) {
            root.testing = true;
            root.speedText = "";
            speedProc.running = true;
          }
        }
      }

      Switch {
        visible: root.wifiDevice !== null
        anchors.verticalCenter: parent.verticalCenter
        on: Networking.wifiEnabled
        onToggled: {
          if (Networking.wifiHardwareEnabled) {
            Networking.wifiEnabled = !Networking.wifiEnabled;
          }
        }
      }
    }
  }

  Image {
    visible: root.qrPath !== ""
    anchors.horizontalCenter: parent.horizontalCenter
    width: visible ? 180 : 0
    height: visible ? 180 : 0
    source: root.qrPath
    cache: false
    smooth: false
  }

  Divider {}

  Grid {
    columns: 2
    columnSpacing: 24
    rowSpacing: 4
    width: parent.width

    Stat {
      label: "Ping"
      value: root.pingText
    }
    Stat {
      label: "Packet Loss"
      value: root.lossText
    }
    Stat {
      label: "Receiving"
      value: `${root.module.formatRate(root.module.down)}`
    }
    Stat {
      label: "Sending"
      value: `${root.module.formatRate(root.module.up)}`
    }
    Stat {
      label: "Downloaded"
      value: root.formatBytes(root.net.rx ?? 0)
    }
    Stat {
      label: "Uploaded"
      value: root.formatBytes(root.net.tx ?? 0)
    }
    Stat {
      label: "IP Address"
      value: root.info.ip ?? "—"
    }
    Stat {
      label: "Gateway"
      value: root.info.gateway ?? "—"
    }
  }

  // Wi-Fi band preference, for a connected Wi-Fi network
  Divider {
    visible: root.isWifi && root.info.band !== ""
  }

  Item {
    visible: root.isWifi && root.info.band !== ""
    width: parent.width
    height: visible ? 22 : 0

    Caption {
      anchors.verticalCenter: parent.verticalCenter
      text: `WI-FI BAND: ${(root.info.band ?? "").toUpperCase().replace(" ", "")}`
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 10

      Caption {
        anchors.verticalCenter: parent.verticalCenter
        text: "AUTOMATIC"
      }

      Switch {
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 16
        on: root.info.bandMode === "auto"
        onToggled: {
          if (on) {
            // Lock to the band in use
            root.script("omadora-network-band", [root.info.connection, root.info.band === "2.4 GHz" ? "bg" : "a"]);
          } else {
            root.script("omadora-network-band", [root.info.connection, "auto"]);
          }
        }
      }
    }
  }

  Divider {}

  Caption {
    text: "DNS PROVIDER"
  }

  Row {
    width: parent.width
    spacing: 6

    ProviderButton {
      text: "DHCP"
      active: root.info.dnsMode === "dhcp"
      onClicked: {
        root.customDns = false;
        root.setDns("dhcp", "");
      }
    }
    ProviderButton {
      text: "Cloudflare"
      active: root.info.dnsMode === "cloudflare"
      onClicked: {
        root.customDns = false;
        root.setDns("cloudflare", "");
      }
    }
    ProviderButton {
      text: "Google"
      active: root.info.dnsMode === "google"
      onClicked: {
        root.customDns = false;
        root.setDns("google", "");
      }
    }
    ProviderButton {
      text: "Custom"
      active: root.info.dnsMode === "custom" || root.customDns
      onClicked: root.customDns = true
    }
  }

  Rectangle {
    visible: root.customDns
    width: parent.width
    height: visible ? 32 : 0
    color: "transparent"
    border.width: 1
    border.color: Qt.alpha(Omadora.accent, 0.5)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      x: 8
      visible: customInput.text === ""
      text: "DNS servers, e.g. 9.9.9.9, 149.112.112.112"
      color: Qt.alpha(Omadora.foreground, 0.5)
      font.family: Omadora.fontFamily
      font.pointSize: Omadora.fontSize - 1
    }

    TextInput {
      id: customInput

      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      verticalAlignment: TextInput.AlignVCenter
      color: Omadora.foreground
      font.family: Omadora.fontFamily
      font.pointSize: Omadora.fontSize
      focus: visible
      onVisibleChanged: if (visible) {
        text = root.info.dnsMode === "custom" ? (root.info.dns ?? []).join(", ") : "";
        forceActiveFocus();
      }
      onAccepted: {
        if (text !== "") {
          root.setDns("custom", text);
          root.customDns = false;
        }
      }
    }
  }

  // Wi-Fi networks
  Divider {
    visible: root.wifiDevice !== null && Networking.wifiEnabled
  }

  Text {
    visible: root.failure !== ""
    width: parent.width
    text: root.failure
    wrapMode: Text.Wrap
    color: Omadora.alert
    font.family: Omadora.fontFamily
    font.pointSize: Omadora.fontSize
  }

  Caption {
    visible: root.knownNetworks.length > 0 && root.wifiDevice !== null && Networking.wifiEnabled
    text: "KNOWN NETWORKS"
  }

  Column {
    visible: root.wifiDevice !== null && Networking.wifiEnabled
    width: parent.width

    Repeater {
      model: root.knownNetworks

      NetworkRow {
        required property var modelData

        network: modelData
        known: true
      }
    }
  }

  Caption {
    visible: root.otherNetworks.length > 0 && root.wifiDevice !== null && Networking.wifiEnabled
    text: "OTHER NETWORKS"
  }

  Flickable {
    visible: root.wifiDevice !== null && Networking.wifiEnabled && root.otherNetworks.length > 0
    width: parent.width
    height: Math.min(others.implicitHeight, 190)
    contentHeight: others.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: others

      width: parent.width

      Repeater {
        model: root.otherNetworks

        NetworkRow {
          required property var modelData

          network: modelData
        }
      }
    }
  }

  Caption {
    visible: root.wifiDevice === null
    text: "NO WI-FI ADAPTER"
  }

  // Only scan while the panel is open
  Binding {
    target: root.wifiDevice
    property: "scannerEnabled"
    value: root.open
    when: root.wifiDevice !== null
  }
}
