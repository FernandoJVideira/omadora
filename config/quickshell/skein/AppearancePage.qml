import QtQuick
import Quickshell
import Quickshell.Io

// Settings > Appearance: theme, wallpaper, text size and terminal font.
SettingsPage {
  id: root

  readonly property string scripts: `${Skein.skeinPath}/libexec`
  readonly property var textSizeStops: [9, 10, 11, 12, 14, 16, 20]
  readonly property int textStopIndex: {
    let best = 0;
    for (let i = 1; i < textSizeStops.length; i++) {
      if (Math.abs(textSizeStops[i] - Skein.textSize) < Math.abs(textSizeStops[best] - Skein.textSize)) {
        best = i;
      }
    }
    return best;
  }

  property string themeName: ""
  property string fontName: ""
  property var fonts: []

  Component.onCompleted: {
    themeProc.running = true;
    fontProc.running = true;
  }

  Process {
    id: themeProc

    command: [`${root.scripts}/skein-theme-current`]
    stdout: StdioCollector {
      onStreamFinished: root.themeName = text.trim()
    }
  }

  Process {
    id: fontProc

    command: [`${root.scripts}/skein-font-current`]
    stdout: StdioCollector {
      onStreamFinished: root.fontName = text.trim()
    }
  }

  Process {
    id: fontListProc

    command: [`${root.scripts}/skein-font-list`]
    stdout: StdioCollector {
      onStreamFinished: root.fonts = text.trim().split("\n").filter(line => line !== "").map(name => ({
            label: name,
            value: name
          }))
    }
  }

  SettingsSection {
    title: "Theme"

    ButtonRow {
      label: "Theme"
      description: root.themeName
      buttonText: "Change…"
      onClicked: Quickshell.execDetached(["qs", "-c", "skein", "ipc", "call", "themes", "open"])
    }

    ButtonRow {
      label: "Wallpaper"
      description: "Pictures, fill mode and your own folder"
      buttonText: "Open…"
      onClicked: root.backend.page = "wallpaper"
    }
  }

  SettingsSection {
    title: "Text"

    SettingsRow {
      label: "Text size"
      description: `${Skein.textSize} px`
      height: Math.round(56 * Skein.textScale)

      StepSlider {
        width: Math.round(260 * Skein.textScale)
        stops: root.textSizeStops.length
        index: root.textStopIndex
        onReleased: i => Quickshell.execDetached([`${root.scripts}/skein-display-text-size`, `${root.textSizeStops[i]}`])
      }
    }

    ComboRow {
      label: "Terminal font"
      options: root.fonts
      current: root.fontName
      onOpenChanged: if (open && root.fonts.length === 0) {
        fontListProc.running = true;
      }
      onChosen: value => {
        root.fontName = value;
        Quickshell.execDetached([`${root.scripts}/skein-font-set`, value]);
      }
    }
  }
}
