import QtQuick
import Quickshell
import Quickshell.Io

// Settings > Input: keyboard layout and touchpad.
SettingsPage {
  id: root

  readonly property var sys: backend?.sysState ?? ({})
  readonly property string inputFile: `${Quickshell.env("HOME")}/.config/hypr/input.lua`
  property string layout: "us"
  readonly property var layouts: [
    {
      label: "English (US)",
      value: "us"
    },
    {
      label: "English (UK)",
      value: "gb"
    },
    {
      label: "Portuguese",
      value: "pt"
    },
    {
      label: "Portuguese (Brazil)",
      value: "br"
    },
    {
      label: "Spanish",
      value: "es"
    },
    {
      label: "French",
      value: "fr"
    },
    {
      label: "German",
      value: "de"
    },
    {
      label: "Italian",
      value: "it"
    }
  ]

  Component.onCompleted: layoutProc.running = true

  Process {
    id: layoutProc

    command: ["sh", "-c", `sed -n 's/.*kb_layout *= *"\\([^"]*\\)".*/\\1/p' '${root.inputFile}' | head -n1`]
    stdout: StdioCollector {
      onStreamFinished: root.layout = text.trim() || "us"
    }
  }

  SettingsSection {
    title: "Keyboard"

    ComboRow {
      label: "Layout"
      description: "Written to ~/.config/hypr/input.lua"
      options: root.layouts
      current: root.layout
      onChosen: value => {
        root.layout = value;
        Quickshell.execDetached(["sh", "-c", `sed -i 's/kb_layout *= *"[^"]*"/kb_layout = "${value}"/' '${root.inputFile}' && hyprctl reload`]);
      }
    }
  }

  SettingsSection {
    title: "Touchpad"

    SwitchRow {
      label: "Touchpad"
      description: root.sys.touchpad === null || root.sys.touchpad === undefined ? "No touchpad found" : ""
      checked: root.sys.touchpad ?? false
      enabled: root.sys.touchpad !== null && root.sys.touchpad !== undefined
      onToggled: value => root.backend.set("touchpad", value, "skein-toggle-touchpad", [value ? "on" : "off"])
    }
  }
}
