import QtQuick

// Month calendar with ISO week numbers, today marked and the year's progress.
Panel {
  id: root

  required property date now

  property int monthOffset: 0 // months away from the current one

  readonly property string mono: "JetBrainsMono Nerd Font"
  readonly property var english: Qt.locale("en_US")
  readonly property var weekdays: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
  readonly property date viewMonth: new Date(now.getFullYear(), now.getMonth() + monthOffset, 1)
  readonly property int yearPercent: {
    const start = new Date(now.getFullYear(), 0, 1);
    const end = new Date(now.getFullYear() + 1, 0, 1);
    const day = Math.floor((new Date(now.getFullYear(), now.getMonth(), now.getDate()) - start) / 86400000) + 1;
    return Math.round(100 * day / Math.round((end - start) / 86400000));
  }

  // Six weeks starting on Sunday, with days of the neighbouring months filling the gaps
  readonly property var weeks: {
    const first = new Date(viewMonth.getFullYear(), viewMonth.getMonth(), 1 - viewMonth.getDay());
    const rows = [];
    for (let row = 0; row < 6; row++) {
      const days = [];
      for (let column = 0; column < 7; column++) {
        const date = new Date(first.getFullYear(), first.getMonth(), first.getDate() + row * 7 + column);
        days.push({
          day: date.getDate(),
          inMonth: date.getMonth() === viewMonth.getMonth(),
          today: date.getFullYear() === now.getFullYear() && date.getMonth() === now.getMonth() && date.getDate() === now.getDate(),
          weekend: column === 0 || column === 6
        });
      }
      const monday = new Date(first.getFullYear(), first.getMonth(), first.getDate() + row * 7 + 1);
      rows.push({
        week: isoWeek(monday),
        days: days
      });
    }
    return rows;
  }

  function isoWeek(date: date): int {
    const day = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    day.setUTCDate(day.getUTCDate() + 4 - (day.getUTCDay() || 7));
    const yearStart = new Date(Date.UTC(day.getUTCFullYear(), 0, 1));
    return Math.ceil(((day - yearStart) / 86400000 + 1) / 7);
  }

  panelWidth: 600
  centered: true
  onOpenChanged: if (open) {
    monthOffset = 0
  }

  component Caption: Text {
    color: Qt.alpha(Omadora.foreground, 0.6)
    font.family: root.mono
    font.pointSize: Omadora.fontSize - 2.5
    font.letterSpacing: 1
  }

  // Scroll to change month
  WheelHandler {
    onWheel: event => root.monthOffset += event.angleDelta.y > 0 ? -1 : 1
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 18

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Omadora.glyph(0xf00ed)
      color: Omadora.accent
      font.family: root.mono
      font.pointSize: Omadora.pt(30)
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.english.toString(root.now, "MMMM d")
      color: Omadora.accent
      font.family: root.mono
      font.pointSize: Omadora.pt(30)
      font.bold: true
    }
  }

  Item {
    width: parent.width
    height: 16

    Caption {
      id: yearLabel

      anchors.verticalCenter: parent.verticalCenter
      text: `${root.now.getFullYear()}`
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      x: yearLabel.width + 16
      width: parent.width - x - percent.width - 16
      height: 6
      color: Qt.alpha(Omadora.foreground, 0.12)

      Rectangle {
        width: parent.width * root.yearPercent / 100
        height: parent.height
        color: Omadora.accent
      }
    }

    Caption {
      id: percent

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: `${root.yearPercent}%`
    }
  }

  // Weekday headers
  Row {
    width: parent.width

    Caption {
      width: 40
      horizontalAlignment: Text.AlignHCenter
      text: "W"
      opacity: 0.6
    }

    Repeater {
      model: root.weekdays

      Caption {
        required property string modelData

        width: (parent.width - 40) / 7
        horizontalAlignment: Text.AlignHCenter
        text: modelData
      }
    }
  }

  Column {
    width: parent.width

    Repeater {
      model: root.weeks

      Row {
        id: week

        required property var modelData

        width: parent.width
        height: 44

        Item {
          width: 40
          height: parent.height

          Text {
            anchors.centerIn: parent
            text: `${week.modelData.week}`
            color: Qt.alpha(Omadora.foreground, 0.3)
            font.family: root.mono
            font.pointSize: Omadora.fontSize - 1
          }

          Rectangle {
            anchors.right: parent.right
            height: parent.height
            width: 1
            color: Qt.alpha(Omadora.foreground, 0.1)
          }
        }

        Repeater {
          model: week.modelData.days

          Item {
            id: cell

            required property var modelData

            width: (week.width - 40) / 7
            height: week.height

            Rectangle {
              anchors.centerIn: parent
              width: 42
              height: 36
              visible: cell.modelData.today
              color: "transparent"
              border.width: 1
              border.color: Qt.alpha(Omadora.foreground, 0.6)
            }

            Text {
              anchors.centerIn: parent
              text: `${cell.modelData.day}`
              color: Omadora.foreground
              opacity: !cell.modelData.inMonth ? 0.25 : (cell.modelData.today ? 1 : (cell.modelData.weekend ? 0.5 : 0.9))
              font.family: root.mono
              font.pointSize: Omadora.fontSize + 1
            }
          }
        }
      }
    }
  }

  Item {
    width: parent.width
    height: 28

    Text {
      id: previous

      anchors.verticalCenter: parent.verticalCenter
      x: 10
      text: "‹"
      color: Qt.alpha(Omadora.foreground, previousMouse.containsMouse ? 1 : 0.6)
      font.family: root.mono
      font.pointSize: Omadora.fontSize + 4

      MouseArea {
        id: previousMouse

        anchors.fill: parent
        anchors.margins: -8
        hoverEnabled: true
        onClicked: root.monthOffset--
      }
    }

    // Click the month to come back to today
    Caption {
      anchors.centerIn: parent
      text: `${root.english.monthName(root.viewMonth.getMonth(), Locale.LongFormat).toUpperCase()} ${root.viewMonth.getFullYear()}`

      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        onClicked: root.monthOffset = 0
      }
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: "›"
      color: Qt.alpha(Omadora.foreground, nextMouse.containsMouse ? 1 : 0.6)
      font.family: root.mono
      font.pointSize: Omadora.fontSize + 4

      MouseArea {
        id: nextMouse

        anchors.fill: parent
        anchors.margins: -8
        hoverEnabled: true
        onClicked: root.monthOffset++
      }
    }
  }
}
