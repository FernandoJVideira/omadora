import QtQuick

// Settings > Menu Bar: Control Center, what the bar shows and where, and how it looks.
SettingsPage {
  id: root

  readonly property var sys: backend?.sysState ?? ({})

  // No scrolling by hand while a row is being dragged
  interactive: dragId === ""
  readonly property var sections: [
    {
      key: "left",
      label: "Left"
    },
    {
      key: "center",
      label: "Center"
    },
    {
      key: "right",
      label: "Right"
    }
  ]

  // Ready-made menu bars: a whole look and arrangement in one click
  readonly property var presets: [
    {
      name: "Classic",
      description: "The original Skein bar: a row of icons on the right, a clock in the middle",
      settings: {
        controlCenter: false,
        notificationCenter: true,
        showModes: true,
        barSize: 26,
        barOpacity: 1,
        barFloating: false,
        barBorder: false,
        barStyle: "classic",
        barDensity: "default",
        clockStyle: "day",
        clock24h: true,
        clockSeconds: false,
        barLayout: Skein.defaultBarLayout
      }
    },
    {
      name: "Mac",
      description: "Menu on the left, Control Center, bell and a dated clock on the right, like macOS",
      settings: {
        controlCenter: true,
        notificationCenter: true,
        showModes: true,
        barSize: 24,
        barOpacity: 0.85,
        barFloating: false,
        barBorder: false,
        barStyle: "classic",
        barDensity: "default",
        clockStyle: "date",
        clock24h: false,
        clockSeconds: false,
        barLayout: {
          left: ["menu", "workspaces"],
          center: [],
          right: ["tray", "agents", "bluetooth", "network", "audio", "display", "cpu", "battery", "update", "controlcenter", "notifications", "clock"]
        }
      }
    },
    {
      name: "GNOME",
      description: "Workspaces on the left, the clock in the middle, one quick-settings button on the right",
      settings: {
        controlCenter: true,
        notificationCenter: false,
        showModes: true,
        barSize: 28,
        barOpacity: 1,
        barFloating: false,
        barBorder: false,
        barStyle: "classic",
        barDensity: "default",
        clockStyle: "date",
        clock24h: true,
        clockSeconds: false,
        barLayout: {
          left: ["workspaces"],
          center: ["clock"],
          right: ["tray", "agents", "bluetooth", "network", "audio", "display", "battery", "update", "controlcenter"]
        }
      }
    },
    {
      name: "Floating islands",
      description: "A gap around the bar and a separate rounded capsule for each side, as in popular Waybar setups",
      settings: {
        controlCenter: true,
        notificationCenter: true,
        showModes: true,
        barSize: 32,
        barOpacity: 0.9,
        barFloating: true,
        barBorder: false,
        barStyle: "pills",
        barDensity: "comfortable",
        clockStyle: "day",
        clock24h: true,
        clockSeconds: false,
        barLayout: {
          left: ["menu", "workspaces"],
          center: ["clock"],
          right: ["tray", "agents", "bluetooth", "network", "audio", "display", "battery", "update", "controlcenter", "notifications"]
        }
      }
    },
    {
      name: "Centered workspaces",
      description: "Workspaces in the middle of the bar, the clock and status on the right, like Polybar and i3bar setups",
      settings: {
        controlCenter: true,
        notificationCenter: true,
        showModes: true,
        barSize: 26,
        barOpacity: 1,
        barFloating: false,
        barBorder: true,
        barStyle: "classic",
        barDensity: "default",
        clockStyle: "time",
        clock24h: true,
        clockSeconds: false,
        barLayout: {
          left: ["menu", "weather"],
          center: ["workspaces"],
          right: ["tray", "agents", "bluetooth", "network", "audio", "display", "cpu", "battery", "update", "controlcenter", "notifications", "clock"]
        }
      }
    },
    {
      name: "Dashboard",
      description: "Everything at a glance: separate icons, processor, battery, weather and updates, kept tight",
      settings: {
        controlCenter: false,
        notificationCenter: true,
        showModes: true,
        barSize: 24,
        barOpacity: 1,
        barFloating: false,
        barBorder: false,
        barStyle: "classic",
        barDensity: "compact",
        clockStyle: "date",
        clock24h: true,
        clockSeconds: true,
        barLayout: {
          left: ["menu", "workspaces", "cpu"],
          center: ["clock", "weather"],
          right: ["tray", "agents", "bluetooth", "network", "audio", "display", "battery", "update"]
        }
      }
    },
    {
      name: "Minimal",
      description: "Only workspaces and the time, see-through and out of the way",
      settings: {
        controlCenter: true,
        notificationCenter: false,
        showModes: false,
        barSize: 22,
        barOpacity: 0.5,
        barFloating: false,
        barBorder: false,
        barStyle: "classic",
        barDensity: "compact",
        clockStyle: "time",
        clock24h: true,
        clockSeconds: false,
        barLayout: {
          left: ["workspaces"],
          center: [],
          right: ["clock"]
        }
      }
    }
  ]

  // What the bar has now, read by name so the bindings that call presetActive() see every change
  readonly property var currentBar: ({
      controlCenter: Skein.controlCenter,
      notificationCenter: Skein.notificationCenter,
      showModes: Skein.showModes,
      barSize: Skein.barSize,
      barOpacity: Skein.barOpacity,
      barFloating: Skein.barFloating,
      barBorder: Skein.barBorder,
      barStyle: Skein.barStyle,
      barDensity: Skein.barDensity,
      clockStyle: Skein.clockStyle,
      clock24h: Skein.clock24h,
      clockSeconds: Skein.clockSeconds,
      barLayout: Skein.normalizeLayout(Skein.barLayout)
    })

  // A preset is in use when every setting it holds is what the bar has now
  function presetActive(preset: var): bool {
    const now = currentBar;
    for (const key of Object.keys(preset.settings)) {
      const want = key === "barLayout" ? Skein.normalizeLayout(preset.settings[key]) : preset.settings[key];
      if (JSON.stringify(now[key]) !== JSON.stringify(want)) {
        return false;
      }
    }
    return true;
  }

  // Items in no section: hidden from the bar
  readonly property var hidden: Skein.barItems.filter(item => Skein.sectionOf(item.id) === "")

  // --- dragging rows of the side lists ---
  property string dragId: ""
  property real dragY: 0 // pointer, in scene coordinates
  property var dropTarget: null // {section, before, lineY}
  property real scrollSpeed: 0

  function boxes(): var {
    const result = [];
    for (let i = 0; i < sectionRepeater.count; i++) {
      result.push(sectionRepeater.itemAt(i));
    }
    return result;
  }

  // Where the dragged row would land for a pointer at scene y
  function computeTarget(y: real): var {
    const all = boxes();
    let best = all[0];
    let bestDistance = Infinity;
    for (const box of all) {
      const top = box.mapToItem(null, 0, 0).y;
      const distance = y < top ? top - y : (y > top + box.height ? y - top - box.height : 0);
      if (distance < bestDistance) {
        best = box;
        bestDistance = distance;
      }
    }
    const key = best.modelData.key;
    const ids = Skein.barLayout[key].filter(id => id !== dragId);
    let before = "";
    let lineScene = 0;
    const cells = best.rowItems;
    for (let i = 0; i < cells.count; i++) {
      const cell = cells.itemAt(i);
      if (!cell || cell.modelData === dragId) {
        continue;
      }
      const top = cell.mapToItem(null, 0, 0).y;
      if (y < top + cell.height / 2) {
        before = cell.modelData;
        lineScene = top;
        break;
      }
      lineScene = top + cell.height;
    }
    if (ids.length === 0) {
      lineScene = best.mapToItem(null, 0, 0).y + 40;
    }
    const line = contentItem.mapFromItem(null, 0, lineScene);
    return {
      section: key,
      before: before,
      lineY: line.y,
      boxX: contentItem.mapFromItem(null, best.mapToItem(null, 0, 0).x, 0).x,
      boxWidth: best.width
    };
  }

  function dragMoved(y: real): void {
    dragY = y;
    dropTarget = computeTarget(y);
    const top = root.mapToItem(null, 0, 0).y;
    scrollSpeed = y < top + 50 ? -8 : (y > top + height - 50 ? 8 : 0);
  }

  function dragDropped(): void {
    const id = dragId;
    const target = dropTarget;
    dragId = "";
    dropTarget = null;
    scrollSpeed = 0;
    if (id === "" || !target) {
      return;
    }
    const layout = Skein.normalizeLayout(Skein.barLayout);
    for (const s of ["left", "center", "right"]) {
      layout[s] = layout[s].filter(i => i !== id);
    }
    const list = layout[target.section];
    const at = target.before === "" ? list.length : list.indexOf(target.before);
    list.splice(at < 0 ? list.length : at, 0, id);
    Skein.saveLayout(layout);
  }

  Timer {
    interval: 16
    repeat: true
    running: root.scrollSpeed !== 0
    onTriggered: root.contentY = Math.max(0, Math.min(root.contentHeight - root.height, root.contentY + root.scrollSpeed))
  }

  // The row being dragged, following the pointer
  Rectangle {
    visible: root.dragId !== ""
    z: 100
    width: Math.min(root.width - 24, 360)
    height: Math.round(36 * Skein.textScale)
    x: 12
    y: root.contentItem.mapFromItem(null, 0, root.dragY).y - height / 2
    radius: Skein.radiusInner
    color: Qt.alpha(Skein.accent, 0.85)

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      text: root.item(root.dragId)?.label ?? ""
      color: Skein.background
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize
      font.bold: true
    }
  }

  // Where it will land
  Rectangle {
    visible: root.dragId !== "" && root.dropTarget !== null
    z: 99
    x: (root.dropTarget?.boxX ?? 0) + 6
    y: (root.dropTarget?.lineY ?? 0) - 1
    width: (root.dropTarget?.boxWidth ?? 0) - 12
    height: 3
    radius: 1.5
    color: Skein.accent
  }

  function item(id: string): var {
    return Skein.barItems.find(i => i.id === id);
  }

  // Items that only exist in one of the two layouts are dimmed in the other
  function applies(item: var): bool {
    return item.only === "" || (item.only === "controlcenter") === Skein.controlCenter;
  }

  function note(item: var): string {
    if (applies(item)) {
      return "";
    }
    return item.only === "controlcenter" ? "Only with the Control Center" : "Only in the classic layout";
  }

  SettingsSection {
    title: "Presets"

    Repeater {
      model: root.presets

      Item {
        id: presetRow

        required property var modelData
        readonly property bool active: root.presetActive(modelData)

        width: parent.width
        height: presetText.implicitHeight + preview.height + 34

        Column {
          id: presetText

          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.right: applyButton.left
          anchors.rightMargin: 12
          anchors.top: parent.top
          anchors.topMargin: 12
          spacing: 2

          Text {
            width: parent.width
            text: presetRow.modelData.name
            color: Skein.foreground
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize
          }

          Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: presetRow.modelData.description
            color: Qt.alpha(Skein.foreground, 0.6)
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize - 1.5
          }
        }

        SmallButton {
          id: applyButton

          anchors.right: parent.right
          anchors.rightMargin: 14
          anchors.top: parent.top
          anchors.topMargin: 12
          text: presetRow.active ? "In use" : "Use"
          highlighted: presetRow.active
          enabled: !presetRow.active
          onClicked: Skein.applyBar(presetRow.modelData.settings)
        }

        BarPreview {
          id: preview

          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.right: parent.right
          anchors.rightMargin: 14
          anchors.top: presetText.bottom
          anchors.topMargin: 10
          width: parent.width - 28
          settings: presetRow.modelData.settings
        }

        Rectangle {
          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: 1
          color: Qt.alpha(Skein.foreground, 0.08)
        }
      }
    }
  }

  SettingsSection {
    title: "Control Center"

    SwitchRow {
      label: "Unified Control Center"
      description: "One button for network, Bluetooth, sound, display and quick switches, like macOS. Turn it off to get the classic row of icons back, exactly as before."
      checked: Skein.controlCenter
      onToggled: value => Skein.setBar("controlCenter", value)
    }

    SwitchRow {
      label: "Notification center"
      description: "A bell next to the Control Center with every open notification, do not disturb and clear all"
      checked: Skein.notificationCenter
      enabled: Skein.controlCenter
      onToggled: value => Skein.setBar("notificationCenter", value)
    }
  }

  SettingsSection {
    title: "Look"

    SliderRow {
      label: "Height"
      valueText: `${Skein.barSize} px`
      value: (Skein.barSize - 20) / 28
      onMoved: v => Skein.setBar("barSize", Math.round(20 + v * 28))
    }

    SliderRow {
      label: "Transparency"
      valueText: `${Math.round((1 - Skein.barOpacity) * 100)}%`
      value: (1 - Skein.barOpacity) / 0.7
      onMoved: v => Skein.setBar("barOpacity", Math.round((1 - v * 0.7) * 100) / 100)
    }

    SwitchRow {
      label: "Floating bar"
      description: "Rounded, with a gap around it"
      checked: Skein.barFloating
      onToggled: value => Skein.setBar("barFloating", value)
    }

    SwitchRow {
      label: "Outline"
      description: "A thin accent line around the bar"
      checked: Skein.barBorder
      onToggled: value => Skein.setBar("barBorder", value)
    }

    ComboRow {
      label: "Style"
      description: "Pills puts each side of the bar in its own rounded capsule"
      options: [
        {
          label: "Classic",
          value: "classic"
        },
        {
          label: "Pills",
          value: "pills"
        }
      ]
      current: Skein.barStyle
      onChosen: value => Skein.setBar("barStyle", value)
    }

    ComboRow {
      label: "Spacing"
      options: [
        {
          label: "Compact",
          value: "compact"
        },
        {
          label: "Default",
          value: "default"
        },
        {
          label: "Comfortable",
          value: "comfortable"
        }
      ]
      current: Skein.barDensity
      onChosen: value => Skein.setBar("barDensity", value)
    }

    SwitchRow {
      label: "Mode indicators"
      description: "Recording, night light, reminders and do not disturb, left of the clock"
      checked: Skein.showModes
      onToggled: value => Skein.setBar("showModes", value)
    }
  }

  SettingsSection {
    title: "Clock"

    ComboRow {
      label: "Format"
      options: [
        {
          label: "Weekday and time",
          value: "day"
        },
        {
          label: "Date and time",
          value: "date"
        },
        {
          label: "Time only",
          value: "time"
        }
      ]
      current: Skein.clockStyle
      onChosen: value => Skein.setBar("clockStyle", value)
    }

    SwitchRow {
      label: "24-hour time"
      checked: Skein.clock24h
      onToggled: value => Skein.setBar("clock24h", value)
    }

    SwitchRow {
      label: "Show seconds"
      checked: Skein.clockSeconds
      onToggled: value => Skein.setBar("clockSeconds", value)
    }
  }

  SettingsSection {
    title: "Rearrange"

    ButtonRow {
      label: "Rearrange items on the bar"
      description: "Drag items to another place or side; click Done on the bar when finished"
      buttonText: "Start"
      onClicked: {
        root.backend.close();
        Skein.barEditing = true;
      }
    }
  }

  // One list per side of the bar: move items along it, to another side, or hide them
  Repeater {
    id: sectionRepeater

    model: root.sections

    SettingsSection {
      id: sectionBox

      required property var modelData
      property alias rowItems: rowRepeater

      title: `${modelData.label} side of the bar`

      SettingsRow {
        visible: Skein.barLayout[sectionBox.modelData.key].length === 0
        label: "Empty"
        description: "Add items from the list at the bottom"
      }

      Repeater {
        id: rowRepeater

        model: Skein.barLayout[sectionBox.modelData.key]

        SettingsRow {
          id: itemRow

          required property string modelData
          required property int index

          readonly property var info: root.item(modelData)

          label: info?.label ?? modelData
          description: info ? root.note(info) : ""
          dimmed: info ? !root.applies(info) : false
          opacity: root.dragId === modelData ? 0.35 : 1

          leading: Text {
            text: "⠿"
            color: Qt.alpha(Skein.foreground, handle.containsMouse || root.dragId === itemRow.modelData ? 0.9 : 0.45)
            font.pointSize: Skein.fontSize + 3

            MouseArea {
              id: handle

              anchors.fill: parent
              anchors.margins: -6
              hoverEnabled: true
              // The page scrolls vertically too: keep the drag from being taken over by it
              preventStealing: true
              cursorShape: Qt.SizeVerCursor
              onPressed: mouse => {
                root.dragId = itemRow.modelData;
                root.dragMoved(mapToItem(null, mouse.x, mouse.y).y);
              }
              onPositionChanged: mouse => root.dragMoved(mapToItem(null, mouse.x, mouse.y).y)
              onReleased: root.dragDropped()
              onCanceled: root.dragDropped()
            }
          }

          Row {
            spacing: 6

            SmallButton {
              text: "◀"
              enabled: itemRow.index > 0
              onClicked: Skein.moveBarItem(itemRow.modelData, -1)
            }

            SmallButton {
              text: "▶"
              enabled: itemRow.index < Skein.barLayout[sectionBox.modelData.key].length - 1
              onClicked: Skein.moveBarItem(itemRow.modelData, 1)
            }

            Repeater {
              model: root.sections

              SmallButton {
                required property var modelData

                text: modelData.label.charAt(0)
                highlighted: modelData.key === sectionBox.modelData.key
                onClicked: Skein.placeBarItem(itemRow.modelData, modelData.key)
              }
            }

            SmallButton {
              text: "Hide"
              onClicked: Skein.placeBarItem(itemRow.modelData, "")
            }
          }
        }
      }
    }
  }

  SettingsSection {
    title: "Hidden items"
    visible: root.hidden.length > 0

    Repeater {
      model: root.hidden

      SettingsRow {
        id: hiddenRow

        required property var modelData

        label: modelData.label
        description: root.note(modelData)
        dimmed: !root.applies(modelData)

        Row {
          spacing: 6

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Add to"
            color: Qt.alpha(Skein.foreground, 0.6)
            font.family: Skein.fontFamily
            font.pointSize: Skein.fontSize - 1
          }

          Repeater {
            model: root.sections

            SmallButton {
              required property var modelData

              text: modelData.label
              onClicked: Skein.placeBarItem(hiddenRow.modelData.id, modelData.key)
            }
          }
        }
      }
    }
  }

  SettingsSection {
    title: "Weather"

    SwitchRow {
      label: "Fetch the weather"
      description: "Needed by the weather item; turning it off also stops the background check"
      checked: root.sys.weather ?? true
      onToggled: value => root.backend.set("weather", value, "skein-toggle-weather-check")
    }
  }

  SettingsSection {
    title: "Custom items"

    Repeater {
      model: Skein.customItems

      ButtonRow {
        required property var modelData

        label: `${modelData.icon ?? ""} ${modelData.label || modelData.id}`
        description: modelData.script ? `Runs ${modelData.script}` : (modelData.onClick ? `Click runs ${modelData.onClick}` : "")
        buttonText: "Remove"
        onClicked: Skein.customItemCommand(["remove", modelData.id])
      }
    }

    TextInputRow {
      id: customName

      label: "Name"
      description: "Add your own item to the bar; it appears at the end of the right side, move it in the lists above"
      placeholder: "VPN"
    }

    TextInputRow {
      id: customIcon

      label: "Icon"
      description: "A glyph or a few characters"
      placeholder: "󰖂"
    }

    TextInputRow {
      id: customScript

      label: "Status command"
      description: "Optional. Its output is shown next to the icon (plain text or Waybar-style JSON)"
      placeholder: "~/bin/vpn-status"
    }

    TextInputRow {
      id: customInterval

      label: "Refresh every (seconds)"
      description: "How often the status command runs; empty runs it once"
      placeholder: "10"
    }

    TextInputRow {
      id: customClick

      label: "On click"
      description: "Optional command run when the item is clicked"
      placeholder: "nm-connection-editor"
    }

    ButtonRow {
      label: "Add the item"
      description: "Needs a name and an icon or a status command"
      buttonText: "Add"
      enabled: customName.text.trim() !== "" && (customIcon.text.trim() !== "" || customScript.text.trim() !== "")
      onClicked: {
        const label = customName.text.trim();
        const id = label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "item";
        const interval = parseInt(customInterval.text);
        Skein.customItemCommand(["add", JSON.stringify({
            id: id,
            label: label,
            icon: customIcon.text.trim(),
            script: customScript.text.trim(),
            interval: interval > 0 ? interval : undefined,
            onClick: customClick.text.trim()
          })]);
        Skein.placeBarItem(`custom-${id}`, "right");
        customName.text = "";
        customIcon.text = "";
        customScript.text = "";
        customInterval.text = "";
        customClick.text = "";
      }
    }

    ButtonRow {
      label: "Edit by hand"
      description: "~/.config/skein/bar-items.json: id, label, icon, text, script, interval, tooltip, onClick, onRightClick"
      buttonText: "Open"
      onClicked: Skein.run("xdg-open \"$HOME/.config/skein/bar-items.json\"")
    }

    ButtonRow {
      label: "Main menu entries"
      description: "~/.config/skein/menu-items: one \"Label, tab, command\" per line adds a Custom submenu to the Skein menu"
      buttonText: "Open"
      onClicked: Skein.run("xdg-open \"$HOME/.config/skein/menu-items\"")
    }
  }

  SettingsSection {
    title: "Reset"

    ButtonRow {
      label: "Restore the classic menu bar"
      description: "Control Center off, the original items and order, the original look"
      buttonText: "Reset"
      onClicked: {
        root.backend.run("skein-menubar", ["reset"]);
        Skein.controlCenter = false;
        Skein.notificationCenter = true;
        Skein.showModes = true;
        Skein.barSize = 26;
        Skein.barOpacity = 1;
        Skein.barFloating = false;
        Skein.barBorder = false;
        Skein.barDensity = "default";
        Skein.barStyle = "classic";
        Skein.barLayout = Skein.defaultBarLayout;
        Skein.clockStyle = "day";
        Skein.clock24h = true;
        Skein.clockSeconds = false;
      }
    }
  }
}
