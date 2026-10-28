import QtQuick
import Quickshell
import Quickshell.Io

// Settings > Users: list, add and remove accounts, administrator rights and passwords.
// Changes go through polkit, so a password prompt appears for each one.
SettingsPage {
  id: root

  readonly property string scripts: `${Skein.skeinPath}/libexec`
  property var users: []
  property string confirming: "" // account whose delete button was pressed once
  property bool deleteHome: false
  property int avatarRev: 0
  readonly property bool nameValid: /^[a-z_][a-z0-9_-]{0,31}$/.test(newName.text) && !users.some(u => u.name === newName.text)

  function q(text: string): string {
    return `'${text.replace(/'/g, "'\\''")}'`;
  }

  function terminal(command: string): void {
    backend.external([`${scripts}/skein-launch-floating-terminal-with-presentation`, command], false);
  }

  function run(script: string, args: var): void {
    Quickshell.execDetached([`${scripts}/${script}`, ...args]);
    refreshTimer.restart();
  }

  Component.onCompleted: listProc.running = true

  // The settings window closes while the file chooser is open and comes back afterwards
  function avatar(args: var): void {
    backend.external([`${scripts}/skein-user-avatar`, ...args], true);
  }

  Process {
    id: listProc

    command: [`${root.scripts}/skein-users-list`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.users = JSON.parse(text.trim());
        } catch (e) {
          // keep the last list
        }
      }
    }
  }

  // Polkit prompts and terminals finish at their own pace: keep looking while the page is open
  Timer {
    id: refreshTimer

    interval: 3000
    repeat: true
    running: true
    onTriggered: if (!listProc.running) {
      listProc.running = true;
    }
  }

  Repeater {
    model: root.users

    SettingsSection {
      id: section

      required property var modelData

      title: modelData.current ? `${modelData.name} (you)` : modelData.name

      SettingsRow {
        label: modelData.fullName || modelData.name
        description: `UID ${modelData.uid} · ${modelData.home} · ${modelData.shell}`
        implicitHeight: Math.round(72 * Skein.textScale)

        Avatar {
          width: Math.round(48 * Skein.textScale)
          height: width
          name: modelData.name
          source: `${modelData.home}/.face`
          revision: root.avatarRev
        }
      }

      ButtonRow {
        visible: modelData.current
        label: "Picture"
        description: "Shown on the login screen and in the sidebar"
        buttonText: "Choose…"
        onClicked: root.avatar([])
      }

      ButtonRow {
        visible: modelData.current
        label: "Remove picture"
        buttonText: "Remove"
        onClicked: root.avatar(["--remove"])
      }

      SwitchRow {
        label: "Administrator"
        description: "Can run commands as root (the wheel group)"
        checked: modelData.admin
        enabled: !(modelData.current && modelData.admin)
        onToggled: value => root.run("skein-user-admin", [modelData.name, value ? "on" : "off"])
      }

      TextInputRow {
        label: "Full name"
        text: modelData.fullName
        placeholder: modelData.name
        onAccepted: value => root.run("skein-user-fullname", [modelData.name, value])
      }

      ButtonRow {
        label: "Password"
        buttonText: "Change…"
        onClicked: root.terminal(`${root.scripts}/skein-user-password ${root.q(modelData.name)}`)
      }

      ButtonRow {
        visible: !modelData.current
        label: root.confirming === modelData.name ? "Delete this account?" : "Delete account"
        description: root.confirming === modelData.name ? "This can't be undone" : ""
        buttonText: root.confirming === modelData.name ? "Yes, delete" : "Delete"
        onClicked: {
          if (root.confirming === modelData.name) {
            root.confirming = "";
            root.run("skein-user-delete", root.deleteHome ? [modelData.name, "home"] : [modelData.name]);
          } else {
            root.confirming = modelData.name;
          }
        }
      }

      CheckRow {
        visible: root.confirming === modelData.name
        label: "Also delete the home folder"
        checked: root.deleteHome
        onToggled: value => root.deleteHome = value
      }
    }
  }

  SettingsSection {
    title: "Add user"

    TextInputRow {
      id: newName

      label: "User name"
      description: text !== "" && !root.nameValid ? "Lowercase letters, digits, - and _; not taken" : ""
      placeholder: "name"
    }

    TextInputRow {
      id: newFull

      label: "Full name"
      placeholder: "optional"
    }

    CheckRow {
      id: newAdmin

      label: "Administrator"
    }

    ButtonRow {
      label: "Create account"
      description: "Opens a terminal to set its password"
      buttonText: "Create"
      enabled: root.nameValid
      onClicked: {
        root.terminal(`${root.scripts}/skein-user-add ${root.q(newName.text)} ${root.q(newFull.text)} ${newAdmin.checked ? "admin" : "user"}`);
        newName.text = "";
        newFull.text = "";
        newAdmin.checked = false;
      }
    }
  }
}
