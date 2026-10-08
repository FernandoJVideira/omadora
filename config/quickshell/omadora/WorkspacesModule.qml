import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland workspaces on this bar's monitor, with 1-5 always shown unless
// another monitor owns them (e.g. 6-10 pinned to the second screen).
Row {
  id: root

  required property var screen

  readonly property var monitor: Hyprland.monitorFor(screen)
  readonly property var persistent: [1, 2, 3, 4, 5]

  readonly property var workspaceIds: {
    const ids = new Set(persistent.filter(id => {
      const ws = Hyprland.workspaces.values.find(w => w.id === id);
      return !ws || !ws.monitor || ws.monitor === monitor;
    }));
    for (const ws of Hyprland.workspaces.values) {
      if (ws.id > 0 && (!ws.monitor || ws.monitor === monitor)) {
        ids.add(ws.id);
      }
    }
    return Array.from(ids).sort((a, b) => a - b);
  }

  height: parent ? parent.height : Omadora.barHeight

  function label(id: int): string {
    if (id >= 1 && id <= 9) {
      return String(id);
    }
    return id === 10 ? "0" : Omadora.glyph(0xea71);
  }

  Repeater {
    model: root.workspaceIds

    BarItem {
      required property int modelData

      readonly property var workspace: Hyprland.workspaces.values.find(ws => ws.id === modelData) ?? null
      readonly property bool active: workspace !== null && root.monitor !== null && root.monitor.activeWorkspace === workspace

      text: active ? Omadora.glyph(0xf14fb) : root.label(modelData)
      dimmed: workspace === null || workspace.toplevels.values.length === 0
      onLeftClicked: Hyprland.dispatch(`workspace ${modelData}`)
    }
  }
}
