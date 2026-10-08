import QtQuick
import Quickshell.Hyprland

// "Tuesday 14:05"; click opens the calendar; tooltip shows the timezone. Always English day and month names.
BarItem {
  id: root

  required property var barWindow
  readonly property var english: Qt.locale("en_US")
  property date now: new Date()

  padded: true
  text: english.toString(now, "dddd HH:mm")
  tooltip: Qt.locale().toString(now, "t:ttt")
  onLeftClicked: calendar.toggle()
  onRightClicked: Omadora.run('omadora-exec omadora-launch-floating-terminal-with-presentation "omactl system timezone select"')

  Connections {
    target: Omadora

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
