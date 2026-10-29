import QtQuick
import Quickshell
import Quickshell.Io

// Settings > Dock: turn the dock on, how it looks and behaves, and which apps it holds.
SettingsPage {
  id: root

  // Icon packs: what is installed or can be downloaded, and the one in use
  property var packs: []
  property bool busy: false
  property string busyText: ""
  readonly property string packTool: `${Skein.skeinPath}/libexec/skein-icon-pack`

  function loadPacks(): void {
    if (!listProc.running) {
      listProc.running = true;
    }
  }

  // Run one command of the pack tool; the list is read again when it ends
  function runPack(text: string, script: string): void {
    if (busy) {
      return;
    }
    busy = true;
    busyText = text;
    toolProc.command = ["bash", "-c", script, "_", packTool];
    toolProc.running = true;
  }

  Component.onCompleted: loadPacks()

  Process {
    id: listProc

    command: [root.packTool, "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.packs = JSON.parse(text);
        } catch (e) {
          // keep the last list
        }
      }
    }
  }

  Process {
    id: toolProc

    onExited: {
      root.busy = false;
      root.loadPacks();
    }
  }

  // Ready-made docks: position, size and behavior in one click. The apps you keep stay as they are.
  readonly property var presets: [
    {
      name: "macOS",
      description: "Centered at the bottom, icons grow under the pointer, Downloads and Trash at the end",
      settings: {
        position: "bottom",
        iconSize: 48,
        magnify: true,
        magnifySize: 72,
        autoHide: false,
        showRunning: true,
        showIndicators: true,
        showTrash: true,
        showDownloads: true
      }
    },
    {
      name: "Plank",
      description: "Slim and out of the way: it slides off the screen until you reach for the edge",
      settings: {
        position: "bottom",
        iconSize: 44,
        magnify: true,
        magnifySize: 64,
        autoHide: true,
        showRunning: true,
        showIndicators: true,
        showTrash: false,
        showDownloads: false
      }
    },
    {
      name: "Sidebar",
      description: "A narrow strip down the left edge, like Dash to Dock or the Unity launcher",
      settings: {
        position: "left",
        iconSize: 40,
        magnify: false,
        magnifySize: 40,
        autoHide: false,
        showRunning: true,
        showIndicators: true,
        showTrash: false,
        showDownloads: false
      }
    },
    {
      name: "Right rail",
      description: "The same strip on the right, with Downloads and Trash",
      settings: {
        position: "right",
        iconSize: 40,
        magnify: false,
        magnifySize: 40,
        autoHide: false,
        showRunning: true,
        showIndicators: true,
        showTrash: true,
        showDownloads: true
      }
    },
    {
      name: "Compact",
      description: "Small icons and a light zoom, for when screen space matters",
      settings: {
        position: "bottom",
        iconSize: 36,
        magnify: true,
        magnifySize: 56,
        autoHide: false,
        showRunning: true,
        showIndicators: true,
        showTrash: false,
        showDownloads: false
      }
    },
    {
      name: "Showcase",
      description: "Big icons and a big zoom",
      settings: {
        position: "bottom",
        iconSize: 64,
        magnify: true,
        magnifySize: 100,
        autoHide: false,
        showRunning: true,
        showIndicators: true,
        showTrash: true,
        showDownloads: true
      }
    },
    {
      name: "Hidden",
      description: "Only your kept apps, no zoom, hidden until you need it",
      settings: {
        position: "bottom",
        iconSize: 40,
        magnify: false,
        magnifySize: 40,
        autoHide: true,
        showRunning: false,
        showIndicators: false,
        showTrash: false,
        showDownloads: false
      }
    }
  ]

  function presetActive(preset: var): bool {
    return Object.keys(preset.settings).every(key => DockConfig[key] === preset.settings[key]);
  }

  readonly property string search: searchRow.text.trim().toLowerCase()
  // Installed apps that are not in the dock yet, filtered by the search box
  readonly property var available: DesktopEntries.applications.values.filter(e => !e.noDisplay && !DockConfig.pinned.includes(e.id) && (search === "" || e.name.toLowerCase().includes(search))).sort((a, b) => a.name.localeCompare(b.name)).slice(0, 8)

  SettingsSection {
    title: "Presets"

    Repeater {
      model: root.presets

      Item {
        id: presetRow

        required property var modelData
        readonly property bool active: root.presetActive(modelData)

        width: parent.width
        height: presetText.implicitHeight + preview.height + 34

        Column {
          id: presetText

          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.right: applyButton.left
          anchors.rightMargin: 12
          anchors.top: parent.top
          anchors.topMargin: 12
          spacing: 2

          Text {
            width: parent.width
            text: presetRow.modelData.name
            color: Skein.foreground
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize
          }

          Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: presetRow.modelData.description
            color: Qt.alpha(Skein.foreground, 0.6)
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize - 1.5
          }
        }

        SmallButton {
          id: applyButton

          anchors.right: parent.right
          anchors.rightMargin: 14
          anchors.top: parent.top
          anchors.topMargin: 12
          text: presetRow.active ? "In use" : "Use"
          highlighted: presetRow.active
          enabled: !presetRow.active
          onClicked: DockConfig.applyLayout(presetRow.modelData.settings)
        }

        DockPreview {
          id: preview

          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.top: presetText.bottom
          anchors.topMargin: 10
          width: parent.width - 28
          settings: presetRow.modelData.settings
        }

        Rectangle {
          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: 1
          color: Qt.alpha(Skein.foreground, 0.08)
        }
      }
    }
  }

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

    SwitchRow {
      label: "Downloads folder"
      description: "A shortcut to your Downloads folder at the end of the dock"
      checked: DockConfig.showDownloads
      onToggled: value => DockConfig.set("showDownloads", value)
    }

    SwitchRow {
      label: "Trash"
      description: "Open the trash, or empty it from the right-click menu"
      checked: DockConfig.showTrash
      onToggled: value => DockConfig.set("showTrash", value)
    }
  }

  SettingsSection {
    title: "Icon pack"

    SettingsRow {
      visible: root.busy
      label: root.busyText
      description: "Hang on, this can take a minute. You can keep using the system meanwhile."
    }

    Repeater {
      model: root.packs

      SettingsRow {
        id: packRow

        required property var modelData

        dimmed: root.busy
        label: modelData.active ? `${modelData.name} (in use)` : modelData.name
        description: modelData.description

        // A taste of the pack: a few well known apps drawn with it
        leading: Row {
          spacing: 6

          Repeater {
            model: packRow.modelData.preview ?? []

            Image {
              required property string modelData

              width: Math.round(30 * Skein.textScale)
              height: width
              source: `file://${modelData}`
              sourceSize: Qt.size(96, 96)
              fillMode: Image.PreserveAspectFit
              asynchronous: true
            }
          }
        }

        Row {
          spacing: 6

          SmallButton {
            visible: !packRow.modelData.installed
            enabled: !root.busy
            text: "Download and apply"
            onClicked: root.runPack(`Downloading ${packRow.modelData.name}…`, 'tool="$1"; "$tool" install "$2" && "$tool" apply "$2"; true'.replace("$2", packRow.modelData.id))
          }

          SmallButton {
            visible: packRow.modelData.installed && !packRow.modelData.active
            enabled: !root.busy
            text: "Apply"
            onClicked: root.runPack("Applying…", '"$1" apply "' + packRow.modelData.id + '"')
          }

          SmallButton {
            visible: packRow.modelData.installed && packRow.modelData.active
            enabled: false
            highlighted: true
            text: "In use"
          }

          SmallButton {
            visible: packRow.modelData.installed && packRow.modelData.removable
            enabled: !root.busy
            text: "Remove"
            onClicked: root.runPack("Removing…", '"$1" remove "' + packRow.modelData.id + '"')
          }
        }
      }
    }

    TextInputRow {
      label: "Add a pack from a link"
      placeholder: "https://… .zip or .tar.xz"
      onAccepted: link => {
        const url = link.trim();
        if (url !== "") {
          root.runPack("Downloading the icon pack…", 'tool="$1"; name="$("$tool" add-url "$2")" && "$tool" apply "$name"; true'.replace("$2", url.replace(/[^A-Za-z0-9:\/._~?&=%+#@,-]/g, "")));
        }
      }
    }

    SettingsRow {
      label: "Your own icon for one app"
      description: "Use Icon… on any app in the list below. It always wins over the pack."
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

        // The key the dock stores your own icon under: the lowercase desktop id
        readonly property string appKey: (entry?.id ?? modelData).toLowerCase().replace(/\.desktop$/, "")
        readonly property bool hasOwnIcon: (DockConfig.icons[appKey] ?? "") !== ""

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
            text: "Icon…"
            onClicked: root.backend.external([`${DockConfig.script}`, "choose-icon", pinnedRow.appKey], true)
          }

          SmallButton {
            visible: pinnedRow.hasOwnIcon
            text: "Reset icon"
            onClicked: DockConfig.resetIcon(pinnedRow.appKey)
          }

          SmallButton {
            visible: pinnedRow.modelData.startsWith("skein-custom-")
            text: "Delete"
            onClicked: DockConfig.removeLauncher(pinnedRow.modelData)
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

  SettingsSection {
    title: "Custom launcher"

    TextInputRow {
      id: launcherName

      label: "Name"
      description: "Your own dock entry: a button that runs any command"
      placeholder: "Notes"
    }

    TextInputRow {
      id: launcherCommand

      label: "Command"
      placeholder: "kitty -e nvim ~/notes.md"
    }

    TextInputRow {
      id: launcherIcon

      label: "Icon"
      description: "An image path or an icon name; empty gives a generic icon, and Icon… on the app changes it later"
      placeholder: "~/Pictures/notes.png"
    }

    ButtonRow {
      label: "Add to the dock"
      description: "It is also a normal app entry: the launcher finds it, and the list above can reorder or remove it"
      buttonText: "Add"
      enabled: launcherName.text.trim() !== "" && launcherCommand.text.trim() !== ""
      onClicked: {
        DockConfig.addLauncher(launcherName.text.trim(), launcherCommand.text.trim(), launcherIcon.text.trim());
        launcherName.text = "";
        launcherCommand.text = "";
        launcherIcon.text = "";
      }
    }
  }
}
