import QtQuick
import Quickshell.Hyprland

// "Tuesday 14:05"; click opens the calendar; tooltip shows the timezone. Always English day and month names.
BarItem {
  id: root

  required property var barWindow
  readonly property var english: Qt.locale("en_US")
  property date now: new Date()

  padded: true
  text: {
    const time = Skein.clock24h ? (Skein.clockSeconds ? "HH:mm:ss" : "HH:mm") : (Skein.clockSeconds ? "h:mm:ss AP" : "h:mm AP");
    switch (Skein.clockStyle) {
    case "date":
      return english.toString(now, `ddd d MMM ${time}`);
    case "time":
      return english.toString(now, time);
    default:
      return english.toString(now, `dddd ${time}`);
    }
  }
  tooltip: Qt.locale().toString(now, "t:ttt")
  onLeftClicked: calendar.toggle()
  onRightClicked: Skein.run('skein-exec skein-launch-floating-terminal-with-presentation "skeinctl system timezone select"')

  Connections {
    target: Skein

    function onPanelRequested(name) {
      if (name === "calendar" && (calendar.open || root.barWindow.screen.name === Hyprland.focusedMonitor?.name)) {
        calendar.toggle();
      }
    }
  }

  CalendarPanel {
    id: calendar

    barWindow: root.barWindow
    now: root.now
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }
}
