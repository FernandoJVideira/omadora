pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shared paths, theme colors, sizing and helpers for the bar.
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string omadoraPath: Quickshell.env("OMADORA_PATH") || `${home}/.local/share/omadora`

  // Theme colors come from the same file Waybar uses, so every theme works unchanged.
  readonly property string themeFile: `${home}/.config/omadora/current/theme/waybar.css`
  property color foreground: "#e0def4"
  property color background: "#191724"
  property color accent: "#c4a7e7"
  readonly property color alert: "#a55555"

  readonly property string fontFamily: "Adwaita Sans"
  // Text size in px (12 is the default); set with omadora-display-text-size or from the display panel
  property int textSize: 12
  readonly property real textScale: textSize / 12

  // Scale a point size with the text size
  function pt(size: real): real {
    return size * textScale;
  }

  readonly property real fontSize: 10.5 * textScale
  readonly property int barHeight: Math.round(26 * textScale)
  readonly property int sectionPadding: Math.round(5 * textScale) // 0.35rem
  readonly property int modulePadding: Math.round(8 * textScale) // 0.55rem
  readonly property int minModuleWidth: Math.round(28 * textScale) // 2em

  // Do not disturb: only notify-send gets through (see Notifications.qml)
  property bool silenced: false

  signal refreshRequested(string module)
  signal panelRequested(string name)

  function glyph(codepoint: int): string {
    return String.fromCodePoint(codepoint);
  }

  // Run a shell command detached, with Omadora's bin dir on PATH (like Waybar's on-click).
  function run(command: string): void {
    Quickshell.execDetached(["bash", "-c", `export OMADORA_PATH="${omadoraPath}"; export PATH="$OMADORA_PATH/bin:$PATH"; ${command}`]);
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
    path: `${root.home}/.config/omadora/shell.json`
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        const size = JSON.parse(text()).textSize;
        root.textSize = size >= 9 && size <= 20 ? size : 12;
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
