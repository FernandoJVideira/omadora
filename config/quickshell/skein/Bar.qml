import QtQuick
import Quickshell
import Quickshell.Hyprland

// The top bar, one per screen. Module order matches the Waybar config.
PanelWindow {
  id: bar

  required property var modelData

  screen: modelData
  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: Skein.barHeight
  color: Skein.background

  Row {
    anchors.left: parent.left
    anchors.leftMargin: Skein.sectionPadding
    height: parent.height

    BarItem {
      text: Skein.glyph(0xf1ce)
      tooltip: "Skein Menu\n\nSuper + Alt + Space"
      onLeftClicked: Skein.run("skein-exec skein-menu")
      onRightClicked: Skein.run("xdg-terminal-exec")
    }

    WorkspacesModule {
      screen: bar.screen
    }
  }

  IndicatorsModule {
    anchors.right: centerRow.left
    barWindow: bar
  }

  Row {
    id: centerRow

    anchors.horizontalCenter: parent.horizontalCenter
    height: parent.height

    ClockModule {
      barWindow: bar
    }

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

  Row {
    anchors.right: parent.right
    anchors.rightMargin: Skein.sectionPadding
    height: parent.height

    TrayModule {
      barWindow: bar
    }

    AgentsModule {
      barWindow: bar
    }

    BluetoothModule {
      barWindow: bar
    }

    NetworkModule {
      barWindow: bar
    }

    AudioModule {
      barWindow: bar
    }

    DisplayModule {
      barWindow: bar
    }

    CpuModule {}

    BatteryModule {}

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
