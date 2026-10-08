import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland

// Notification daemon and popups (replaces Mako).
Scope {
  id: root

  readonly property int popupWidth: 420
  readonly property int outerMargin: 20
  readonly property int defaultTimeout: 8000

  property int shownCount: 0

  function visibleItems(): var {
    const out = [];
    for (let i = 0; i < popups.count; i++) {
      const item = popups.itemAt(i);
      if (item && item.shown) {
        out.push(item);
      }
    }
    return out;
  }

  // The popup window is only mapped while something is shown, so layout can't drive this
  function recount(): void {
    root.shownCount = root.visibleItems().length;
  }

  NotificationServer {
    id: server

    keepOnReload: false
    actionsSupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: false
    imageSupported: true
    persistenceSupported: true

    onNotification: notification => {
      notification.tracked = true;
    }
  }

  IpcHandler {
    target: "notifications"

    function dismiss(): void {
      const shown = root.visibleItems();
      if (shown.length > 0) {
        shown[shown.length - 1].notification.dismiss();
      }
    }

    function dismissAll(): void {
      for (const n of [...server.trackedNotifications.values]) {
        n.dismiss();
      }
    }

    function dismissBySummary(summary: string): void {
      const match = server.trackedNotifications.values.find(n => n.summary.includes(summary));
      if (match) {
        match.dismiss();
      }
    }

    function invokeLast(): void {
      const shown = root.visibleItems();
      if (shown.length > 0) {
        shown[shown.length - 1].activate();
      }
    }

    // Bring back the newest popup that timed out
    function restoreLast(): void {
      for (let i = popups.count - 1; i >= 0; i--) {
        const item = popups.itemAt(i);
        if (item && !item.shown && !item.suppressed) {
          item.expired = false;
          item.restart();
          return;
        }
      }
    }

    function toggleSilenced(): bool {
      Omadora.silenced = !Omadora.silenced;
      return Omadora.silenced;
    }

    function isSilenced(): bool {
      return Omadora.silenced;
    }
  }

  PanelWindow {
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: root.shownCount > 0
    anchors {
      top: true
      right: true
    }
    margins {
      top: root.outerMargin
      right: root.outerMargin
    }
    implicitWidth: root.popupWidth
    implicitHeight: Math.max(1, Math.min(stack.childrenRect.height, 500))
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omadora-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
      id: stack

      width: parent.width
      spacing: 10

      // Newest on top
      Repeater {
        id: popups

        model: server.trackedNotifications

        delegate: Rectangle {
          id: popup

          required property var modelData
          required property int index
          readonly property var notification: modelData
          property bool expired: false
          readonly property bool suppressed: notification.appName === "Spotify" || (Omadora.silenced && notification.appName !== "notify-send")
          readonly property bool critical: notification.urgency === NotificationUrgency.Critical
          readonly property string iconSource: notification.image !== "" ? notification.image : (notification.appIcon !== "" ? Quickshell.iconPath(notification.appIcon, true) ?? "" : "")

          function restart(): void {
            expiry.restart();
          }

          function activate(): void {
            if (notification.summary.includes("Welcome to Omadora")) {
              Omadora.run("omadora-exec omadora-menu-keybindings");
            } else {
              const action = notification.actions.find(a => a.identifier === "default");
              if (action) {
                action.invoke();
              }
            }
            notification.dismiss();
          }

          readonly property bool shown: !expired && !suppressed

          onShownChanged: root.recount()
          Component.onCompleted: root.recount()
          Component.onDestruction: Qt.callLater(root.recount)

          visible: shown
          width: stack.width
          height: shown ? body.implicitHeight + 25 : 0
          z: -index
          color: Omadora.background
          border.width: 1
          border.color: Omadora.accent

          // Show again when a notification is replaced in place (e.g. volume steps)
          Connections {
            target: popup.notification

            function onSummaryChanged() {
              popup.expired = false;
              expiry.restart();
            }

            function onBodyChanged() {
              popup.expired = false;
              expiry.restart();
            }
          }

          Timer {
            id: expiry

            readonly property real requested: popup.notification.expireTimeout // milliseconds

            interval: popup.critical ? 0 : (requested > 0 ? requested : root.defaultTimeout)
            running: interval > 0 && popup.shown
            onTriggered: popup.expired = true
          }

          Row {
            id: body

            x: 15
            y: 10
            width: parent.width - 30
            spacing: 10

            Image {
              visible: popup.iconSource !== ""
              width: visible ? 32 : 0
              height: 32
              source: popup.iconSource
              sourceSize: Qt.size(64, 64)
              fillMode: Image.PreserveAspectFit
              asynchronous: true
            }

            Column {
              width: parent.width - (popup.iconSource !== "" ? 42 : 0)
              spacing: 4

              Text {
                width: parent.width
                text: popup.notification.summary
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: Omadora.foreground
                font.family: Omadora.fontFamily
                font.pointSize: Omadora.pt(10)
                font.bold: true
              }

              Text {
                visible: text !== ""
                width: parent.width
                text: popup.notification.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                color: Omadora.foreground
                font.family: Omadora.fontFamily
                font.pointSize: Omadora.pt(10)
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.button === Qt.RightButton ? popup.notification.dismiss() : popup.activate()
          }
        }
      }
    }
  }
}
