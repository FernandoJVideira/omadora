import QtQuick
import Quickshell.Io

// CPU icon with current usage in the tooltip; click opens the system monitor.
BarItem {
  id: root

  property var last: null // { idle, total }
  property int usage: 0

  function update(stat: string): void {
    const fields = stat.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
    const idle = fields[3] + (fields[4] ?? 0);
    const total = fields.reduce((sum, value) => sum + value, 0);
    if (last && total > last.total) {
      usage = Math.round(100 * (1 - (idle - last.idle) / (total - last.total)));
    }
    last = { idle: idle, total: total };
  }

  text: Omadora.glyph(0xf035b)
  tooltip: `CPU ${usage}%`
  onLeftClicked: Omadora.run("omadora-exec omadora-launch-system-monitor")
  onRightClicked: Omadora.run("xdg-terminal-exec")

  FileView {
    id: stat

    path: "/proc/stat"
    onLoaded: root.update(text())
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: stat.reload()
  }
}
