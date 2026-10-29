import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// The top bar, one per screen. What it shows and where is set by Skein.barLayout
// (Settings > Menu Bar); how it looks by Skein.barSize, barOpacity, barFloating and barBorder.
PanelWindow {
  id: bar

  required property var modelData

  // The component for a bar item id, see Skein.barItems
  function componentFor(id: string): var {
    switch (id) {
    case "menu":
      return cMenu;
    case "workspaces":
      return cWorkspaces;
    case "clock":
      return cClock;
    case "weather":
      return cWeather;
    case "tray":
      return cTray;
    case "agents":
      return cAgents;
    case "notifications":
      return cNotifications;
    case "controlcenter":
      return cControlCenter;
    case "bluetooth":
      return cBluetooth;
    case "network":
      return cNetwork;
    case "audio":
      return cAudio;
    case "display":
      return cDisplay;
    case "cpu":
      return cCpu;
    case "battery":
      return cBattery;
    case "update":
      return cUpdate;
    default:
      return id.startsWith("custom-") ? cCustom : null;
    }
  }

  screen: modelData
  anchors {
    top: true
    left: true
    right: true
  }
  margins {
    top: Skein.barInset
    left: Skein.barInset
    right: Skein.barInset
  }
  implicitHeight: Skein.barHeight
  exclusionMode: ExclusionMode.Normal
  WlrLayershell.namespace: "skein-bar"
  exclusiveZone: Skein.barHeight + Skein.barInset * 2
  color: "transparent"

  Rectangle {
    visible: Skein.barStyle === "classic"
    anchors.fill: parent
    radius: Skein.barFloating ? Skein.radius : 0
    color: Qt.alpha(Skein.background, Skein.glass ? Math.min(Skein.barOpacity, 0.5) : Skein.barOpacity)
    border.width: Skein.barBorder ? 1 : 0
    border.color: Qt.alpha(Skein.accent, 0.5)

  }

  // A row of bar items for one section
  readonly property bool pills: Skein.barStyle === "pills"
  readonly property int pillInset: Math.round(3 * Skein.textScale)

  component Section: Item {
    id: section

    property var ids: []
    readonly property bool occupied: row.width > 0

    // The id and horizontal centre (in bar coordinates) of every item shown in this section
    function centers(): var {
      const result = [];
      for (let i = 0; i < ids.length; i++) {
        const cell = items.itemAt(i);
        if (cell && cell.width > 0) {
          result.push({
            id: ids[i],
            index: i,
            cx: cell.mapToItem(bar.contentItem, cell.width / 2, 0).x
          });
        }
      }
      return result;
    }

    height: parent ? parent.height : Skein.barHeight
    width: row.width + (bar.pills ? 2 * Skein.sectionPadding : 0)

    // Pills: a rounded, translucent group behind the items of this side
    Rectangle {
      visible: bar.pills && section.occupied
      anchors.fill: parent
      anchors.topMargin: bar.pillInset
      anchors.bottomMargin: bar.pillInset
      radius: height / 2
      color: Qt.alpha(Skein.background, Skein.glass ? Math.min(Skein.barOpacity, 0.5) : Skein.barOpacity)
      border.width: Skein.barBorder ? 1 : 0
      border.color: Qt.alpha(Skein.accent, 0.5)

    }

    Row {
      id: row

      x: bar.pills ? Skein.sectionPadding : 0
      height: section.height

      Repeater {
        id: items

        model: section.ids

        Item {
          id: cell

          required property string modelData

          width: loader.width
          height: row.height

          Loader {
            id: loader

            height: parent.height
            sourceComponent: bar.componentFor(cell.modelData)
            onLoaded: if (item && "customId" in item) {
              item.customId = cell.modelData.slice(7);
            }
          }

          // Rearranging: the item stops reacting to clicks and can be dragged to another place
          Rectangle {
            visible: Skein.barEditing && cell.width > 0
            anchors.fill: parent
            anchors.topMargin: bar.pillInset + 1
            anchors.bottomMargin: bar.pillInset + 1
            radius: Skein.radiusInner
            color: Qt.alpha(Skein.accent, drag.pressed ? 0.35 : 0.15)
            border.width: 1
            border.color: Qt.alpha(Skein.accent, 0.8)

            MouseArea {
              id: drag

              anchors.fill: parent
              cursorShape: Qt.SizeAllCursor
              onPressed: bar.startDrag(cell.modelData)
              onPositionChanged: mouse => bar.moveDrag(mapToItem(bar.contentItem, mouse.x, mouse.y).x)
              onReleased: mouse => bar.dropDrag(mapToItem(bar.contentItem, mouse.x, mouse.y).x)
            }
          }
        }
      }
    }
  }

  // --- drag and drop of bar items while Skein.barEditing ---
  property string dragId: ""
  property real dragX: 0

  function startDrag(id: string): void {
    dragId = id;
  }

  function moveDrag(x: real): void {
    dragX = x;
  }

  function sectionAt(x: real): string {
    return x < width / 3 ? "left" : (x > width * 2 / 3 ? "right" : "center");
  }

  function dropDrag(x: real): void {
    const id = dragId;
    dragId = "";
    if (id === "") {
      return;
    }
    const target = sectionAt(x);
    const sections = {
      left: leftSection,
      center: centerSection,
      right: rightSection
    };
    const layout = Skein.normalizeLayout(Skein.barLayout);
    for (const s of ["left", "center", "right"]) {
      layout[s] = layout[s].filter(i => i !== id);
    }
    // Insert before the first item whose centre is to the right of the drop point
    const ids = layout[target];
    const shown = sections[target].centers().filter(c => c.id !== id);
    const next = shown.find(c => c.cx > x);
    const at = next ? ids.indexOf(next.id) : ids.length;
    ids.splice(at < 0 ? ids.length : at, 0, id);
    Skein.saveLayout(layout);
  }

  // The item being dragged, following the pointer
  Rectangle {
    visible: bar.dragId !== ""
    z: 50
    x: bar.dragX - width / 2
    y: bar.pillInset
    width: dragLabel.implicitWidth + 20
    height: bar.height - 2 * bar.pillInset
    radius: height / 2
    color: Qt.alpha(Skein.accent, 0.9)

    Text {
      id: dragLabel

      anchors.centerIn: parent
      text: Skein.barItems.find(i => i.id === bar.dragId)?.label ?? ""
      color: Skein.background
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 1
      font.bold: true
    }
  }

  // Which side the item would land on
  Repeater {
    model: Skein.barEditing && bar.dragId !== "" ? ["left", "center", "right"] : []

    Rectangle {
      required property string modelData

      readonly property bool target: bar.sectionAt(bar.dragX) === modelData

      z: 40
      y: bar.pillInset
      height: bar.height - 2 * bar.pillInset
      width: bar.width / 3 - 8
      x: (modelData === "left" ? 0 : (modelData === "center" ? 1 : 2)) * bar.width / 3 + 4
      radius: height / 2
      color: "transparent"
      border.width: target ? 2 : 1
      border.color: Qt.alpha(Skein.accent, target ? 0.9 : 0.3)
    }
  }

  // Done button while rearranging
  Rectangle {
    visible: Skein.barEditing && bar.dragId === ""
    z: 60
    anchors.left: centerSection.right
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    width: doneText.implicitWidth + 28
    height: bar.height - 2 * bar.pillInset - 2
    radius: height / 2
    color: Qt.alpha(Skein.accent, doneMouse.containsMouse ? 1 : 0.85)

    Text {
      id: doneText

      anchors.centerIn: parent
      text: "Done rearranging"
      color: Skein.background
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 0.5
      font.bold: true
    }

    MouseArea {
      id: doneMouse

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: Skein.barEditing = false
    }
  }

  Section {
    id: leftSection

    anchors.left: parent.left
    anchors.leftMargin: bar.pills ? Skein.sectionPadding + 2 : Skein.sectionPadding
    ids: Skein.barLayout.left
  }

  Section {
    id: centerSection

    anchors.horizontalCenter: parent.horizontalCenter
    ids: Skein.barLayout.center
  }

  Section {
    id: rightSection

    anchors.right: parent.right
    anchors.rightMargin: bar.pills ? Skein.sectionPadding + 2 : Skein.sectionPadding
    ids: Skein.barLayout.right
  }

  Component {
    id: cMenu

    BarItem {
      text: Skein.glyph(0xf1ce)
      tooltip: "Skein Menu\n\nSuper + Alt + Space"
      onLeftClicked: Skein.run("skein-exec skein-menu")
      onRightClicked: Skein.run("xdg-terminal-exec")
    }
  }

  Component {
    id: cWorkspaces

    WorkspacesModule {
      screen: bar.screen
    }
  }

  Component {
    id: cClock

    ClockModule {
      barWindow: bar
    }
  }

  Component {
    id: cWeather

    ScriptModule {
      id: weather

      name: "weather"
      tooltip: "" // the panel replaces the hover tooltip
      script: "libexec/waybar/skein-waybar-weather"
      guard: "! skeinctl state toggles exists weather-check-off"
      interval: 60
      alertClasses: ["error"]
      icons: {
        const g = codepoint => Skein.glyph(codepoint);
        return {
          "unknown": g(0xf0590),
          "clear": [g(0xe32b), g(0xe30d)],
          "cloudy": [g(0xe32e), g(0xe302)],
          "fog": [g(0xe346), g(0xe303)],
          "drizzle": [g(0xe336), g(0xe30b)],
          "freezing_drizzle": [`${g(0xe336)} ${g(0xe36f)}`, `${g(0xe30b)} ${g(0xe36f)}`],
          "rain": [g(0xe333), g(0xe308)],
          "freezing_rain": [`${g(0xe333)} ${g(0xe36f)}`, `${g(0xe308)} ${g(0xe36f)}`],
          "showers": [g(0xe334), g(0xe309)],
          "snow": [g(0xe335), g(0xe30a)],
          "snow_grains": [g(0xe335), g(0xe30a)],
          "snow_showers": [g(0xe3ab), g(0xe3aa)],
          "thunderstorm": [g(0xe338), g(0xe30f)],
          "severe_thunderstorm": [`${g(0xe338)} ${g(0xe32f)}`, `${g(0xe30f)} ${g(0xe304)}`]
        };
      }

      WeatherPanel {
        id: weatherPanel

        barWindow: bar
      }

      Connections {
        target: weather

        function onLeftClicked() {
          weatherPanel.toggle();
        }

        function onRightClicked() {
          weather.showText = !weather.showText;
        }
      }

      Connections {
        target: Skein

        function onPanelRequested(name) {
          if (name === "weather" && (weatherPanel.open || bar.screen.name === Hyprland.focusedMonitor?.name)) {
            weatherPanel.toggle();
          }
        }
      }
    }
  }

  // An item from ~/.config/skein/bar-items.json
  Component {
    id: cCustom

    CustomModule {
      barWindow: bar
    }
  }

  Component {
    id: cTray

    TrayModule {
      barWindow: bar
    }
  }

  // Classic layout: one icon each. With the Control Center on, they live in its panel instead.
  Component {
    id: cAgents

    AgentsModule {
      barWindow: bar
      visible: !Skein.controlCenter && text !== ""
    }
  }

  Component {
    id: cNotifications

    NotificationCenterModule {
      barWindow: bar
    }
  }

  Component {
    id: cControlCenter

    ControlCenterModule {
      barWindow: bar
    }
  }

  Component {
    id: cBluetooth

    BluetoothModule {
      barWindow: bar
      visible: !Skein.controlCenter && text !== ""
    }
  }

  Component {
    id: cNetwork

    NetworkModule {
      barWindow: bar
      visible: !Skein.controlCenter && text !== ""
    }
  }

  Component {
    id: cAudio

    AudioModule {
      barWindow: bar
      visible: !Skein.controlCenter && text !== ""
    }
  }

  Component {
    id: cDisplay

    DisplayModule {
      barWindow: bar
      visible: !Skein.controlCenter && text !== ""
    }
  }

  Component {
    id: cCpu

    CpuModule {}
  }

  Component {
    id: cBattery

    BatteryModule {}
  }

  Component {
    id: cUpdate

    ScriptModule {
      name: "update"
      script: "libexec/waybar/skein-waybar-update"
      interval: 60
      command: 'skein-exec skein-launch-floating-terminal-with-presentation "skeinctl update all"'
      alertClasses: ["error", "reboot-required", "relaunch-required", "security"]
      icons: ({
          "updated": Skein.glyph(0xf03d7),
          "updates": Skein.glyph(0xf03d5),
          "security": Skein.glyph(0xf03ed),
          "relaunch-required": Skein.glyph(0xf0453),
          "reboot-required": Skein.glyph(0xf0709),
          "unknown": Skein.glyph(0xf078b)
        })
    }
  }
}
