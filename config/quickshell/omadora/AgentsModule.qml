import QtQuick
import Quickshell.Hyprland

// Coding agent usage: click opens the agents panel. Hidden when no agent is found.
BarItem {
  id: root

  required property var barWindow

  text: panel.providers.length > 0 ? Omadora.glyph(0xf06a9) : ""
  tooltip: panel.summary
  onLeftClicked: panel.toggle()
  onRightClicked: Omadora.run("omadora-exec omadora-agent --pick")

  Connections {
    target: Omadora

    function onPanelRequested(name) {
      if (name === "agents" && (panel.open || root.barWindow.screen.name === Hyprland.focusedMonitor?.name)) {
        panel.toggle();
      }
    }
  }

  AgentsPanel {
    id: panel

    barWindow: root.barWindow
  }
}
