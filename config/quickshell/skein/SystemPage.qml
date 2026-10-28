import QtQuick
import Quickshell
import Quickshell.Io

// Settings > System: background services, updates and session actions.
SettingsPage {
  id: root

  readonly property var sys: backend?.sysState ?? ({})
  readonly property string sharePickerTool: `${Skein.skeinPath}/libexec/skein-share-picker`
  property bool sharePicker: false

  Process {
    id: shareStatus

    command: [root.sharePickerTool, "status"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.sharePicker = text.trim() === "enabled"
    }
  }

  SettingsSection {
    title: "Services"

    SwitchRow {
      label: "Screen-share picker"
      description: "Choose what to share in Skein's own window, with previews of your monitors and windows"
      checked: root.sharePicker
      onToggled: value => {
        root.sharePicker = value;
        Quickshell.execDetached([root.sharePickerTool, value ? "enable" : "disable"]);
      }
    }

    SwitchRow {
      label: "Weather"
      description: "Check the weather for the bar"
      checked: root.sys.weather ?? true
      onToggled: value => root.backend.set("weather", value, "skein-toggle-weather-check")
    }

    SwitchRow {
      label: "Update checks"
      description: "Look for Skein updates in the background"
      checked: root.sys.updateCheck ?? true
      onToggled: value => root.backend.set("updateCheck", value, "skein-toggle-update-check")
    }

    SwitchRow {
      label: "Crash capture"
      description: "Save a report when a program crashes"
      checked: root.sys.crashCapture ?? true
      onToggled: value => root.backend.set("crashCapture", value, "skein-toggle-crash-capture")
    }
  }

  SettingsSection {
    title: "Updates"

    ButtonRow {
      label: "Update"
      description: "Update Skein and the system packages"
      buttonText: "Run update"
      onClicked: {
        root.backend.close();
        Quickshell.execDetached(["sh", "-c", `${Skein.skeinPath}/libexec/skein-menu update`]);
      }
    }
  }

  // Power actions need a second click, so a stray one can't end your session
  property string armed: ""

  Timer {
    id: disarm

    interval: 4000
    onTriggered: root.armed = ""
  }

  function confirm(key: string, script: string): void {
    if (armed === key) {
      armed = "";
      backend.close();
      backend.run(script);
    } else {
      armed = key;
      disarm.restart();
    }
  }

  SettingsSection {
    title: "Session"

    ButtonRow {
      label: "Log out"
      description: root.armed === "logout" ? "Click again to log out" : ""
      buttonText: root.armed === "logout" ? "Confirm" : "Log out"
      onClicked: root.confirm("logout", "skein-system-logout")
    }

    ButtonRow {
      label: "Reboot"
      description: root.armed === "reboot" ? "Click again to reboot" : ""
      buttonText: root.armed === "reboot" ? "Confirm" : "Reboot"
      onClicked: root.confirm("reboot", "skein-system-reboot")
    }

    ButtonRow {
      label: "Shut down"
      description: root.armed === "shutdown" ? "Click again to shut down" : ""
      buttonText: root.armed === "shutdown" ? "Confirm" : "Shut down"
      onClicked: root.confirm("shutdown", "skein-system-shutdown")
    }
  }
}
