import QtQuick

// A small picture of the menu bar for a set of settings (a preset), drawn with the current theme.
Item {
  id: root

  // {controlCenter, barLayout, barStyle, barFloating, barBorder, barOpacity, barDensity, barSize, clockStyle, clock24h, ...}
  property var settings: ({})

  readonly property bool pills: settings.barStyle === "pills"
  readonly property bool floating: settings.barFloating === true
  readonly property real density: settings.barDensity === "compact" ? 0.75 : (settings.barDensity === "comfortable" ? 1.3 : 1)
  readonly property int barHeight: Math.round(14 + ((settings.barSize ?? 26) - 20) * 0.5)
  readonly property int inset: floating ? 4 : 0
  readonly property real opacityValue: settings.barOpacity ?? 1
  readonly property font mockFont: Qt.font({
    family: Skein.fontFamily,
    pointSize: Math.max(6, Skein.fontSize - 4)
  })

  width: parent ? parent.width : 0
  height: 54

  // What each item looks like, in a few characters
  function mock(id: string): string {
    switch (id) {
    case "menu":
      return "◆";
    case "workspaces":
      return "● ○ ○";
    case "clock":
      {
        const time = settings.clock24h === false ? "2:05 PM" : "14:05";
        const style = settings.clockStyle ?? "day";
        return style === "time" ? time : (style === "date" ? `Tue 14 Oct ${time}` : `Tuesday ${time}`);
      }
    case "weather":
      return "☀ 18°";
    case "tray":
      return "▪▪";
    case "agents":
      return "✦";
    case "notifications":
      return "◉";
    case "controlcenter":
      return "▤";
    case "bluetooth":
      return "ᛒ";
    case "network":
      return "≋";
    case "audio":
      return "♪";
    case "display":
      return "▭";
    case "cpu":
      return "42%";
    case "battery":
      return "86%";
    case "update":
      return "↻";
    default:
      return "";
    }
  }

  // Items that only exist in one of the two layouts are not drawn in the other
  function shown(id: string): bool {
    const item = Skein.barItems.find(i => i.id === id);
    if (!item) {
      return false;
    }
    if (id === "notifications" && settings.notificationCenter === false) {
      return false;
    }
    return item.only === "" || (item.only === "controlcenter") === (settings.controlCenter === true);
  }

  // The "desktop" behind the bar
  Rectangle {
    anchors.fill: parent
    radius: 8
    color: Qt.alpha(Skein.accent, 0.18)
    clip: true

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 6
      width: parent.width * 0.5
      height: 14
      radius: 4
      color: Qt.alpha(Skein.foreground, 0.08)
    }
  }

  Item {
    id: bar

    x: root.inset
    y: root.inset
    width: parent.width - 2 * root.inset
    height: root.barHeight

    // A bar flush with the preview follows its rounded corners at the top; the clip squares off the bottom
    Item {
      visible: !root.pills
      anchors.fill: parent
      clip: true

      Rectangle {
        width: parent.width
        height: root.floating ? parent.height : parent.height + 8
        radius: root.floating ? 6 : 8
        color: Qt.alpha(Skein.background, root.opacityValue)
        border.width: root.settings.barBorder ? 1 : 0
        border.color: Qt.alpha(Skein.accent, 0.5)
      }

      Rectangle {
        visible: root.settings.barBorder === true && !root.floating
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Qt.alpha(Skein.accent, 0.5)
      }
    }

    component Side: Item {
      id: side

      property string key: "left"
      readonly property var ids: (root.settings.barLayout?.[key] ?? []).filter(id => root.shown(id))

      height: bar.height
      width: sideRow.width + 12
      visible: ids.length > 0

      Rectangle {
        visible: root.pills
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        radius: height / 2
        color: Qt.alpha(Skein.background, root.opacityValue)
        border.width: root.settings.barBorder ? 1 : 0
        border.color: Qt.alpha(Skein.accent, 0.5)
      }

      Row {
        id: sideRow

        x: 6
        height: parent.height
        spacing: Math.round(6 * root.density)

        Repeater {
          model: side.ids

          Text {
            required property string modelData

            anchors.verticalCenter: parent.verticalCenter
            text: root.mock(modelData)
            font: root.mockFont
            color: modelData === "controlcenter" || modelData === "menu" ? Skein.accent : Skein.foreground
          }
        }
      }
    }

    Side {
      key: "left"
      x: 2
    }

    Side {
      key: "center"
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Side {
      key: "right"
      anchors.right: parent.right
      anchors.rightMargin: 2
    }
  }
}
