import QtQuick
import Quickshell
import Quickshell.Io

// Settings > Agents: the default coding agent, and each agent's rate limits and token usage
// (the same data as the bar's agents panel, from libexec/agents/skein-agents-data).
SettingsPage {
  id: root

  readonly property var sys: backend?.sysState ?? ({})
  property var providers: []
  property real now: Date.now()

  function formatTokens(tokens: real): string {
    if (tokens >= 1e9) {
      return `${(tokens / 1e9).toFixed(1)}B`;
    }
    if (tokens >= 1e6) {
      return `${(tokens / 1e6).toFixed(1)}M`;
    }
    if (tokens >= 1e3) {
      return `${(tokens / 1e3).toFixed(1)}K`;
    }
    return `${tokens}`;
  }

  function formatReset(epoch: real): string {
    const minutes = Math.max(0, Math.round((epoch * 1000 - now) / 60000));
    const days = Math.floor(minutes / 1440);
    const hours = Math.floor((minutes % 1440) / 60);
    if (days > 0) {
      return `Resets in ${days}d ${hours}h`;
    }
    return hours > 0 ? `Resets in ${hours}h ${minutes % 60}m` : `Resets in ${minutes}m`;
  }

  function limitColor(percent: real): color {
    return percent >= 95 ? "#ff453a" : (percent >= 80 ? "#ff9f0a" : Skein.accent);
  }

  Component.onCompleted: load.running = true

  Process {
    id: load

    command: [`${Skein.skeinPath}/libexec/agents/skein-agents-data`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.providers = JSON.parse(text.trim());
          root.now = Date.now();
        } catch (e) {
          root.providers = [];
        }
      }
    }
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: if (!load.running) {
      load.running = true;
    }
  }

  SettingsSection {
    title: "Default agent"

    ComboRow {
      label: "Coding agent"
      description: "Opens with the agent shortcut. Choosing one installs it if needed and starts it."
      options: [["Claude", "claude"], ["Codex", "codex"], ["OpenCode", "opencode"], ["Antigravity", "agy"], ["Copilot", "copilot"], ["Crush", "crush"], ["Grok", "grok"], ["Cursor CLI", "cursor-agent"], ["Muse Code", "muse"], ["Pi", "pi"], ["Oh My Pi", "omp"], ["Ori", "ori"]].map(n => ({
            label: n[0],
            value: n[1]
          }))
      current: root.sys.agent ?? ""
      // The agent starts in a window of its own, so the settings window steps aside
      onChosen: value => root.backend.external([`${Skein.skeinPath}/libexec/skein-default-agent`, value], false)
    }
  }

  SettingsSection {
    title: "Claude Code limits"
    visible: root.providers.some(p => p.id === "claude")

    SwitchRow {
      label: "Track session and weekly limits"
      description: "Claude Code only reports them to its status line, so Skein hooks into it. Your own status line keeps working."
      checked: root.sys.claudeHook ?? false
      onToggled: value => {
        root.backend.set("claudeHook", value, "agents/skein-agents-setup", value ? ["claude"] : ["claude", "--remove"]);
      }
    }
  }

  Repeater {
    model: root.providers

    Column {
      id: provider

      required property var modelData

      width: root.width - 12
      spacing: 6

      SettingsSection {
        title: provider.modelData.plan ? `${provider.modelData.name} · ${provider.modelData.plan}` : provider.modelData.name

        Repeater {
          model: provider.modelData.limits

          SettingsRow {
            required property var modelData

            label: modelData.label
            description: root.formatReset(modelData.resetsAt)

            Row {
              spacing: 10

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(200 * Skein.textScale)
                height: 6
                radius: 3
                color: Qt.alpha(Skein.foreground, 0.15)

                Rectangle {
                  width: parent.width * Math.max(0, Math.min(1, modelData.percent / 100))
                  height: parent.height
                  radius: 3
                  color: root.limitColor(modelData.percent)
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(modelData.percent)}%`
                color: Skein.foreground
                font.family: Skein.fontFamily
                font.pointSize: Skein.fontSize
              }
            }
          }
        }

        SettingsRow {
          visible: provider.modelData.limits.length === 0
          label: "Limits"
          description: provider.modelData.limitsNote || "This agent doesn't report limits"
        }
      }

      SettingsSection {
        title: `${provider.modelData.name} tokens`

        Repeater {
          model: provider.modelData.days

          SettingsRow {
            required property var modelData

            label: modelData.label
            implicitHeight: Math.round(28 * Skein.textScale)

            Text {
              width: 70
              horizontalAlignment: Text.AlignRight
              text: root.formatTokens(modelData.tokens)
              color: modelData.label === "Today" ? Skein.foreground : Qt.alpha(Skein.foreground, 0.7)
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize
              font.bold: modelData.label === "Today"
            }
          }
        }

        Repeater {
          model: provider.modelData.models

          SettingsRow {
            required property var modelData

            label: modelData.name
            description: "Last 7 days"

            Text {
              text: root.formatTokens(modelData.tokens)
              color: Skein.foreground
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize
            }
          }
        }
      }
    }
  }
}
