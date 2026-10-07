import QtQuick
import Quickshell.Services.Pipewire

// Default output volume: click opens the mixer, right click mutes, scroll changes volume by 5%.
BarItem {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property real volume: sink?.audio?.volume ?? 0
  readonly property bool muted: sink?.audio?.muted ?? false
  readonly property bool headphones: {
    const props = sink?.properties ?? {};
    const description = `${props["device.form-factor"] ?? ""} ${sink?.name ?? ""} ${sink?.description ?? ""}`.toLowerCase();
    return description.includes("headphone") || description.includes("headset");
  }

  text: {
    if (!sink) {
      return "";
    }
    if (muted) {
      return Omadora.glyph(0xeee8);
    }
    if (headphones) {
      return Omadora.glyph(0xf025);
    }
    const levels = [0xf026, 0xf027, 0xf028];
    return Omadora.glyph(levels[Math.min(levels.length - 1, Math.floor(volume * levels.length))]);
  }
  tooltip: `Playing at ${Math.round(volume * 100)}%`
  onLeftClicked: Omadora.run("omadora-exec omadora-launch-audio")
  onRightClicked: Omadora.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  onScrolled: delta => {
    if (sink?.audio && delta !== 0) {
      sink.audio.volume = Math.max(0, Math.min(1, volume + (delta > 0 ? 0.05 : -0.05)));
    }
  }

  PwObjectTracker {
    objects: [root.sink]
  }
}
