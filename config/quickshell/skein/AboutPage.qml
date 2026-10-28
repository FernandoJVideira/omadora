import QtQuick
import Quickshell
import Quickshell.Io

// Settings > About: the computer, the OS and the desktop.
SettingsPage {
  id: root

  property var info: ({})
  property string packages: "…"

  function line(value: var): string {
    return Array.isArray(value) ? value.join("\n") : (value ?? "");
  }

  Component.onCompleted: {
    infoProc.running = true;
    packagesProc.running = true;
  }

  // Counting packages is slow the first time, so it loads after the rest of the page
  Process {
    id: packagesProc

    command: [`${Skein.skeinPath}/libexec/skein-about-packages`]
    stdout: StdioCollector {
      onStreamFinished: root.packages = text.trim()
    }
  }

  Process {
    id: infoProc

    command: [`${Skein.skeinPath}/libexec/skein-about-info`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.info = JSON.parse(text.trim());
        } catch (e) {
          // keep empty
        }
      }
    }
  }

  Item {
    width: parent.width
    height: Math.round(130 * Skein.textScale)

    Image {
      id: logo

      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      width: Math.round(96 * Skein.textScale)
      height: width
      source: root.info.logo ? `file://${root.info.logo}` : ""
      sourceSize: Qt.size(256, 256)
      fillMode: Image.PreserveAspectFit
      smooth: true
    }

    Column {
      anchors.left: logo.right
      anchors.leftMargin: 18
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      Text {
        text: root.info.osName ?? ""
        color: Skein.foreground
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize + 8
        font.bold: true
      }

      Text {
        text: root.info.osVersion ?? ""
        color: Qt.alpha(Skein.foreground, 0.7)
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize
      }

      Text {
        text: `${root.info.user ?? ""}@${root.info.host ?? ""} · Skein ${root.info.skein ?? ""}`
        color: Skein.accent
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize - 0.5
      }
    }
  }

  SettingsSection {
    title: "Computer"

    EditableRow {
      label: "Computer name"
      description: "Changing it needs your password; open terminals show the new name once restarted."
      value: root.info.host ?? ""
      placeholder: "hostname"
      onAccepted: text => {
        // The password prompt would open under this window, so it steps aside and comes back after
        root.backend.external([`${Skein.skeinPath}/libexec/skein-hostname`, "set", text], true);
      }
    }

    InfoRow {
      label: "Model"
      value: root.info.model ?? ""
    }

    InfoRow {
      label: "Processor"
      value: root.info.cpu ?? ""
    }

    InfoRow {
      label: "Graphics"
      value: root.line(root.info.gpus)
    }

    InfoRow {
      label: "Memory"
      value: root.info.memory ?? ""
    }

    InfoRow {
      label: "Storage"
      description: "Root partition"
      value: root.info.disk ?? ""
    }

    InfoRow {
      label: "Displays"
      value: root.line(root.info.screens)
    }
  }

  SettingsSection {
    title: "SkeinOS"

    InfoRow {
      label: "Operating system"
      value: root.info.os ?? ""
    }

    InfoRow {
      label: "Based on"
      value: root.info.base ?? ""
    }

    InfoRow {
      label: "Kernel"
      value: root.info.kernel ?? ""
    }

    InfoRow {
      label: "Architecture"
      value: root.info.arch ?? ""
    }

    InfoRow {
      label: "Packages"
      value: root.packages
    }

    InfoRow {
      label: "Uptime"
      value: root.info.uptime ?? ""
    }
  }

  SettingsSection {
    title: "Desktop"

    InfoRow {
      label: "Skein"
      value: root.info.skein ?? ""
    }

    InfoRow {
      label: "Hyprland"
      value: root.info.hyprland ?? ""
    }

    InfoRow {
      label: "Quickshell"
      value: root.info.quickshell ?? ""
    }

    InfoRow {
      label: "Session"
      value: root.info.session ?? ""
    }

    InfoRow {
      label: "User shell"
      value: `${root.info.user ?? ""} · ${root.info.shell ?? ""}`
    }
  }
}
