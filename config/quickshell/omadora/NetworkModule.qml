import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

// Wi-Fi signal / ethernet / disconnected, with bandwidth in the tooltip.
// Uses a small script so it works with both NetworkManager and iwd/systemd-networkd.
BarItem {
  id: root

  required property var barWindow

  readonly property var wifiIcons: [0xf092f, 0xf091f, 0xf0922, 0xf0925, 0xf0928]

  property var net: ({ type: "disconnected" })
  property real down: 0 // bytes/s
  property real up: 0
  property var last: null // { iface, rx, tx, time }

  function formatRate(bytes: real): string {
    const units = ["B/s", "kB/s", "MB/s", "GB/s"];
    let unit = 0;
    while (bytes >= 1000 && unit < units.length - 1) {
      bytes /= 1000;
      unit++;
    }
    return `${bytes.toFixed(unit === 0 ? 0 : 1)}${units[unit]}`;
  }

  function update(output: string): void {
    let next;
    try {
      next = JSON.parse(output.trim());
    } catch (e) {
      next = { type: "disconnected" };
    }
    const now = Date.now();
    if (next.type !== "disconnected" && last && last.iface === next.iface) {
      const seconds = (now - last.time) / 1000;
      down = Math.max(0, (next.rx - last.rx) / seconds);
      up = Math.max(0, (next.tx - last.tx) / seconds);
    } else {
      down = 0;
      up = 0;
    }
    last = next.type === "disconnected" ? null : { iface: next.iface, rx: next.rx, tx: next.tx, time: now };
    net = next;
  }

  text: {
    switch (net.type) {
    case "wifi":
      const index = Math.min(wifiIcons.length - 1, Math.floor((net.signal ?? 0) * wifiIcons.length / 100));
      return Omadora.glyph(wifiIcons[Math.max(0, index)]);
    case "ethernet":
      return Omadora.glyph(0xf0002);
    default:
      return Omadora.glyph(0xf092e);
    }
  }
  tooltip: {
    const rates = `⇣${formatRate(down)}  ⇡${formatRate(up)}`;
    switch (net.type) {
    case "wifi":
      const frequency = net.frequency ? ` (${(net.frequency / 1000).toFixed(1)} GHz)` : "";
      return `${net.essid || net.iface}${frequency}\n${rates}`;
    case "ethernet":
      return rates;
    default:
      return "Disconnected";
    }
  }
  onLeftClicked: panel.toggle()

  Connections {
    target: Omadora

    function onPanelRequested(name) {
      if (name === "network" && (panel.open || root.barWindow.screen.name === Hyprland.focusedMonitor?.name)) {
        panel.toggle();
      }
    }
  }

  NetworkPanel {
    id: panel

    barWindow: root.barWindow
    module: root
    panelWidth: 380
  }

  Process {
    id: proc

    command: [`${Omadora.omadoraPath}/libexec/bar/omadora-bar-network`]
    stdout: StdioCollector {
      onStreamFinished: root.update(text)
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: proc.running = true
  }
}
