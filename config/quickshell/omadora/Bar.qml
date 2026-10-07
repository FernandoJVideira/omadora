import QtQuick
import Quickshell

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
  implicitHeight: Omadora.barHeight
  color: Omadora.background

  Row {
    anchors.left: parent.left
    anchors.leftMargin: Omadora.sectionPadding
    height: parent.height

    BarItem {
      text: Omadora.glyph(0xf1ce)
      tooltip: "Omadora Menu\n\nSuper + Alt + Space"
      onLeftClicked: Omadora.run("omadora-exec omadora-menu")
      onRightClicked: Omadora.run("xdg-terminal-exec")
    }

    WorkspacesModule {
      screen: bar.screen
    }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    height: parent.height

    ClockModule {}

    ScriptModule {
      name: "weather"
      script: "libexec/waybar/omadora-waybar-weather"
      guard: "! omactl state toggles exists weather-check-off"
      interval: 60
      altFormat: true
      alertClasses: ["error"]
      icons: {
        const g = codepoint => Omadora.glyph(codepoint);
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
    }

    ScriptModule {
      name: "screenrecording"
      script: "libexec/waybar/omadora-waybar-screen-recording"
      command: "omactl capture screenrecording >/dev/null 2>&1"
    }

    ScriptModule {
      name: "idle"
      script: "libexec/waybar/omadora-waybar-idle"
      command: "omactl toggle idle-lock"
    }

    ScriptModule {
      name: "notification-silencing"
      script: "libexec/waybar/omadora-waybar-notification-silencing"
      command: "omactl toggle notification-silencing"
    }
  }

  Row {
    anchors.right: parent.right
    anchors.rightMargin: Omadora.sectionPadding
    height: parent.height

    TrayModule {
      barWindow: bar
    }

    BluetoothModule {}

    NetworkModule {}

    AudioModule {}

    CpuModule {}

    BatteryModule {}

    ScriptModule {
      name: "update"
      script: "libexec/waybar/omadora-waybar-update"
      interval: 60
      command: 'omadora-exec omadora-launch-floating-terminal-with-presentation "omactl update all"'
      alertClasses: ["error", "reboot-required", "relaunch-required", "security"]
      icons: ({
          "updated": Omadora.glyph(0xf03d7),
          "updates": Omadora.glyph(0xf03d5),
          "security": Omadora.glyph(0xf03ed),
          "relaunch-required": Omadora.glyph(0xf0453),
          "reboot-required": Omadora.glyph(0xf0709),
          "unknown": Omadora.glyph(0xf078b)
        })
    }
  }
}
