import QtQuick

// Settings > Power & Idle: power profile, idle lock, screensaver, update checks.
SettingsPage {
  id: root

  readonly property var sys: backend?.sysState ?? ({})

  SettingsSection {
    title: "Power"

    ComboRow {
      label: "Power profile"
      options: (root.sys.profiles ?? []).map(p => ({
            label: p,
            value: p
          }))
      current: root.sys.profile ?? ""
      onChosen: value => root.backend.set("profile", value, "skein-powerprofiles-set", [value])
    }
  }

  SettingsSection {
    title: "Idle"

    SwitchRow {
      label: "Lock when idle"
      description: "Lock the screen and turn the display off after a while"
      checked: root.sys.idle ?? false
      onToggled: value => root.backend.set("idle", value, "skein-toggle-idle")
    }

    SwitchRow {
      label: "Screensaver"
      checked: root.sys.screensaver ?? true
      onToggled: value => root.backend.set("screensaver", value, "skein-toggle-screensaver")
    }

    ButtonRow {
      label: "Lock now"
      buttonText: "Lock"
      onClicked: {
        root.backend.close();
        root.backend.run("skein-system-lock");
      }
    }
  }
}
