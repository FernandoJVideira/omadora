import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Settings > Network: Wi-Fi switch and saved or open networks.
SettingsPage {
  id: root

  readonly property var wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null
  readonly property var networks: {
    const list = wifiDevice ? [...wifiDevice.networks.values] : [];
    return list.sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength));
  }

  // Details of the connection, read live while the page is open
  property var info: ({})
  property var net: ({})
  property var last: null // {iface, rx, tx, time}
  property real down: 0 // bytes/s
  property real up: 0
  property string pingText: "…"
  property string lossText: "…"
  property string speedText: ""
  property bool testing: false

  function formatBytes(bytes: real): string {
    const units = ["B", "kB", "MB", "GB", "TB"];
    let unit = 0;
    while (bytes >= 1000 && unit < units.length - 1) {
      bytes /= 1000;
      unit++;
    }
    return `${bytes.toFixed(unit < 2 ? 0 : 2)} ${units[unit]}`;
  }

  function formatRate(bytes: real): string {
    return `${formatBytes(bytes)}/s`;
  }

  function setDns(provider: string, servers: string): void {
    Quickshell.execDetached([`${Skein.skeinPath}/libexec/skein-network-dns`, info.connection, provider, ...(servers ? [servers] : [])]);
    infoTimer.restart();
  }

  function secured(network: var): bool {
    return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
  }

  Component.onCompleted: {
    infoProc.running = true;
    rateProc.running = true;
    pingProc.running = true;
  }

  Process {
    id: infoProc

    command: [`${Skein.skeinPath}/libexec/bar/skein-network-info`]
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

  // Byte counters, sampled for the transfer rates
  Process {
    id: rateProc

    command: [`${Skein.skeinPath}/libexec/bar/skein-bar-network`]
    stdout: StdioCollector {
      onStreamFinished: {
        let next;
        try {
          next = JSON.parse(text.trim());
        } catch (e) {
          next = {
            type: "disconnected"
          };
        }
        const now = Date.now();
        if (next.type !== "disconnected" && root.last && root.last.iface === next.iface) {
          const seconds = (now - root.last.time) / 1000;
          root.down = Math.max(0, (next.rx - root.last.rx) / seconds);
          root.up = Math.max(0, (next.tx - root.last.tx) / seconds);
        } else {
          root.down = 0;
          root.up = 0;
        }
        root.last = next.type === "disconnected" ? null : {
          iface: next.iface,
          rx: next.rx,
          tx: next.tx,
          time: now
        };
        root.net = next;
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

    command: [`${Skein.skeinPath}/libexec/skein-network-speedtest`]
    stdout: StdioCollector {
      onStreamFinished: {
        root.testing = false;
        try {
          const result = JSON.parse(text.trim());
          root.speedText = `↓ ${result.down.toFixed(1)} Mb/s   ↑ ${result.up.toFixed(1)} Mb/s`;
        } catch (e) {
          root.speedText = "Speed test failed";
        }
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: if (!rateProc.running) {
      rateProc.running = true;
    }
  }

  Timer {
    id: infoTimer

    interval: 5000
    running: true
    repeat: true
    onTriggered: {
      if (!infoProc.running) {
        infoProc.running = true;
      }
      if (!pingProc.running) {
        pingProc.running = true;
      }
    }
  }

  SettingsSection {
    title: root.info.connection ? `${root.info.connection} · ${root.info.iface}` : "Connection"

    InfoRow {
      label: "Status"
      value: root.info.iface ? (root.info.type === "wifi" ? "Wi-Fi" : "Ethernet") : "Disconnected"
    }

    InfoRow {
      label: "Ping"
      value: root.pingText
    }

    InfoRow {
      label: "Packet loss"
      value: root.lossText
    }

    InfoRow {
      label: "Receiving"
      value: root.formatRate(root.down)
    }

    InfoRow {
      label: "Sending"
      value: root.formatRate(root.up)
    }

    InfoRow {
      label: "Downloaded"
      value: root.formatBytes(root.net.rx ?? 0)
    }

    InfoRow {
      label: "Uploaded"
      value: root.formatBytes(root.net.tx ?? 0)
    }

    InfoRow {
      label: "IP address"
      value: root.info.ip ?? ""
    }

    InfoRow {
      label: "Gateway"
      value: root.info.gateway ?? ""
    }

    InfoRow {
      label: "DNS servers"
      value: (root.info.dns ?? []).join(", ")
    }

    ButtonRow {
      label: "Speed test"
      description: root.testing ? "Testing…" : root.speedText
      buttonText: "Run"
      enabled: !root.testing && !!root.info.iface
      onClicked: {
        root.testing = true;
        root.speedText = "";
        speedProc.running = true;
      }
    }
  }

  SettingsSection {
    title: "DNS"
    visible: !!root.info.connection

    ComboRow {
      label: "DNS provider"
      description: "DHCP uses what your router hands out"
      options: [
        {
          label: "DHCP",
          value: "dhcp"
        },
        {
          label: "Cloudflare",
          value: "cloudflare"
        },
        {
          label: "Google",
          value: "google"
        },
        {
          label: "Custom",
          value: "custom"
        }
      ]
      current: root.info.dnsMode ?? "dhcp"
      onChosen: value => {
        if (value === "custom") {
          customDns.visible = true;
        } else {
          customDns.visible = false;
          root.setDns(value, "");
        }
      }
    }

    TextInputRow {
      id: customDns

      visible: (root.info.dnsMode ?? "") === "custom"
      label: "Custom servers"
      description: "IP addresses separated by commas, then Enter"
      placeholder: "9.9.9.9, 149.112.112.112"
      text: (root.info.dnsMode ?? "") === "custom" ? (root.info.dns ?? []).join(", ") : ""
      onAccepted: value => root.setDns("custom", value)
    }
  }

  SettingsSection {
    title: "Wi-Fi"

    SwitchRow {
      label: "Wi-Fi"
      checked: Networking.wifiEnabled
      enabled: Networking.wifiHardwareEnabled && root.wifiDevice !== null
      description: root.wifiDevice === null ? "No Wi-Fi adapter" : (Networking.wifiHardwareEnabled ? "" : "Turned off by a hardware switch")
      onToggled: value => Networking.wifiEnabled = value
    }
  }

  SettingsSection {
    title: "Networks"
    visible: Networking.wifiEnabled && root.networks.length > 0

    Repeater {
      model: root.networks

      SettingsRow {
        required property var modelData

        label: modelData.name
        description: modelData.connected ? "Connected" : (modelData.known ? "Saved" : (root.secured(modelData) ? "Needs a password" : "Open"))

        Row {
          spacing: 6

          Rectangle {
            visible: modelData.known && !modelData.connected
            width: forgetText.implicitWidth + 24
            height: Math.round(24 * Skein.textScale)
            radius: Skein.radiusInner
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Skein.foreground, 0.3)

            Text {
              id: forgetText

              anchors.centerIn: parent
              text: "Forget"
              color: Skein.foreground
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize - 0.5
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: modelData.forget()
            }
          }

          Rectangle {
            visible: modelData.connected || modelData.known || !root.secured(modelData)
            width: actionText.implicitWidth + 24
            height: Math.round(24 * Skein.textScale)
            radius: Skein.radiusInner
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Skein.accent, 0.7)

            Text {
              id: actionText

              anchors.centerIn: parent
              text: modelData.connected ? "Disconnect" : "Connect"
              color: Skein.foreground
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize - 0.5
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            }
          }
        }
      }
    }
  }

  SettingsSection {
    title: "More"

    ButtonRow {
      label: "Network panel"
      description: "Join new secured networks, DNS, band and speed test"
      buttonText: "Open"
      onClicked: {
        root.backend.close();
        Quickshell.execDetached(["qs", "-c", "skein", "ipc", "call", "bar", "panel", "network"]);
      }
    }
  }
}
