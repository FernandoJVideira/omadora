import QtQuick

// Settings > Menu Bar: Control Center, what the bar shows and where, and how it looks.
SettingsPage {
  id: root

  readonly property var sys: backend?.sysState ?? ({})
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
  // Items in no section: hidden from the bar
  readonly property var hidden: Skein.barItems.filter(item => Skein.sectionOf(item.id) === "")

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

  // One list per side of the bar: move items along it, to another side, or hide them
  Repeater {
    model: root.sections

    SettingsSection {
      id: sectionBox

      required property var modelData

      title: `${modelData.label} side of the bar`

      SettingsRow {
        visible: Skein.barLayout[sectionBox.modelData.key].length === 0
        label: "Empty"
        description: "Add items from the list at the bottom"
      }

      Repeater {
        model: Skein.barLayout[sectionBox.modelData.key]

        SettingsRow {
          id: itemRow

          required property string modelData
          required property int index

          readonly property var info: root.item(modelData)

          label: info?.label ?? modelData
          description: info ? root.note(info) : ""
          dimmed: info ? !root.applies(info) : false

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
        Skein.barLayout = Skein.defaultBarLayout;
        Skein.clockStyle = "day";
        Skein.clock24h = true;
        Skein.clockSeconds = false;
      }
    }
  }
}
