import QtQuick
import Quickshell.Io

// Mode indicators (ported from Omarchy): screen recording, reminders, night light, do not disturb and
// stay awake. They sit in the tray drawer: active ones always show, the inactive ones slide out with the
// tray (revealed). Clicking toggles the mode.
Item {
  id: root

  required property var barWindow

  property bool recording: false
  property bool stayAwake: false
  property bool nightLight: false
  property int reminders: 0

  property bool revealed: false
  readonly property bool anyShown: row.implicitWidth > 0

  function refresh(): void {
    if (!probe.running) {
      probe.running = true;
    }
  }

  height: parent ? parent.height : Skein.barHeight
  width: row.implicitWidth

  Process {
    id: probe

    command: ["bash", "-c", `
      pgrep -f '^gpu-screen-recorder' >/dev/null && echo rec=1 || echo rec=0
      systemctl --user is-active --quiet hypridle.service && echo awake=0 || echo awake=1
      echo night=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+' | head -1)
      echo reminders=$(systemctl --user list-timers --no-legend --no-pager 'skein-reminder-*.timer' 2>/dev/null | grep -c skein-reminder)
    `]
    stdout: StdioCollector {
      onStreamFinished: {
        const values = {};
        for (const line of text.split("\n")) {
          const [key, value] = line.split("=");
          values[key] = value;
        }
        root.recording = values.rec === "1";
        root.stayAwake = values.awake === "1";
        root.nightLight = values.night !== undefined && values.night !== "" && values.night !== "6000";
        root.reminders = Number(values.reminders) || 0;
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Connections {
    target: Skein

    function onRefreshRequested(module) {
      root.refresh();
    }
  }

  component Indicator: BarItem {
    property string glyph
    property bool active: false

    text: (active || root.revealed) ? glyph : ""
    dimmed: !active
  }

  Row {
    id: row

    height: parent.height

    Indicator {
      glyph: Skein.glyph(0xf0ec2)
      active: root.recording
      tooltip: active ? "Stop recording" : "Screen Recording"
      onLeftClicked: Skein.run(root.recording ? "skein-exec skein-capture-screenrecording --stop-recording" : "skein-exec skein-menu screenrecord")
    }

    Indicator {
      glyph: Skein.glyph(0xf088c)
      active: root.reminders > 0
      tooltip: root.reminders > 0 ? `${root.reminders} reminder${root.reminders === 1 ? "" : "s"}` : "Set a reminder"
      onLeftClicked: Skein.run(root.reminders > 0 ? "skein-exec skein-reminder show" : "skein-exec skein-menu reminder")
    }

    Indicator {
      glyph: Skein.glyph(0xf050e)
      active: root.nightLight
      tooltip: active ? "Day Light" : "Night Light"
      onLeftClicked: {
        Skein.run("skein-exec skein-toggle-nightlight");
        refreshTimer.restart();
      }
    }

    Indicator {
      glyph: Skein.glyph(0xf009b)
      active: Skein.silenced
      tooltip: active ? "Allow Notifications" : "Silence Notifications"
      onLeftClicked: Skein.run("skein-exec skein-toggle-notification-silencing")
    }

    Indicator {
      glyph: Skein.glyph(0xf0176)
      active: root.stayAwake
      tooltip: active ? "Allow Idle Lock & Screensaver" : "Stay Awake"
      onLeftClicked: {
        Skein.run("skein-exec skein-toggle-idle");
        refreshTimer.restart();
      }
    }
  }

  Timer {
    id: refreshTimer

    interval: 1200
    onTriggered: root.refresh()
  }
}
