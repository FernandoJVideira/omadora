import QtQuick
import Quickshell
import Quickshell.Io

// Settings > Wallpaper, laid out like macOS: your displays on top, the current picture with its
// fill mode, then grids of the theme's wallpapers and your own from ~/Pictures/Wallpapers/<theme>.
SettingsPage {
  id: root

  readonly property string scripts: `${Skein.skeinPath}/libexec`
  readonly property string mine: `${Quickshell.env("HOME")}/Pictures/Wallpapers/`
  property var all: []
  property string fit: "cover"
  property string themeName: ""
  readonly property var current: all.find(w => w.current) ?? null
  readonly property var themeWallpapers: all.filter(w => !w.key.startsWith(mine))
  readonly property var myWallpapers: all.filter(w => w.key.startsWith(mine))
  readonly property int columns: Math.max(2, Math.floor((width - 12 + 12) / 180))
  readonly property real tileWidth: (width - 12 - (columns - 1) * 12) / columns

  function reload(): void {
    if (!listProc.running) {
      listProc.running = true;
    }
  }

  function choose(wallpaper: var): void {
    root.all = root.all.map(w => Object.assign({}, w, {
        current: w.key === wallpaper.key
      }));
    Quickshell.execDetached([`${scripts}/skein-theme-bg-set`, wallpaper.key]);
  }

  function setFit(mode: string): void {
    fit = mode;
    Quickshell.execDetached([`${scripts}/skein-wallpaper-fit`, mode]);
  }

  Component.onCompleted: {
    reload();
    fitProc.running = true;
    themeProc.running = true;
  }

  Process {
    id: listProc

    command: [`${root.scripts}/skein-backgrounds-data`]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.all = JSON.parse(text.trim());
        } catch (e) {
          // keep the last list
        }
      }
    }
  }

  Process {
    id: fitProc

    command: [`${root.scripts}/skein-wallpaper-fit`]
    stdout: StdioCollector {
      onStreamFinished: root.fit = text.trim() || "cover"
    }
  }

  Process {
    id: themeProc

    command: [`${root.scripts}/skein-theme-current`]
    stdout: StdioCollector {
      onStreamFinished: root.themeName = text.trim()
    }
  }

  component Thumb: Rectangle {
    id: thumb

    required property var wallpaper

    width: root.tileWidth
    height: Math.round(width * 0.62)
    radius: 8
    color: Qt.alpha(Skein.foreground, 0.08)
    border.width: wallpaper.current ? 2 : 1
    border.color: wallpaper.current ? Skein.accent : Qt.alpha(Skein.foreground, 0.16)

    Image {
      anchors.fill: parent
      anchors.margins: 3
      source: `file://${thumb.wallpaper.preview}`
      sourceSize: Qt.size(400, 260)
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      smooth: true
    }

    Rectangle {
      visible: hover.containsMouse
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: 3
      height: 22
      color: Qt.alpha(Skein.background, 0.85)

      Text {
        anchors.fill: parent
        anchors.leftMargin: 6
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        text: thumb.wallpaper.label
        color: Skein.foreground
        font.family: Skein.fontFamily
        font.pointSize: Skein.fontSize - 1.5
      }
    }

    Rectangle {
      visible: thumb.wallpaper.current
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 8
      width: 18
      height: 18
      radius: 9
      color: Skein.accent

      Text {
        anchors.centerIn: parent
        text: "✓"
        color: Skein.background
        font.pointSize: Skein.fontSize - 2
        font.bold: true
      }
    }

    MouseArea {
      id: hover

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.choose(thumb.wallpaper)
    }
  }

  // Displays
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 28
    topPadding: 16
    bottomPadding: 4

    Repeater {
      model: Quickshell.screens

      Column {
        required property var modelData

        spacing: 6

        Rectangle {
          width: 150
          height: 92
          radius: 6
          color: "black"
          border.width: 3
          border.color: Qt.alpha(Skein.foreground, 0.25)

          Image {
            anchors.fill: parent
            anchors.margins: 3
            source: root.current ? `file://${root.current.preview}` : ""
            sourceSize: Qt.size(300, 190)
            fillMode: root.fit === "contain" ? Image.PreserveAspectFit : (root.fit === "fill" ? Image.Stretch : (root.fit === "tile" ? Image.Tile : Image.PreserveAspectCrop))
            asynchronous: true
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData.name
          color: Skein.foreground
          font.family: Skein.fontFamily
          font.pointSize: Skein.fontSize - 0.5
          font.bold: true
        }
      }
    }
  }

  SettingsSection {
    SettingsRow {
      label: root.current ? root.current.label : "No wallpaper"
      description: root.themeName ? `Theme: ${root.themeName}` : ""
    }

    ComboRow {
      label: "Fill"
      options: [
        {
          label: "Fill Screen",
          value: "cover"
        },
        {
          label: "Fit to Screen",
          value: "contain"
        },
        {
          label: "Stretch to Fill",
          value: "fill"
        },
        {
          label: "Tile",
          value: "tile"
        }
      ]
      current: root.fit
      onChosen: value => root.setFit(value)
    }
  }

  // Theme wallpapers
  Column {
    visible: root.themeWallpapers.length > 0
    width: parent.width
    spacing: 8

    Text {
      leftPadding: 4
      text: `${root.themeName.charAt(0).toUpperCase()}${root.themeName.slice(1)} wallpapers`
      color: Qt.alpha(Skein.foreground, 0.55)
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 0.5
      font.weight: Font.Medium
    }

    Flow {
      width: parent.width - 12
      spacing: 12

      Repeater {
        model: root.themeWallpapers

        Thumb {
          required property var modelData

          wallpaper: modelData
        }
      }
    }
  }

  // Your own, one folder per theme
  Column {
    width: parent.width
    spacing: 8

    Text {
      leftPadding: 4
      text: "My wallpapers"
      color: Qt.alpha(Skein.foreground, 0.55)
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 0.5
      font.weight: Font.Medium
    }

    Text {
      visible: root.myWallpapers.length === 0
      leftPadding: 4
      width: parent.width - 12
      wrapMode: Text.WordWrap
      text: `Nothing here yet. Add pictures and they are copied to ~/Pictures/Wallpapers/${root.themeName}`
      color: Qt.alpha(Skein.foreground, 0.5)
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 1
    }

    Flow {
      width: parent.width - 12
      spacing: 12

      Repeater {
        model: root.myWallpapers

        Thumb {
          required property var modelData

          wallpaper: modelData
        }
      }
    }
  }

  Row {
    spacing: 8
    bottomPadding: 4

    Repeater {
      model: [
        {
          text: "Add Wallpapers…",
          add: true
        },
        {
          text: "Open Folder",
          add: false
        }
      ]

      Rectangle {
        required property var modelData

        width: label.implicitWidth + 28
        height: Math.round(28 * Skein.textScale)
        radius: 6
        color: btn.containsMouse ? Qt.alpha(Skein.accent, 0.25) : Qt.alpha(Skein.foreground, 0.06)
        border.width: 1
        border.color: Qt.alpha(Skein.accent, 0.6)

        Text {
          id: label

          anchors.centerIn: parent
          text: modelData.text
          color: Skein.foreground
          font.family: Skein.fontFamily
          font.pointSize: Skein.fontSize - 0.5
        }

        MouseArea {
          id: btn

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: modelData.add ? root.backend.external([`${root.scripts}/skein-theme-bg-add`], true) : root.backend.external([`${root.scripts}/skein-theme-bg-add`, "--folder"], false)
        }
      }
    }
  }
}
