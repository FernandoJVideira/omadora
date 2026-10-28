import QtQuick

// Settings > Windows: tiling layout, gaps and window shape.
SettingsPage {
  id: root

  readonly property var sys: backend?.sysState ?? ({})
  readonly property bool customSound: Skein.notificationSound.startsWith("/")
  readonly property var soundOptions: {
    const named = [
      ["default", "Default"],
      ["message", "Message"],
      ["bell", "Bell"],
      ["complete", "Complete"],
      ["dialog-information", "Information"],
      ["window-attention", "Attention"],
      ["device-added", "Device added"],
      ["service-login", "Chime"],
      ["off", "Off"]
    ].map(entry => ({
          label: entry[1],
          value: entry[0]
        }));
    // A picked file gets its own entry so the list shows what is set
    return customSound ? [
      {
        label: "Custom file",
        value: Skein.notificationSound
      }
    ].concat(named) : named;
  }

  SettingsSection {
    title: "Layout"

    ComboRow {
      label: "Workspace layout"
      description: "For the current workspace"
      options: [
        {
          label: "Dwindle",
          value: "dwindle"
        },
        {
          label: "Scrolling",
          value: "scrolling"
        }
      ]
      current: root.sys.layout ?? "dwindle"
      onChosen: value => {
        if (value !== root.sys.layout) {
          root.backend.set("layout", value, "skein-hyprland-workspace-layout-toggle");
        }
      }
    }

    SwitchRow {
      label: "Window gaps"
      checked: root.sys.gaps ?? true
      onToggled: value => root.backend.set("gaps", value, "skein-hyprland-window-gaps-toggle")
    }

    SwitchRow {
      label: "Square single window"
      description: "Keep a lone window at a 1:1 aspect ratio"
      checked: root.sys.squareAspect ?? false
      onToggled: value => root.backend.set("squareAspect", value, "skein-hyprland-window-single-square-aspect-toggle")
    }
  }

  SettingsSection {
    title: "Notifications"

    SwitchRow {
      label: "Silence notifications"
      checked: Skein.silenced
      onToggled: value => Skein.silenced = value
    }

    ComboRow {
      label: "Notification sound"
      description: "Played when a notification arrives. Silenced notifications stay quiet."
      options: root.soundOptions
      current: Skein.notificationSound
      onChosen: value => {
        Skein.setBar("notificationSound", value);
        Skein.playNotificationSound(value);
      }
    }

    ButtonRow {
      label: root.customSound ? `Custom sound: ${Skein.notificationSound.split("/").pop()}` : "Your own sound"
      description: "Pick any audio file from your computer"
      buttonText: "Choose…"
      onClicked: root.backend.external([`${Skein.skeinPath}/libexec/skein-notification-sound`, "choose"], true)
    }

    ButtonRow {
      label: "Preview"
      enabled: Skein.notificationSound !== "off"
      buttonText: "Play"
      onClicked: Skein.playNotificationSound("")
    }
  }
}
