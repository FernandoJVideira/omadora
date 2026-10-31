import QtQuick
import Quickshell
import Quickshell.Io
import "DisplayModel.js" as Model

// Settings > Display: brightness, scale and nightlight of the focused monitor.
SettingsPage {
  id: root

  readonly property string scripts: `${Skein.skeinPath}/libexec`
  readonly property var scalePresets: [1, 1.25, 1.6, 2, 3, 4]
  property var monitors: ({
      focused: "",
      brightness: null,
      displays: []
    })
  property int brightnessLive: -1
  readonly property var focusedDisplay: monitors.displays.find(d => d.focused) ?? null
  readonly property var scales: focusedDisplay ? Model.availableScales(scalePresets, focusedDisplay.width, focusedDisplay.height) : scalePresets
  readonly property int scaleIndex: focusedDisplay ? Model.matchingScaleIndex(scales, focusedDisplay.scale, focusedDisplay.width, focusedDisplay.height) : -1
  readonly property bool hasBrightness: monitors.brightness !== null && monitors.brightness !== undefined

  // A mode you just picked is tried live; you keep it, or it goes back after ten seconds
  property var pending: null // {name, previous, mode, left}

  function parseMode(text: string): var {
    const m = text.match(/^(\d+)x(\d+)@([\d.]+)/);
    return m ? {
      w: +m[1],
      h: +m[2],
      r: +m[3],
      text: text.replace(/Hz$/, "")
    } : null;
  }

  function resolutions(display: var): var {
    const seen = {};
    return display.modes.map(m => parseMode(m)).filter(m => m && !seen[`${m.w}x${m.h}`] && (seen[`${m.w}x${m.h}`] = true)).sort((a, b) => b.w * b.h - a.w * a.h).map(m => `${m.w}x${m.h}`);
  }

  function ratesFor(display: var, resolution: string): var {
    return display.modes.map(m => parseMode(m)).filter(m => m && `${m.w}x${m.h}` === resolution).sort((a, b) => b.r - a.r);
  }

  function currentMode(display: var): string {
    const rates = ratesFor(display, `${display.width}x${display.height}`);
    let best = rates[0];
    for (const m of rates) {
      if (Math.abs(m.r - display.refreshRate) < Math.abs(best.r - display.refreshRate)) {
        best = m;
      }
    }
    return best ? best.text : "";
  }

  function tryMode(display: var, mode: string): void {
    if (mode === "" || mode === currentMode(display)) {
      return;
    }
    const previous = pending && pending.name === display.name ? pending.previous : currentMode(display);
    Quickshell.execDetached([`${scripts}/skein-monitors-set`, "apply", display.name, mode]);
    pending = {
      name: display.name,
      previous: previous,
      mode: mode,
      left: 10
    };
    countdown.restart();
    refreshTimer.restart();
  }

  function keepMode(): void {
    Quickshell.execDetached([`${scripts}/skein-monitors-set`, "save", pending.name, pending.mode]);
    pending = null;
    countdown.stop();
    refreshTimer.restart();
  }

  function revertMode(): void {
    if (!pending) {
      return;
    }
    Quickshell.execDetached([`${scripts}/skein-monitors-set`, "apply", pending.name, pending.previous]);
    pending = null;
    countdown.stop();
    refreshTimer.restart();
  }

  // Closing the settings window with a mode on trial puts the old one back
  Component.onDestruction: revertMode()

  Timer {
    id: countdown

    interval: 1000
    repeat: true
    onTriggered: {
      if (root.pending.left <= 1) {
        root.revertMode();
      } else {
        root.pending = Object.assign({}, root.pending, {
          left: root.pending.left - 1
        });
      }
    }
  }

  Component.onCompleted: stateProc.running = true

  Process {
    id: stateProc

    command: [`${root.scripts}/skein-monitor-state`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.monitors = JSON.parse(text.trim());
          root.brightnessLive = -1;
        } catch (e) {
          // keep the last state
        }
      }
    }
  }

  Process {
    id: brightnessProc
  }

  Timer {
    id: refreshTimer

    interval: 1500
    onTriggered: stateProc.running = true
  }

  SettingsSection {
    visible: root.pending !== null
    title: "Keep these settings?"

    SettingsRow {
      label: root.pending ? `${root.pending.name} · ${root.pending.mode}` : ""
      description: root.pending ? `Going back in ${root.pending.left} seconds` : ""

      Row {
        spacing: 8

        Repeater {
          model: [
            {
              text: "Revert",
              keep: false
            },
            {
              text: "Keep",
              keep: true
            }
          ]

          Rectangle {
            required property var modelData

            width: label.implicitWidth + 28
            height: Math.round(26 * Skein.textScale)
            radius: Skein.radiusInner
            color: btn.containsMouse ? Qt.alpha(Skein.accent, 0.35) : (modelData.keep ? Qt.alpha(Skein.accent, 0.25) : Qt.alpha(Skein.foreground, 0.06))
            border.width: 1
            border.color: Qt.alpha(Skein.accent, 0.6)

            Text {
              id: label

              anchors.centerIn: parent
              text: modelData.text
              color: Skein.foreground
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize - 0.5
              font.bold: modelData.keep
            }

            MouseArea {
              id: btn

              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: modelData.keep ? root.keepMode() : root.revertMode()
            }
          }
        }
      }
    }
  }

  SettingsSection {
    title: "Arrangement"
    visible: root.monitors.displays.length > 1

    MonitorLayoutEditor {
      displays: root.monitors.displays
      onCommitted: placements => {
        Quickshell.execDetached([`${root.scripts}/skein-monitors-set`, "layout", ...placements.map(p => `${p.name}=${p.x}x${p.y}`)]);
        refreshTimer.interval = 2500;
        refreshTimer.restart();
      }
    }
  }

  SettingsSection {
    title: "Main display"
    visible: root.monitors.displays.length > 1

    ComboRow {
      label: "Main display"
      description: "Sits at the left edge and gets workspaces 1-5. Used for the login screen too."
      options: root.monitors.displays.map(d => ({
            label: `${d.name} · ${d.width}×${d.height}`,
            value: d.name
          }))
      current: root.monitors.displays.find(d => d.main)?.name ?? ""
      onChosen: value => {
        if (value !== root.monitors.displays.find(d => d.main)?.name) {
          Quickshell.execDetached([`${root.scripts}/skein-monitors-set`, "main", value]);
          refreshTimer.interval = 2500;
          refreshTimer.restart();
        }
      }
    }
  }

  Repeater {
    model: root.monitors.displays

    SettingsSection {
      id: monitorSection

      required property var modelData

      title: `${modelData.name}${modelData.main ? " · Main" : ""}`

      ComboRow {
        label: "Resolution"
        options: root.resolutions(monitorSection.modelData).map(r => ({
              label: r.replace("x", " × "),
              value: r
            }))
        current: `${monitorSection.modelData.width}x${monitorSection.modelData.height}`
        onChosen: value => {
          // Keep the refresh rate if the new resolution has it, otherwise the fastest one
          const rates = root.ratesFor(monitorSection.modelData, value);
          const wanted = rates.find(m => Math.abs(m.r - monitorSection.modelData.refreshRate) < 0.5) ?? rates[0];
          root.tryMode(monitorSection.modelData, wanted.text);
        }
      }

      ComboRow {
        label: "Refresh rate"
        options: root.ratesFor(monitorSection.modelData, `${monitorSection.modelData.width}x${monitorSection.modelData.height}`).map(m => ({
              label: `${m.r.toFixed(2).replace(/\.?0+$/, "")} Hz`,
              value: m.text
            }))
        current: root.currentMode(monitorSection.modelData)
        onChosen: value => root.tryMode(monitorSection.modelData, value)
      }
    }
  }

  SettingsSection {
    title: root.focusedDisplay ? `Display · ${root.focusedDisplay.name}` : "Display"

    SliderRow {
      visible: root.hasBrightness
      label: "Brightness"
      valueText: `${root.brightnessLive >= 0 ? root.brightnessLive : root.monitors.brightness}%`
      value: (root.brightnessLive >= 0 ? root.brightnessLive : (root.monitors.brightness ?? 0)) / 100
      onMoved: v => {
        root.brightnessLive = Model.clampBrightness(v * 100);
        if (!brightnessProc.running) {
          brightnessProc.command = [`${root.scripts}/skein-brightness-display`, "--no-osd", "--monitor", root.monitors.focused, `${root.brightnessLive}%`];
          brightnessProc.running = true;
        }
      }
    }

    SettingsRow {
      visible: !root.hasBrightness
      label: "Brightness"
      description: "This display has no brightness control"
    }

    ComboRow {
      label: "Scale"
      options: root.scales.map(s => ({
            label: `${Number(s).toFixed(2).replace(/\.?0+$/, "")}x`,
            value: `${s}`
          }))
      current: root.scaleIndex >= 0 ? `${root.scales[root.scaleIndex]}` : ""
      onChosen: value => {
        Quickshell.execDetached([`${root.scripts}/skein-hyprland-monitor-scaling`, value]);
        refreshTimer.restart();
      }
    }

    SwitchRow {
      label: "Nightlight"
      description: "Warmer screen colours (4000 K)"
      checked: root.backend?.sysState.nightlight ?? false
      onToggled: value => root.backend.set("nightlight", value, "skein-toggle-nightlight")
    }
  }
}
