import QtQuick
import Quickshell.Io

// Runs one of Omadora's Waybar status scripts (JSON with text/alt/class/tooltip/percentage)
// on an interval and whenever `qs -c omadora ipc call bar refresh <name>` is called.
BarItem {
  id: root

  required property string name
  required property string script // relative to $OMADORA_PATH
  property string guard: "" // shell condition; module hidden when it fails (Waybar's exec-if)
  property int interval: 0 // seconds; 0 runs only at start and on refresh
  property var icons: null // alt -> glyph, or [night, day] picked by percentage (Waybar's format-icons)
  property var alertClasses: ["active"]
  property bool altFormat: false // left click toggles "{icon}   {text}" (Waybar's format-alt)
  property string command: "" // left click command

  property var result: ({})
  property bool showText: false
  property bool pending: false

  readonly property var classes: [].concat(result["class"] ?? [])

  readonly property string icon: {
    if (!icons) {
      return "";
    }
    let value = icons[result.alt] ?? icons["default"] ?? "";
    if (Array.isArray(value)) {
      const index = Math.floor((result.percentage ?? 0) * value.length / 100);
      value = value[Math.max(0, Math.min(value.length - 1, index))];
    }
    return value;
  }

  text: {
    if (!icons) {
      return result.text ?? "";
    }
    if (result.alt === undefined && result.text === undefined) {
      return "";
    }
    return showText && result.text ? `${icon}   ${result.text}` : icon;
  }
  tooltip: result.tooltip ?? ""
  alert: classes.some(c => alertClasses.includes(c))
  dimmed: classes.includes("stale")

  onLeftClicked: {
    if (altFormat) {
      showText = !showText;
    } else if (command) {
      Omadora.run(command);
    }
  }

  function refresh(): void {
    if (proc.running) {
      pending = true;
    } else {
      proc.running = true;
    }
  }

  function parse(output: string): void {
    const lines = output.trim().split("\n");
    const last = lines[lines.length - 1];
    if (!last) {
      result = {};
      return;
    }
    try {
      result = JSON.parse(last);
    } catch (e) {
      result = { text: last };
    }
  }

  Process {
    id: proc

    command: {
      const exec = `exec "$OMADORA_PATH/${root.script}"`;
      const body = root.guard ? `if ${root.guard}; then ${exec}; fi` : exec;
      return ["bash", "-c", `export OMADORA_PATH="${Omadora.omadoraPath}"; export PATH="$OMADORA_PATH/bin:$PATH"; ${body}`];
    }
    stdout: StdioCollector {
      onStreamFinished: root.parse(text)
    }
    onExited: {
      if (root.pending) {
        root.pending = false;
        running = true;
      }
    }
  }

  Timer {
    interval: root.interval * 1000
    running: root.interval > 0
    repeat: true
    onTriggered: root.refresh()
  }

  Connections {
    target: Omadora

    function onRefreshRequested(module: string): void {
      if (module === root.name || module === "all") {
        root.refresh();
      }
    }
  }

  Component.onCompleted: refresh()
}
