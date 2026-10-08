import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

// Session lock screen (replaces Hyprlock). Password only, checked with PAM.
Scope {
  id: root

  property string buffer: ""
  property string message: ""
  property bool failed: false
  property bool busy: false

  function lock(): void {
    if (!sessionLock.locked) {
      root.buffer = "";
      root.message = "";
      root.failed = false;
      sessionLock.locked = true;
    }
  }

  function submit(): void {
    if (root.busy || root.buffer === "") {
      return;
    }
    root.busy = true;
    root.failed = false;
    pam.start();
  }

  IpcHandler {
    target: "lock"

    function lock(): void {
      root.lock();
    }

    function isLocked(): bool {
      return sessionLock.locked;
    }
  }

  PamContext {
    id: pam

    configDirectory: `${Omadora.home}/.config/quickshell/omadora/pam`
    config: "omadora-lock"

    onPamMessage: {
      if (responseRequired) {
        respond(root.buffer);
      }
    }

    onCompleted: result => {
      root.busy = false;
      root.buffer = "";
      if (result === PamResult.Success) {
        sessionLock.locked = false;
      } else {
        root.failed = true;
        root.message = "Wrong password";
      }
    }

    onError: {
      root.busy = false;
      root.failed = true;
      root.message = "Authentication error";
    }
  }

  WlSessionLock {
    id: sessionLock

    WlSessionLockSurface {
      id: surface

      color: Omadora.background

      SystemClock {
        id: clock

        precision: SystemClock.Minutes
      }

      Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
          if (root.busy) {
            return;
          }
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submit();
          } else if (event.key === Qt.Key_Backspace) {
            root.buffer = (event.modifiers & Qt.ControlModifier) ? "" : root.buffer.slice(0, -1);
          } else if (event.key === Qt.Key_Escape) {
            root.buffer = "";
          } else if (event.text !== "" && event.text >= " " && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            root.buffer += event.text;
          } else {
            return;
          }
          root.failed = false;
          root.message = "";
        }

        Column {
          anchors.centerIn: parent
          spacing: 24

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "hh:mm")
            color: Omadora.foreground
            font.family: Omadora.fontFamily
            font.pointSize: Omadora.pt(64)
          }

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300
            height: 50
            color: Qt.alpha(Omadora.background, 0.8)
            border.width: 2
            border.color: root.failed ? Omadora.alert : (root.busy ? Omadora.accent : Omadora.foreground)

            Text {
              anchors.centerIn: parent
              text: root.busy ? "Checking…" : (root.buffer === "" ? "Enter Password" : "●".repeat(root.buffer.length))
              elide: Text.ElideLeft
              width: parent.width - 20
              horizontalAlignment: Text.AlignHCenter
              color: root.buffer === "" ? Qt.alpha(Omadora.foreground, 0.5) : Omadora.foreground
              font.family: Omadora.fontFamily
              font.pointSize: Omadora.pt(12)
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.message
            color: Omadora.alert
            font.family: Omadora.fontFamily
            font.pointSize: Omadora.pt(11)
          }
        }
      }
    }
  }
}
