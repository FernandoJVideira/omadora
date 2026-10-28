import QtQuick

// Settings > Windows: tiling layout, gaps and window shape.
SettingsPage {
  id: root

  readonly property var sys: backend?.sysState ?? ({})

  SettingsSection {
    title: "Layout"

    ComboRow {
      label: "Workspace layout"
      description: "For the current workspace"
      options: [
        {
          label: "Dwindle",
          value: "dwindle"
        },
        {
          label: "Scrolling",
          value: "scrolling"
        }
      ]
      current: root.sys.layout ?? "dwindle"
      onChosen: value => {
        if (value !== root.sys.layout) {
          root.backend.set("layout", value, "skein-hyprland-workspace-layout-toggle");
        }
      }
    }

    SwitchRow {
      label: "Window gaps"
      checked: root.sys.gaps ?? true
      onToggled: value => root.backend.set("gaps", value, "skein-hyprland-window-gaps-toggle")
    }

    SwitchRow {
      label: "Square single window"
      description: "Keep a lone window at a 1:1 aspect ratio"
      checked: root.sys.squareAspect ?? false
      onToggled: value => root.backend.set("squareAspect", value, "skein-hyprland-window-single-square-aspect-toggle")
    }
  }

  SettingsSection {
    title: "Notifications"

    SwitchRow {
      label: "Silence notifications"
      checked: Skein.silenced
      onToggled: value => Skein.silenced = value
    }
  }
}
