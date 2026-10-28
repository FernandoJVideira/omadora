import QtQuick
import Quickshell.Services.Pipewire

// Settings > Audio: default output and input devices, volume and mute.
SettingsPage {
  id: root

  readonly property var nodes: Pipewire.nodes.values
  readonly property var sinks: nodes.filter(n => !n.isStream && (n.type & PwNodeType.AudioSink) === PwNodeType.AudioSink)
  readonly property var sources: nodes.filter(n => !n.isStream && (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource)
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource

  function label(node: var): string {
    return node.description || node.nickname || node.name;
  }

  PwObjectTracker {
    objects: root.nodes
  }

  SettingsSection {
    title: "Output"

    ComboRow {
      label: "Output device"
      options: root.sinks.map(n => ({
            label: root.label(n),
            value: n.name
          }))
      current: root.sink?.name ?? ""
      onChosen: value => Pipewire.preferredDefaultAudioSink = root.sinks.find(n => n.name === value)
    }

    SliderRow {
      label: "Volume"
      valueText: `${Math.round((root.sink?.audio?.volume ?? 0) * 100)}%`
      value: root.sink?.audio?.volume ?? 0
      maximum: 1
      onMoved: v => {
        if (root.sink?.audio) {
          root.sink.audio.volume = v;
        }
      }
    }

    SwitchRow {
      label: "Sound on"
      description: "Off mutes the output"
      checked: root.sink?.audio ? !root.sink.audio.muted : false
      enabled: root.sink?.audio !== undefined && root.sink?.audio !== null
      onToggled: value => root.sink.audio.muted = !value
    }
  }

  SettingsSection {
    title: "Input"

    ComboRow {
      label: "Input device"
      options: root.sources.map(n => ({
            label: root.label(n),
            value: n.name
          }))
      current: root.source?.name ?? ""
      onChosen: value => Pipewire.preferredDefaultAudioSource = root.sources.find(n => n.name === value)
    }

    SliderRow {
      label: "Volume"
      valueText: `${Math.round((root.source?.audio?.volume ?? 0) * 100)}%`
      value: root.source?.audio?.volume ?? 0
      onMoved: v => {
        if (root.source?.audio) {
          root.source.audio.volume = v;
        }
      }
    }

    SwitchRow {
      label: "Microphone on"
      checked: root.source?.audio ? !root.source.audio.muted : false
      enabled: root.source?.audio !== undefined && root.source?.audio !== null
      onToggled: value => root.source.audio.muted = !value
    }
  }
}
