import QtQuick
import Quickshell

// Settings > Dock: turn the dock on, how it looks and behaves, and which apps it holds.
SettingsPage {
  id: root

  readonly property string search: searchRow.text.trim().toLowerCase()
  // Installed apps that are not in the dock yet, filtered by the search box
  readonly property var available: DesktopEntries.applications.values.filter(e => !e.noDisplay && !DockConfig.pinned.includes(e.id) && (search === "" || e.name.toLowerCase().includes(search))).sort((a, b) => a.name.localeCompare(b.name)).slice(0, 8)

  SettingsSection {
    title: "Dock"

    SwitchRow {
      label: "Show dock"
      description: "A dock with your pinned and running apps"
      checked: DockConfig.enabled
      onToggled: value => DockConfig.set("enabled", value)
    }

    SwitchRow {
      label: "Automatically hide"
      description: "Slides away until you move the pointer to the screen edge"
      checked: DockConfig.autoHide
      onToggled: value => DockConfig.set("autoHide", value)
    }

    ComboRow {
      label: "Position on screen"
      options: [
        {
          label: "Bottom",
          value: "bottom"
        },
        {
          label: "Left",
          value: "left"
        },
        {
          label: "Right",
          value: "right"
        }
      ]
      current: DockConfig.position
      onChosen: value => DockConfig.set("position", value)
    }

    SliderRow {
      label: "Size"
      valueText: `${DockConfig.iconSize} px`
      value: (DockConfig.iconSize - 28) / 84
      onMoved: v => DockConfig.set("iconSize", Math.round(28 + v * 84))
    }

    SwitchRow {
      label: "Magnification"
      description: "Icons grow as the pointer passes over them"
      checked: DockConfig.magnify
      onToggled: value => DockConfig.set("magnify", value)
    }

    SliderRow {
      visible: DockConfig.magnify
      label: "Magnified size"
      valueText: `${DockConfig.magnifySize} px`
      value: (DockConfig.magnifySize - 40) / 120
      onMoved: v => DockConfig.set("magnifySize", Math.max(DockConfig.iconSize, Math.round(40 + v * 120)))
    }

    SwitchRow {
      label: "Show running apps"
      description: "Apps that are open but not kept in the dock appear after a divider"
      checked: DockConfig.showRunning
      onToggled: value => DockConfig.set("showRunning", value)
    }

    SwitchRow {
      label: "Show indicators for open apps"
      checked: DockConfig.showIndicators
      onToggled: value => DockConfig.set("showIndicators", value)
    }
  }

  SettingsSection {
    title: "Apps in the dock"

    SettingsRow {
      visible: DockConfig.pinned.length === 0
      label: "Nothing kept in the dock yet"
      description: "Add apps below, or right-click an open app in the dock and choose Keep in Dock"
    }

    Repeater {
      model: DockConfig.pinned

      AppRow {
        id: pinnedRow

        required property string modelData
        required property int index

        entry: DesktopEntries.byId(modelData) ?? DesktopEntries.heuristicLookup(modelData)
        fallbackName: modelData

        Row {
          spacing: 6

          SmallButton {
            text: "◀"
            enabled: pinnedRow.index > 0
            onClicked: DockConfig.move(pinnedRow.modelData, -1)
          }

          SmallButton {
            text: "▶"
            enabled: pinnedRow.index < DockConfig.pinned.length - 1
            onClicked: DockConfig.move(pinnedRow.modelData, 1)
          }

          SmallButton {
            text: "Remove"
            onClicked: DockConfig.unpin(pinnedRow.modelData)
          }
        }
      }
    }
  }

  SettingsSection {
    title: "Add an app"

    TextInputRow {
      id: searchRow

      label: "Search installed apps"
      placeholder: "name"
    }

    Repeater {
      model: root.available

      AppRow {
        id: availableRow

        required property var modelData

        entry: modelData

        SmallButton {
          text: "Add"
          onClicked: DockConfig.pin(availableRow.modelData.id)
        }
      }
    }

    SettingsRow {
      visible: root.available.length === 0
      label: root.search === "" ? "Every app is already in the dock" : "No app matches"
    }
  }
}
