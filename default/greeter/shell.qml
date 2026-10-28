// Login screen: a Quickshell greeter for greetd, run inside cage (see remove-kde.sh), styled after
// Omarchy's: a plain background, the logo and a lock next to an outlined entry box that fills with bullets.
// Theme.qml (colors, users, logo, primary monitor) and the avatars are written by skein-greeter sync.
// Your picture and name sit above the entry box; "Switch user" lists the other accounts.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Greetd

ShellRoot {
  id: root

  // the Skein session, same command as /usr/share/wayland-sessions/skein.desktop
  readonly property var sessionCommand: ["uwsm", "start", "-e", "-D", "Hyprland", "-N", "Hyprland", "--", "/usr/bin/start-hyprland"]

  property string notice: ""
  property bool failed: false
  property bool busy: false
  property bool sessionOpen: false
  property string pending: ""
  property bool picking: false // the list of users is showing instead of the entry box

  // the people on this machine; falls back to the one user the theme names
  readonly property var users: theme.users.length > 0 ? theme.users : [{ name: theme.user, fullName: "", avatar: false }]
  property string selected: theme.user
  readonly property var selectedUser: users.find(u => u.name === selected) || users[0]

  function choose(name) {
    if (root.sessionOpen) {
      Greetd.cancelSession()
      root.sessionOpen = false
    }
    root.busy = false
    root.failed = false
    root.notice = ""
    root.selected = name
    root.picking = false
    entry.text = ""
    entry.forceActiveFocus()
  }

  Theme { id: theme }

  // cage stretches one window over every monitor, so the screens are laid out inside it by hand: the
  // form goes on the primary monitor and the others just get the background
  readonly property real originX: {
    var m = Infinity
    for (var i = 0; i < Quickshell.screens.length; i++) m = Math.min(m, Quickshell.screens[i].x)
    return m
  }
  readonly property real originY: {
    var m = Infinity
    for (var i = 0; i < Quickshell.screens.length; i++) m = Math.min(m, Quickshell.screens[i].y)
    return m
  }
  readonly property var primaryScreen: {
    var best = null
    for (var i = 0; i < Quickshell.screens.length; i++) {
      var s = Quickshell.screens[i]
      if (s.name === theme.primary) return s
      if (best === null || s.x < best.x) best = s
    }
    return best
  }

  Component.onCompleted: {
    // shows up in `journalctl -b -u greetd`: which monitor the form went to, and why
    for (var i = 0; i < Quickshell.screens.length; i++) {
      var s = Quickshell.screens[i]
      console.log("greeter screen", s.name, s.x, s.y, s.width, s.height)
    }
    console.log("greeter primary wanted:", theme.primary, "using:", root.primaryScreen ? root.primaryScreen.name : "none")
  }

  function submit() {
    if (root.busy || entry.text === "") return
    root.busy = true
    root.notice = ""
    root.pending = entry.text
    entry.text = ""
    if (root.sessionOpen) {
      Greetd.respond(root.pending)
      root.pending = ""
    } else {
      root.sessionOpen = true
      Greetd.createSession(root.selected)
    }
  }

  Connections {
    target: Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (responseRequired && root.pending !== "") {
        Greetd.respond(root.pending)
        root.pending = ""
        return
      }
      root.notice = message
      root.failed = error
      if (responseRequired) root.busy = false
    }

    function onAuthFailure(message) {
      root.sessionOpen = false
      root.busy = false
      root.failed = true
      entry.forceActiveFocus()
    }

    function onReadyToLaunch() {
      Greetd.launch(root.sessionCommand, ["XDG_SESSION_TYPE=wayland"])
    }

    function onError(error) {
      root.sessionOpen = false
      root.busy = false
      root.failed = true
      root.notice = error
    }
  }

  FloatingWindow {
    visible: true
    color: theme.background

    Rectangle {
      anchors.fill: parent
      color: theme.background
    }

    Item {
      x: root.primaryScreen ? root.primaryScreen.x - root.originX : 0
      y: root.primaryScreen ? root.primaryScreen.y - root.originY : 0
      width: root.primaryScreen ? root.primaryScreen.width : parent.width
      height: root.primaryScreen ? root.primaryScreen.height : parent.height

      // A round picture of a user, or their initial when they have none
      component Avatar: Item {
        id: avatar

        property var user: null
        property int size: 96

        width: size
        height: size

        Rectangle {
          id: mask
          anchors.fill: parent
          radius: width / 2
          visible: false
          layer.enabled: true
        }

        Rectangle {
          anchors.fill: parent
          radius: width / 2
          color: Qt.alpha(theme.accent, 0.8)
          border.width: 2
          border.color: theme.accent
          visible: !photo.visible

          Text {
            anchors.centerIn: parent
            text: avatar.user ? avatar.user.name.charAt(0).toUpperCase() : ""
            color: theme.background
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: avatar.size * 0.4
            font.bold: true
          }
        }

        Image {
          id: photo
          anchors.fill: parent
          visible: avatar.user !== null && avatar.user.avatar && status === Image.Ready
          source: avatar.user && avatar.user.avatar ? Qt.resolvedUrl("avatars/" + avatar.user.name + ".png") : ""
          sourceSize: Qt.size(192, 192)
          fillMode: Image.PreserveAspectCrop
          cache: false
          layer.enabled: true
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
          }
        }
      }

      Column {
        anchors.centerIn: parent
        spacing: 40

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: theme.logo
          color: theme.accent
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          horizontalAlignment: Text.AlignHCenter
        }

        // Who is logging in
        Column {
          visible: !root.picking
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 14

          Avatar {
            anchors.horizontalCenter: parent.horizontalCenter
            user: root.selectedUser
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.selectedUser.fullName !== "" ? root.selectedUser.fullName : root.selectedUser.name
            color: theme.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 22
            font.bold: true
          }
        }

        // The list of accounts, after "Switch user"
        Row {
          visible: root.picking
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 36

          Repeater {
            model: root.users

            Item {
              id: tileItem

              required property var modelData

              width: tileColumn.width
              height: tileColumn.height

              Column {
                id: tileColumn

                spacing: 12

                Avatar {
                  anchors.horizontalCenter: parent.horizontalCenter
                  user: tileItem.modelData
                  size: 88
                  opacity: tile.containsMouse || tileItem.modelData.name === root.selected ? 1 : 0.7
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: tileItem.modelData.fullName !== "" ? tileItem.modelData.fullName : tileItem.modelData.name
                  color: tileItem.modelData.name === root.selected ? theme.accent : theme.foreground
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 16
                }
              }

              MouseArea {
                id: tile
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.choose(tileItem.modelData.name)
              }
            }
          }
        }

        Row {
          visible: !root.picking
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 15

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: root.failed ? theme.red : theme.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 40
          }

          Rectangle {
            width: 360
            height: 56
            color: "transparent"
            border.width: 2
            border.color: root.failed ? theme.red : theme.foreground

            Row {
              anchors.left: parent.left
              anchors.leftMargin: 20
              anchors.verticalCenter: parent.verticalCenter
              spacing: 5

              Repeater {
                model: Math.min(entry.text.length, 21)

                Rectangle {
                  width: 9
                  height: 9
                  radius: 4.5
                  color: root.failed ? theme.red : theme.foreground
                }
              }
            }

            // takes the typing; the bullets above stand in for its text
            TextInput {
              id: entry
              anchors.fill: parent
              echoMode: TextInput.Password
              color: "transparent"
              selectionColor: "transparent"
              selectedTextColor: "transparent"
              cursorDelegate: Item {}
              enabled: !root.busy
              focus: true
              onTextChanged: root.failed = false
              onEnabledChanged: if (enabled) forceActiveFocus()
              onAccepted: root.submit()
              Component.onCompleted: forceActiveFocus()
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.notice
          color: root.failed ? theme.red : theme.foreground
          font.pixelSize: 15
          visible: root.notice !== "" && !root.picking
        }

        // Only offered when there is someone else to switch to (and to go back from the list)
        Text {
          visible: root.users.length > 1 || root.picking
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.picking ? "Back" : "Switch user"
          color: switchMouse.containsMouse ? theme.accent : Qt.alpha(theme.foreground, 0.7)
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 15
          font.underline: switchMouse.containsMouse

          MouseArea {
            id: switchMouse
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.picking = !root.picking
              if (!root.picking) entry.forceActiveFocus()
            }
          }
        }
      }
    }
  }
}
