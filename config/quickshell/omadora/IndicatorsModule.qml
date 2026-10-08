import QtQuick
import Quickshell.Io

// Mode indicators left of the clock (ported from Omarchy): screen recording, reminders, night light,
// do not disturb and stay awake. Active ones always show; hover to peek at the inactive ones.
// Clicking toggles the mode.
Item {
  id: root

  required property var barWindow

  property bool recording: false
  property bool stayAwake: false
  property bool nightLight: false
  property int reminders: 0

  readonly property bool revealed: hover.hovered
  readonly property bool anyShown: row.implicitWidth > 0

  function refresh(): void {
    if (!probe.running) {
      probe.running = true;
    }
  }

  height: parent ? parent.height : Omadora.barHeight
  // A little hover zone stays when nothing is active, so there is something to hover
  width: Math.max(row.implicitWidth, Math.round(18 * Omadora.textScale))

  HoverHandler {
    id: hover
  }

  Process {
    id: probe

    command: ["bash", "-c", `
      pgrep -f '^gpu-screen-recorder' >/dev/null && echo rec=1 || echo rec=0
      systemctl --user is-active --quiet hypridle.service && echo awake=0 || echo awake=1
      echo night=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+' | head -1)
      echo reminders=$(systemctl --user list-timers --no-legend --no-pager 'omadora-reminder-*.timer' 2>/dev/null | grep -c omadora-reminder)
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
    target: Omadora

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

    anchors.right: parent.right
    height: parent.height

    Indicator {
      glyph: Omadora.glyph(0xf0ec2)
      active: root.recording
      tooltip: active ? "Stop recording" : "Screen Recording"
      onLeftClicked: Omadora.run(root.recording ? "omadora-exec omadora-capture-screenrecording --stop-recording" : "omadora-exec omadora-menu screenrecord")
    }

    Indicator {
      glyph: Omadora.glyph(0xf088c)
      active: root.reminders > 0
      tooltip: root.reminders > 0 ? `${root.reminders} reminder${root.reminders === 1 ? "" : "s"}` : "Set a reminder"
      onLeftClicked: Omadora.run(root.reminders > 0 ? "omadora-exec omadora-reminder show" : "omadora-exec omadora-menu reminder")
    }

    Indicator {
      glyph: Omadora.glyph(0xf050e)
      active: root.nightLight
      tooltip: active ? "Day Light" : "Night Light"
      onLeftClicked: {
        Omadora.run("omadora-exec omadora-toggle-nightlight");
        refreshTimer.restart();
      }
    }

    Indicator {
      glyph: Omadora.glyph(0xf009b)
      active: Omadora.silenced
      tooltip: active ? "Allow Notifications" : "Silence Notifications"
      onLeftClicked: Omadora.run("omadora-exec omadora-toggle-notification-silencing")
    }

    Indicator {
      glyph: Omadora.glyph(0xf0176)
      active: root.stayAwake
      tooltip: active ? "Allow Idle Lock & Screensaver" : "Stay Awake"
      onLeftClicked: {
        Omadora.run("omadora-exec omadora-toggle-idle");
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
