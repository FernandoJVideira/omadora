import QtQuick
import Quickshell

// Notification center: everything still open, newest first, with do-not-disturb and clear all.
Panel {
  id: root

  readonly property var notifications: Skein.notifications.filter(n => n.appName !== "Spotify").slice().reverse()

  function activate(notification: var): void {
    const action = notification.actions.find(a => a.identifier === "default");
    if (action) {
      action.invoke();
    }
    notification.dismiss();
  }

  function clearAll(): void {
    for (const notification of [...root.notifications]) {
      notification.dismiss();
    }
  }

  function iconOf(notification: var): string {
    if (notification.image !== "") {
      return notification.image;
    }
    return notification.appIcon !== "" ? Quickshell.iconPath(notification.appIcon, true) ?? "" : "";
  }

  panelWidth: 400

  Item {
    width: parent.width
    height: 30

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "Notifications"
      color: Skein.foreground
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize + 2
      font.bold: true
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8

      Repeater {
        model: [
          {
            kind: "dnd"
          },
          {
            kind: "clear"
          }
        ]

        Rectangle {
          required property var modelData

          readonly property bool isDnd: modelData.kind === "dnd"

          visible: isDnd || root.notifications.length > 0
          width: label.implicitWidth + 22
          height: 26
          radius: height / 2
          color: isDnd && Skein.silenced ? Qt.alpha(Skein.accent, 0.9) : (mouse.containsMouse ? Qt.alpha(Skein.foreground, 0.14) : Qt.alpha(Skein.foreground, 0.07))
          border.width: 1
          border.color: isDnd && Skein.silenced ? Qt.alpha(Skein.accent, 0.9) : Qt.alpha(Skein.foreground, 0.16)

          Text {
            id: label

            anchors.centerIn: parent
            text: parent.isDnd ? `${Skein.glyph(Skein.silenced ? 0xf009b : 0xf009a)}  Do Not Disturb` : "Clear all"
            color: Skein.foreground
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize - 1
          }

          MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.isDnd ? Skein.silenced = !Skein.silenced : root.clearAll()
          }
        }
      }
    }
  }

  Text {
    visible: root.notifications.length === 0
    width: parent.width
    topPadding: 20
    bottomPadding: 24
    horizontalAlignment: Text.AlignHCenter
    text: "No new notifications"
    color: Qt.alpha(Skein.foreground, 0.5)
    font.family: Skein.fontFamily
    font.pointSize: Skein.fontSize
  }

  Flickable {
    visible: root.notifications.length > 0
    width: parent.width
    height: Math.min(list.implicitHeight, 460)
    contentHeight: list.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: list

      width: parent.width
      spacing: 8

      Repeater {
        model: root.notifications

        Rectangle {
          id: card

          required property var modelData

          width: list.width
          height: cardBody.implicitHeight + 22
          radius: 12
          color: cardMouse.containsMouse ? Qt.alpha(Skein.foreground, 0.1) : Qt.alpha(Skein.foreground, 0.06)
          border.width: 1
          border.color: modelData.urgency === 2 ? Qt.alpha(Skein.accent, 0.8) : Qt.alpha(Skein.foreground, 0.12)

          MouseArea {
            id: cardMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.activate(card.modelData)
          }

          Row {
            id: cardBody

            x: 12
            y: 11
            width: parent.width - 24
            spacing: 10

            Image {
              visible: root.iconOf(card.modelData) !== ""
              width: visible ? 34 : 0
              height: 34
              source: root.iconOf(card.modelData)
              sourceSize: Qt.size(68, 68)
              fillMode: Image.PreserveAspectFit
              asynchronous: true
            }

            Column {
              width: parent.width - (root.iconOf(card.modelData) !== "" ? 44 : 0) - 26
              spacing: 2

              Text {
                width: parent.width
                elide: Text.ElideRight
                visible: text !== ""
                text: card.modelData.appName
                textFormat: Text.PlainText
                color: Qt.alpha(Skein.foreground, 0.55)
                font.family: Skein.fontFamily
                font.pointSize: Skein.fontSize - 2
                font.letterSpacing: 0.5
              }

              Text {
                width: parent.width
                text: card.modelData.summary
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Skein.foreground
                font.family: Skein.fontFamily
                font.pointSize: Skein.fontSize
                font.bold: true
              }

              Text {
                visible: text !== ""
                width: parent.width
                text: card.modelData.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: Qt.alpha(Skein.foreground, 0.85)
                font.family: Skein.fontFamily
                font.pointSize: Skein.fontSize - 0.5
              }
            }

            Text {
              width: 16
              text: "✕"
              horizontalAlignment: Text.AlignHCenter
              color: Qt.alpha(Skein.foreground, 0.5)
              font.pointSize: Skein.fontSize - 1

              MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: card.modelData.dismiss()
              }
            }
          }
        }
      }
    }
  }
}
