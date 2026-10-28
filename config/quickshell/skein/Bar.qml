import QtQuick
import Quickshell
import Quickshell.Hyprland

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
      return null;
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
  exclusiveZone: Skein.barHeight + Skein.barInset * 2
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    radius: Skein.barFloating ? Math.round(10 * Skein.textScale) : 0
    color: Qt.alpha(Skein.background, Skein.barOpacity)
    border.width: Skein.barBorder ? 1 : 0
    border.color: Qt.alpha(Skein.accent, 0.5)
  }

  // A row of bar items for one section
  component Section: Row {
    id: section

    property var ids: []

    height: parent ? parent.height : Skein.barHeight

    Repeater {
      model: section.ids

      Loader {
        required property string modelData

        height: section.height
        sourceComponent: bar.componentFor(modelData)
      }
    }
  }

  Section {
    anchors.left: parent.left
    anchors.leftMargin: Skein.sectionPadding
    ids: Skein.barLayout.left
  }

  IndicatorsModule {
    visible: Skein.showModes
    anchors.right: centerSection.left
    barWindow: bar
  }

  Section {
    id: centerSection

    anchors.horizontalCenter: parent.horizontalCenter
    ids: Skein.barLayout.center
  }

  Section {
    anchors.right: parent.right
    anchors.rightMargin: Skein.sectionPadding
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
