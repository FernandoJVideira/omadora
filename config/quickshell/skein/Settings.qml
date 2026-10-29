import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// Settings window in the Skein Search style: a pill search field, your account and the pages in
// groups (text only, the selected one filled with the accent), and the page on the right.
// A transparent full-screen layer catches clicks outside the window, and Escape closes it.
//   qs -c skein ipc call settings toggle|open|close|page <name>
Scope {
  id: root

  property bool active: false
  property bool barVisible: true
  property string page: "appearance"
  property string query: ""

  readonly property var pages: [
    {
      key: "appearance",
      label: "Appearance",
      group: "Personalization",
      glyph: Skein.glyph(0xf1fc),
      tint: "#5e8bff",
      keywords: "theme wallpaper background text size font colors"
    },
    {
      key: "wallpaper",
      label: "Wallpaper",
      group: "Personalization",
      glyph: Skein.glyph(0xf03e),
      tint: "#2dd4bf",
      keywords: "background picture image folder fill fit"
    },
    {
      key: "display",
      label: "Display",
      group: "Hardware",
      glyph: Skein.glyph(0xf0379),
      tint: "#32a5f0",
      keywords: "brightness scale resolution monitor nightlight"
    },
    {
      key: "audio",
      label: "Audio",
      group: "Hardware",
      glyph: Skein.glyph(0xf028),
      tint: "#f0524f",
      keywords: "sound volume output input microphone speaker mute"
    },
    {
      key: "input",
      label: "Input",
      group: "Hardware",
      glyph: Skein.glyph(0xf11c),
      tint: "#8e8e93",
      keywords: "keyboard layout touchpad mouse"
    },
    {
      key: "power",
      label: "Power & Idle",
      group: "Hardware",
      glyph: Skein.glyph(0xf0e7),
      tint: "#34c759",
      keywords: "battery profile lock screensaver sleep idle"
    },
    {
      key: "network",
      label: "Network",
      group: "Connectivity",
      glyph: Skein.glyph(0xf1eb),
      tint: "#2f8cf5",
      keywords: "wifi internet ethernet"
    },
    {
      key: "bluetooth",
      label: "Bluetooth",
      group: "Connectivity",
      glyph: Skein.glyph(0xf00af),
      tint: "#3478f6",
      keywords: "devices pair headphones"
    },
    {
      key: "menubar",
      label: "Menu Bar",
      group: "Desktop",
      glyph: Skein.glyph(0xf035c),
      tint: "#5e5ce6",
      keywords: "top bar control center notification center clock tray cpu battery indicators weather"
    },
    {
      key: "windows",
      label: "Windows",
      group: "Desktop",
      glyph: Skein.glyph(0xf2d0),
      tint: "#ff9f0a",
      keywords: "tiling layout gaps bar notifications"
    },
    {
      key: "dock",
      label: "Dock",
      group: "Desktop",
      glyph: Skein.glyph(0xf0e4),
      tint: "#30b0c7",
      keywords: "apps launcher pinned magnification auto hide taskbar running"
    },
    {
      key: "agents",
      label: "Agents",
      group: "Desktop",
      glyph: Skein.glyph(0xf06a9),
      tint: "#ff7a59",
      keywords: "claude codex opencode ai limits usage tokens default agent"
    },
    {
      key: "defaults",
      label: "Defaults",
      group: "Desktop",
      glyph: Skein.glyph(0xf02e),
      tint: "#bf5af2",
      keywords: "browser terminal editor agent default apps"
    },
    {
      key: "system",
      label: "System",
      group: "System",
      glyph: Skein.glyph(0xf013),
      tint: "#8e8e93",
      keywords: "updates weather crash logout reboot shutdown"
    },
    {
      key: "users",
      label: "Users",
      group: "System",
      glyph: Skein.glyph(0xf0c0),
      tint: "#5ac8fa",
      keywords: "accounts avatar password administrator"
    },
    {
      key: "about",
      label: "About",
      group: "System",
      glyph: Skein.glyph(0xf05a),
      tint: "#64748b",
      keywords: "computer os version hardware logo"
    }
  ]

  readonly property var visiblePages: {
    const q = query.trim().toLowerCase();
    return q === "" ? pages : pages.filter(p => p.label.toLowerCase().includes(q) || p.keywords.includes(q));
  }
  readonly property string pageTitle: pages.find(p => p.key === page)?.label ?? ""

  // Switch and default states from skein-settings-state, re-read after every change
  property var sysState: ({})
  // The signed-in account, for the sidebar card
  property var me: ({
      name: "",
      fullName: "",
      admin: false
    })
  property int avatarRevision: 0
  readonly property string avatarPath: `${Quickshell.env("HOME")}/.face`

  function refresh(): void {
    avatarRevision++;
    if (!stateProc.running) {
      stateProc.running = true;
    }
    if (!meProc.running) {
      meProc.running = true;
    }
  }

  function reloadAvatar(): void {
    avatarRevision++;
  }

  function refreshState(): void {
    if (!stateProc.running) {
      stateProc.running = true;
    }
  }

  // Run a skein command and re-read the state as soon as it has finished
  function run(script: string, args: var): void {
    const process = runner.createObject(root, {
      command: [`${Skein.skeinPath}/libexec/${script}`, ...(args ?? [])]
    });
    process.running = true;
  }

  // Show a new switch or choice at once, then run the command that makes it so.
  // The state read after the command ends puts things right if it failed.
  function set(key: string, value: var, script: string, args: var): void {
    const next = Object.assign({}, sysState);
    next[key] = value;
    sysState = next;
    run(script, args);
  }

  signal setBarVisible(bool visible)

  Component {
    id: runner

    Process {
      onExited: {
        root.refreshState();
        destroy();
      }
    }
  }

  // The window floats above every other window, so anything that opens a window of its own
  // (a file chooser, a file manager, a terminal) closes it first. With reopen the window comes
  // back on the same page once the command ends, for choosers that block until you are done.
  property bool reopenAfter: false
  property string reopenPage: ""

  function external(command: var, reopen: bool): void {
    reopenPage = page;
    reopenAfter = reopen;
    close();
    if (reopen) {
      externalProc.command = command;
      externalProc.running = true;
    } else {
      Quickshell.execDetached(command);
    }
  }

  Process {
    id: externalProc

    onExited: if (root.reopenAfter) {
      root.reopenAfter = false;
      root.open(root.reopenPage);
    }
  }

  function open(name: string): void {
    if (name) {
      page = name;
    }
    query = "";
    active = true;
  }

  function close(): void {
    active = false;
  }

  onActiveChanged: if (active) {
    refresh();
  }

  Process {
    id: stateProc

    command: [`${Skein.skeinPath}/libexec/skein-settings-state`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.sysState = JSON.parse(text.trim());
        } catch (e) {
          // keep the last state
        }
      }
    }
  }

  Process {
    id: meProc

    command: [`${Skein.skeinPath}/libexec/skein-users-list`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.me = JSON.parse(text.trim()).find(u => u.current) ?? root.me;
        } catch (e) {
          // keep the last account
        }
      }
    }
  }

  IpcHandler {
    target: "settings"

    function toggle(): void {
      root.active ? root.close() : root.open("");
    }

    function open(): void {
      root.open("");
    }

    function close(): void {
      root.close();
    }

    // Open on a page: appearance, wallpaper, display, audio, input, power, network, bluetooth, menubar, windows, dock, agents, defaults, system, users or about
    function page(name: string): void {
      root.open(name);
    }
  }

  PanelWindow {
    // Follow the focused monitor, like the bar panels
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: root.active
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    color: Qt.alpha("black", 0.35)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "skein-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onClicked: root.close()
    }

    Rectangle {
      id: window

      anchors.centerIn: parent
      width: Math.min(Math.round(900 * Skein.textScale), parent.width - 40)
      height: Math.min(Math.round(780 * Skein.textScale), parent.height - 40)
      radius: Skein.glass ? 26 : 16
      color: Qt.alpha(Skein.background, Skein.glass ? 0.74 : 0.98)
      focus: true


      Keys.onEscapePressed: dropdown.owner ? dropdown.close() : root.close()

      MouseArea {
        anchors.fill: parent
      }

      // Fade and grow in when the window opens
      transform: Scale {
        id: grow

        origin.x: window.width / 2
        origin.y: window.height / 2
      }

      ParallelAnimation {
        id: openAnimation

        NumberAnimation {
          target: window
          property: "opacity"
          from: 0
          to: 1
          duration: 150
          easing.type: Easing.OutCubic
        }

        NumberAnimation {
          target: grow
          properties: "xScale,yScale"
          from: 0.97
          to: 1
          duration: 180
          easing.type: Easing.OutCubic
        }
      }

      Connections {
        target: root

        function onActiveChanged(): void {
          if (root.active) {
            openAnimation.restart();
          }
        }
      }

      // Sidebar: rounded on the window's left corners, square against the page
      Rectangle {
        id: sidebar

        readonly property color fill: Qt.tint(Skein.background, Qt.alpha(Skein.foreground, 0.05))

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: Math.round(230 * Skein.textScale)
        radius: window.radius
        color: fill

        Rectangle {
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          width: window.radius
          color: sidebar.fill
        }

        Rectangle {
          id: search

          anchors.top: parent.top
          anchors.topMargin: 18
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          height: Math.round(36 * Skein.textScale)
          radius: Skein.glass ? 10 : height / 2
          color: Qt.alpha(Skein.foreground, 0.06)
          border.width: 1
          border.color: searchInput.activeFocus ? Qt.alpha(Skein.foreground, 0.32) : Qt.alpha(Skein.foreground, 0.16)

          Text {
            id: lens

            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf002"
            color: Qt.alpha(Skein.foreground, 0.5)
            font.family: "JetBrainsMono Nerd Font"
            font.pointSize: Skein.fontSize
          }

          TextInput {
            id: searchInput

            anchors.left: lens.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            color: Skein.foreground
            selectionColor: Skein.accent
            selectedTextColor: Skein.background
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize
            text: root.query
            onTextChanged: root.query = text
            onAccepted: if (root.visiblePages.length > 0) {
              root.page = root.visiblePages[0].key;
            }
            Keys.onEscapePressed: event => {
              if (text !== "") {
                text = "";
              } else {
                root.close();
              }
            }

            Text {
              visible: searchInput.text === ""
              anchors.verticalCenter: parent.verticalCenter
              text: "Search settings"
              color: Qt.alpha(Skein.foreground, 0.45)
              font: searchInput.font
            }
          }
        }

        // Your account
        Rectangle {
          id: account

          visible: root.query === ""
          anchors.top: search.bottom
          anchors.topMargin: 10
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          height: visible ? Math.round(56 * Skein.textScale) : 0
          radius: Skein.glass ? 12 : 11
          color: root.page === "users" ? Qt.alpha(Skein.accent, 0.9) : (accountMouse.containsMouse ? Qt.alpha(Skein.foreground, 0.07) : "transparent")

          Avatar {
            id: accountAvatar

            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(40 * Skein.textScale)
            height: width
            name: root.me.name
            source: root.avatarPath
            revision: root.avatarRevision
          }

          Column {
            anchors.left: accountAvatar.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
              width: parent.width
              elide: Text.ElideRight
              text: root.me.fullName || root.me.name
              color: root.page === "users" ? Skein.background : Skein.foreground
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize
              font.weight: Font.DemiBold
            }

            Text {
              width: parent.width
              elide: Text.ElideRight
              text: root.me.admin ? "Administrator" : "Standard"
              color: root.page === "users" ? Qt.alpha(Skein.background, 0.7) : Qt.alpha(Skein.foreground, 0.6)
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize - 2
            }
          }

          MouseArea {
            id: accountMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.page = "users"
          }
        }

        Flickable {
          anchors.top: account.visible ? account.bottom : search.bottom
          anchors.topMargin: 6
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          contentHeight: pageList.implicitHeight + 12
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          Column {
            id: pageList

            x: 12
            width: parent.width - 24

            Repeater {
              model: root.visiblePages

              Column {
                id: entry

                required property var modelData
                required property int index

                readonly property bool newGroup: root.query === "" && (index === 0 || root.visiblePages[index - 1].group !== modelData.group)

                width: pageList.width
                spacing: 5

                // Space between groups
                Item {
                  visible: entry.newGroup && entry.index !== 0
                  width: parent.width
                  height: visible ? 10 : 0
                }

                Rectangle {
                  width: parent.width
                  height: Math.round(34 * Skein.textScale)
                  radius: Skein.glass ? 12 : 9
                  color: root.page === entry.modelData.key ? Qt.alpha(Skein.accent, 0.9) : (rowMouse.containsMouse ? Qt.alpha(Skein.foreground, 0.07) : "transparent")

                  // Plain glyph in the same Nerd Font the launcher categories use, no badge behind it
                  Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: entry.modelData.glyph
                    color: root.page === entry.modelData.key ? Skein.background : Qt.alpha(Skein.foreground, 0.8)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pointSize: Skein.fontSize + 1
                  }

                  Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 48
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: entry.modelData.label
                    color: root.page === entry.modelData.key ? Skein.background : Skein.foreground
                    font.family: Skein.fontFamily
                    font.pointSize: Skein.fontSize
                  }

                  MouseArea {
                    id: rowMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.page = entry.modelData.key
                  }
                }
              }
            }

            Text {
              visible: root.visiblePages.length === 0
              topPadding: 8
              leftPadding: 8
              text: "No results"
              color: Qt.alpha(Skein.foreground, 0.5)
              font.family: Skein.fontFamily
              font.pointSize: Skein.fontSize
            }
          }
        }
      }

      Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: sidebar.right
        width: 1
        color: Qt.alpha(Skein.foreground, 0.1)
      }

      // Page title, then the page
      Text {
        id: title

        anchors.top: parent.top
        anchors.topMargin: 28
        anchors.left: sidebar.right
        anchors.leftMargin: 24
        text: root.pageTitle
        color: Skein.foreground
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize + 6
        font.weight: Font.DemiBold
      }

      // Dropdown list, drawn above the whole window so no card can clip or cover it
      Item {
        id: dropdown

        property var owner: null
        property var options: []
        property string current: ""
        property real anchorX: 0
        property real anchorY: 0
        property real anchorWidth: 0

        anchors.fill: parent
        visible: owner !== null
        z: 20

        function close(): void {
          if (owner) {
            owner.open = false;
          }
          owner = null;
        }

        Connections {
          target: Skein

          function onDropdownRequested(owner, anchor, options, current): void {
            if (dropdown.owner && dropdown.owner !== owner) {
              dropdown.owner.open = false;
            }
            const point = anchor.mapToItem(dropdown, 0, anchor.height + 4);
            dropdown.anchorX = point.x;
            dropdown.anchorY = point.y;
            dropdown.anchorWidth = anchor.width;
            dropdown.options = options;
            dropdown.current = current;
            dropdown.owner = owner;
          }
        }

        // A list left open is closed when the window closes or the page changes
        Connections {
          target: root

          function onActiveChanged(): void {
            dropdown.close();
          }

          function onPageChanged(): void {
            dropdown.close();
          }
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onClicked: dropdown.close()
        }

        Rectangle {
          width: Math.max(dropdown.anchorWidth, Math.round(170 * Skein.textScale))
          height: choices.implicitHeight + 10
          x: Math.min(dropdown.anchorX + dropdown.anchorWidth - width, dropdown.width - width - 10)
          y: Math.min(dropdown.anchorY, dropdown.height - height - 10)
          radius: 12
          color: Qt.alpha(Skein.background, Skein.glass ? 0.7 : 0.98)
          border.width: 1
          border.color: Qt.alpha(Skein.foreground, 0.16)


          Column {
            id: choices

            x: 5
            y: 5
            width: parent.width - 10

            Repeater {
              model: dropdown.options

              Rectangle {
                id: choice

                required property var modelData

                width: choices.width
                height: Math.round(34 * Skein.textScale)
                radius: 8
                color: choiceMouse.containsMouse ? Qt.alpha(Skein.accent, 0.9) : "transparent"

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  text: choice.modelData.label
                  color: choiceMouse.containsMouse ? Skein.background : (choice.modelData.value === dropdown.current ? Skein.accent : Skein.foreground)
                  font.family: Skein.fontFamily
                  font.pointSize: Skein.fontSize
                }

                Text {
                  visible: choice.modelData.value === dropdown.current
                  anchors.right: parent.right
                  anchors.rightMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  text: "✓"
                  color: choiceMouse.containsMouse ? Skein.background : Skein.accent
                  font.pointSize: Skein.fontSize - 1
                }

                MouseArea {
                  id: choiceMouse

                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    const owner = dropdown.owner;
                    const value = choice.modelData.value;
                    dropdown.close();
                    owner.chosen(value);
                  }
                }
              }
            }
          }
        }
      }

      Rectangle {
        anchors.fill: parent
        radius: window.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Skein.foreground, 0.16)
        z: 10
      }

      Loader {
        id: pageLoader

        anchors.top: title.bottom
        anchors.topMargin: 20
        anchors.bottom: parent.bottom
        anchors.left: sidebar.right
        anchors.right: parent.right
        anchors.leftMargin: 24
        anchors.rightMargin: 12
        anchors.bottomMargin: 16
        active: root.active
        source: root.pages.some(p => p.key === root.page) ? `${root.page.charAt(0).toUpperCase()}${root.page.slice(1)}Page.qml` : ""
        onLoaded: {
          item.backend = root;
          item.opacity = 0;
          pageFade.target = item;
          pageFade.restart();
        }

        NumberAnimation {
          id: pageFade

          property: "opacity"
          from: 0
          to: 1
          duration: 140
          easing.type: Easing.OutCubic
        }
      }
    }
  }
}
