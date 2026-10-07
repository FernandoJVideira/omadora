import QtQuick

// "Tuesday 14:05"; click for "07 October W41 2026"; tooltip shows the timezone.
BarItem {
  id: root

  property date now: new Date()
  property bool showDate: false

  function isoWeek(date: date): string {
    const day = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const weekday = day.getUTCDay() || 7;
    day.setUTCDate(day.getUTCDate() + 4 - weekday);
    const yearStart = new Date(Date.UTC(day.getUTCFullYear(), 0, 1));
    return String(Math.ceil(((day - yearStart) / 86400000 + 1) / 7)).padStart(2, "0");
  }

  padded: true
  text: showDate
    ? `${Qt.locale().toString(now, "dd MMMM")} W${isoWeek(now)} ${now.getFullYear()}`
    : Qt.locale().toString(now, "dddd HH:mm")
  tooltip: Qt.locale().toString(now, "t:ttt")
  onLeftClicked: showDate = !showDate
  onRightClicked: Omadora.run('omadora-exec omadora-launch-floating-terminal-with-presentation "omactl system timezone select"')

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }
}
