import QtQuick
import Quickshell.Io

// A bar item defined by the user in ~/.config/skein/bar-items.json:
//   {"id": "vpn", "label": "VPN", "icon": "󰖂", "text": "VPN", "script": "~/bin/vpn-status", "interval": 10,
//    "tooltip": "VPN status", "onClick": "nm-connection-editor", "onRightClick": "..."}
// The script prints plain text or Waybar-style JSON ({"text", "tooltip", "class"}); "alert" in the class turns
// the item red. Without a script the item shows its icon and text as they are.
BarItem {
  id: root

  required property var barWindow
  property string customId: ""

  readonly property var def: Skein.customItems.find(item => item.id === customId) ?? null
  property var result: ({})

  readonly property string shownText: result.text ?? def?.text ?? ""
  readonly property string icon: def?.icon ?? ""

  text: def ? (icon !== "" && shownText !== "" ? `${icon}  ${shownText}` : (icon !== "" ? icon : shownText)) : ""
  tooltip: result.tooltip ?? def?.tooltip ?? def?.label ?? ""
  alert: [].concat(result["class"] ?? []).includes("alert")
  padded: shownText !== ""
  onLeftClicked: if (def?.onClick) {
    Skein.run(def.onClick);
  }
  onRightClicked: if (def?.onRightClick) {
    Skein.run(def.onRightClick);
  }

  function refresh(): void {
    if (def?.script && !proc.running) {
      proc.running = true;
    }
  }

  Process {
    id: proc

    command: ["bash", "-c", `export SKEIN_PATH="${Skein.skeinPath}"; export PATH="$SKEIN_PATH/bin:$PATH"; ${root.def?.script ?? "true"}`]
    stdout: StdioCollector {
      onStreamFinished: {
        const last = text.trim().split("\n").pop();
        try {
          const parsed = JSON.parse(last);
          root.result = parsed !== null && typeof parsed === "object" ? parsed : { text: last };
        } catch (e) {
          root.result = { text: last };
        }
      }
    }
  }

  Timer {
    interval: Math.max(1, root.def?.interval ?? 0) * 1000
    running: !!root.def?.script && (root.def?.interval ?? 0) > 0
    repeat: true
    onTriggered: root.refresh()
  }

  Connections {
    target: Skein

    function onRefreshRequested(module: string): void {
      if (module === `custom-${root.customId}` || module === "all") {
        root.refresh();
      }
    }
  }

  onDefChanged: refresh()
}
