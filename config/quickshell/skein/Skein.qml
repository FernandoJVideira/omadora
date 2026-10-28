pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shared paths, theme colors, sizing and helpers for the bar.
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string skeinPath: Quickshell.env("SKEIN_PATH") || `${home}/.local/share/skein`

  // Theme colors come from the same file Waybar uses, so every theme works unchanged.
  readonly property string themeFile: `${home}/.config/skein/current/theme/waybar.css`
  property color foreground: "#e0def4"
  property color background: "#191724"
  property color accent: "#c4a7e7"
  readonly property color alert: "#a55555"

  readonly property string fontFamily: "Adwaita Sans"
  // Text size in px (12 is the default); set with skein-display-text-size or from the display panel
  property int textSize: 12
  readonly property real textScale: textSize / 12

  // Scale a point size with the text size
  function pt(size: real): real {
    return size * textScale;
  }

  readonly property real fontSize: 10.5 * textScale
  readonly property int barHeight: Math.round(barSize * textScale)
  // Gap around a floating bar
  readonly property int barInset: barFloating ? Math.round(6 * textScale) : 0
  readonly property int sectionPadding: Math.round(5 * textScale) // 0.35rem
  readonly property int modulePadding: Math.round(8 * textScale * densityFactor) // 0.55rem
  readonly property int minModuleWidth: Math.round(28 * textScale * densityFactor) // 2em

  // Do not disturb: only notify-send gets through (see Notifications.qml)
  property bool silenced: false

  // Menu bar settings (Settings > Menu Bar), read from shell.json. With controlCenter on, one Control
  // Center button and a notification center replace the row of indicators; off is the classic bar.
  property bool controlCenter: false
  property bool notificationCenter: true
  // Sound for a new notification: "default", "off", the name of a theme sound or the path of a file
  property string notificationSound: "default"
  property bool showModes: true // the mode indicators (recording, night light, ...) left of the clock
  property int barSize: 26 // bar height in px at the default text size
  property real barOpacity: 1
  property bool barFloating: false // a rounded bar with a gap around it
  property bool barBorder: false
  property string barStyle: "classic" // classic (one bar) or pills (a rounded group for each side)
  property bool barEditing: false // drag items on the bar to rearrange them (not saved)
  property string barDensity: "default" // compact, default or comfortable

  // Everything the bar can show. `only` limits an item to the classic bar or to the Control Center.
  readonly property var barItems: [
    {
      id: "menu",
      label: "Skein menu",
      only: ""
    },
    {
      id: "workspaces",
      label: "Workspaces",
      only: ""
    },
    {
      id: "clock",
      label: "Clock",
      only: ""
    },
    {
      id: "weather",
      label: "Weather",
      only: ""
    },
    {
      id: "tray",
      label: "System tray",
      only: ""
    },
    {
      id: "agents",
      label: "Agents",
      only: "classic"
    },
    {
      id: "notifications",
      label: "Notification bell",
      only: "controlcenter"
    },
    {
      id: "controlcenter",
      label: "Control Center",
      only: ""
    },
    {
      id: "bluetooth",
      label: "Bluetooth",
      only: "classic"
    },
    {
      id: "network",
      label: "Network",
      only: "classic"
    },
    {
      id: "audio",
      label: "Audio",
      only: "classic"
    },
    {
      id: "display",
      label: "Display",
      only: "classic"
    },
    {
      id: "cpu",
      label: "Processor",
      only: ""
    },
    {
      id: "battery",
      label: "Battery",
      only: ""
    },
    {
      id: "update",
      label: "Updates",
      only: ""
    }
  ]
  readonly property var defaultBarLayout: ({
      left: ["menu", "workspaces"],
      center: ["clock", "weather"],
      right: ["tray", "agents", "notifications", "controlcenter", "bluetooth", "network", "audio", "display", "cpu", "battery", "update"]
    })
  // Where each item sits: {left: [ids], center: [ids], right: [ids]}; ids left out are hidden
  property var barLayout: defaultBarLayout

  readonly property real densityFactor: barDensity === "compact" ? 0.75 : (barDensity === "comfortable" ? 1.3 : 1)

  function normalizeLayout(layout: var): var {
    const known = barItems.map(i => i.id);
    const seen = {};
    const result = {};
    for (const section of ["left", "center", "right"]) {
      result[section] = (Array.isArray(layout?.[section]) ? layout[section] : []).filter(id => known.includes(id) && !seen[id] && (seen[id] = true));
    }
    return result;
  }

  function sectionOf(id: string): string {
    for (const section of ["left", "center", "right"]) {
      if (barLayout[section].includes(id)) {
        return section;
      }
    }
    return "";
  }

  function saveLayout(layout: var): void {
    setBar("barLayout", normalizeLayout(layout));
  }

  // Put an item at the end of a section ("" hides it)
  function placeBarItem(id: string, section: string): void {
    const next = normalizeLayout(barLayout);
    for (const s of ["left", "center", "right"]) {
      next[s] = next[s].filter(i => i !== id);
    }
    if (section !== "") {
      next[section].push(id);
    }
    saveLayout(next);
  }

  // Move an item one place within its section
  function moveBarItem(id: string, delta: int): void {
    const next = normalizeLayout(barLayout);
    const section = sectionOf(id);
    if (section === "") {
      return;
    }
    const list = next[section];
    const i = list.indexOf(id);
    const j = i + delta;
    if (j < 0 || j >= list.length) {
      return;
    }
    [list[i], list[j]] = [list[j], list[i]];
    saveLayout(next);
  }
  property string clockStyle: "day" // day ("Tuesday 14:05"), date ("Tue 14 Oct 14:05") or time
  property bool clock24h: true
  property bool clockSeconds: false

  // The notifications still open, newest last, for the notification center (kept by Notifications.qml)
  property var notifications: []

  // Change a menu bar setting now and save it
  function playNotificationSound(choice: string): void {
    const which = choice !== "" ? choice : notificationSound;
    if (which !== "off") {
      Quickshell.execDetached([`${skeinPath}/libexec/skein-notification-sound`, "play", which]);
    }
  }

  function setBar(key: string, value: var): void {
    root[key] = value;
    Quickshell.execDetached([`${skeinPath}/libexec/skein-menubar`, "set", key, JSON.stringify(value)]);
  }

  signal refreshRequested(string module)
  signal panelRequested(string name)
  // A bar panel just opened: every other one closes
  signal panelOpening(var panel)
  // A dropdown wants its list shown above everything (Settings window): owner gets chosen(value)
  signal dropdownRequested(var owner, var anchor, var options, string current)

  function glyph(codepoint: int): string {
    return String.fromCodePoint(codepoint);
  }

  // Run a shell command detached, with Skein's bin dir on PATH (like Waybar's on-click).
  function run(command: string): void {
    Quickshell.execDetached(["bash", "-c", `export SKEIN_PATH="${skeinPath}"; export PATH="$SKEIN_PATH/bin:$PATH"; ${command}`]);
  }

  function reloadTheme(): void {
    themeView.reload();
  }

  function parseColor(value: string): var {
    const rgb = value.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)$/);
    if (rgb) {
      return Qt.rgba(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, rgb[4] === undefined ? 1 : Number(rgb[4]));
    }
    return value;
  }

  function parseTheme(css: string): void {
    const re = /@define-color\s+([\w-]+)\s+([^;]+);/g;
    let match;
    while ((match = re.exec(css)) !== null) {
      if (match[1] === "foreground") {
        root.foreground = parseColor(match[2].trim());
      } else if (match[1] === "background") {
        root.background = parseColor(match[2].trim());
      } else if (match[1] === "accent") {
        root.accent = parseColor(match[2].trim());
      }
    }
  }

  // Shell settings: {"textSize": 12}
  FileView {
    path: `${root.home}/.config/skein/shell.json`
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        const config = JSON.parse(text());
        root.textSize = config.textSize >= 9 && config.textSize <= 20 ? config.textSize : 12;
        root.controlCenter = config.controlCenter === true;
        root.notificationCenter = config.notificationCenter !== false;
        root.notificationSound = typeof config.notificationSound === "string" && config.notificationSound !== "" ? config.notificationSound : "default";
        root.showModes = config.showModes !== false;
        root.barSize = Math.max(20, Math.min(48, config.barSize ?? 26));
        root.barOpacity = Math.max(0.3, Math.min(1, config.barOpacity ?? 1));
        root.barFloating = config.barFloating === true;
        root.barBorder = config.barBorder === true;
        root.barStyle = config.barStyle === "pills" ? "pills" : "classic";
        root.barDensity = ["compact", "default", "comfortable"].includes(config.barDensity) ? config.barDensity : "default";
        root.barLayout = config.barLayout ? root.normalizeLayout(config.barLayout) : root.defaultBarLayout;
        root.clockStyle = ["day", "date", "time"].includes(config.clockStyle) ? config.clockStyle : "day";
        root.clock24h = config.clock24h !== false;
        root.clockSeconds = config.clockSeconds === true;
      } catch (e) {
        root.textSize = 12;
      }
    }
    onLoadFailed: root.textSize = 12
  }

  FileView {
    id: themeView

    path: root.themeFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parseTheme(text())
  }
}
