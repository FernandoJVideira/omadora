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

  // The blur slider fires while dragging: apply once it settles
  Timer {
    id: blurTimer

    interval: 250
    onTriggered: Quickshell.execDetached([`${root.scripts}/skein-glass`, "set", "blur", Skein.glassBlur.toFixed(1)])
  }

  SettingsSection {
    title: "Liquid Glass"

    SwitchRow {
      label: "Liquid Glass"
      description: "Translucent glass bar, panels, windows and dock with refraction. Needs the HyprGlass plugin; without it the surfaces are only blurred. Off gives solid surfaces."
      checked: Skein.glass
      onToggled: value => {
        Skein.glass = value;
        Quickshell.execDetached([`${root.scripts}/skein-glass`, "set", "enabled", value ? "1" : "0"]);
      }
    }

    SliderRow {
      label: "Blur"
      valueText: Skein.glassBlur.toFixed(1)
      value: Skein.glassBlur
      maximum: 6
      opacity: Skein.glass ? 1 : 0.4
      onMoved: v => {
        Skein.glassBlur = Math.max(0.5, Math.min(6, v));
        blurTimer.restart();
      }
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
