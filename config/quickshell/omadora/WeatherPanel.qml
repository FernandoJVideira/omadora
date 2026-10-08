import QtQuick
import Quickshell
import Quickshell.Io

// Current conditions and the next three days, from the weather check's state file.
Panel {
  id: root

  property var weather: null
  property bool editing: false // searching for another city
  property var results: []
  property int selected: 0
  property string pendingPlace: "" // shown until the weather for a newly chosen city arrives

  readonly property string mono: "JetBrainsMono Nerd Font"
  readonly property string stateFile: `${Omadora.home}/.local/state/omadora/weather/state.json`
  readonly property int staleMinutes: weather ? Math.max(0, Math.round((Date.now() / 1000 - weather.timestamp) / 60)) : 0

  function parse(text: string): void {
    try {
      const state = JSON.parse(text);
      const current = state.weather.current;
      const units = state.weather.current_units ?? {};
      const daily = state.weather.daily;
      const derived = state.weather.derived ?? {};
      const today = Qt.formatDate(new Date(), "yyyy-MM-dd"); // local date, to match the forecast days
      const days = [];
      for (let i = 0; i < daily.time.length && days.length < 3; i++) {
        if (daily.time[i] <= today) {
          continue;
        }
        const date = new Date(`${daily.time[i]}T12:00:00`);
        days.push({
          name: date.toLocaleDateString(Qt.locale("en_US"), "dddd").toUpperCase(),
          icon: (derived.daily_icons ?? [])[i] ?? "",
          high: Math.round(daily.temperature_2m_max[i]),
          low: Math.round(daily.temperature_2m_min[i])
        });
      }
      if (root.pendingPlace !== "" && (state.location.label ?? "").startsWith(root.pendingPlace)) {
        root.pendingPlace = "";
      }
      root.weather = {
        timestamp: state.meta.current_timestamp,
        place: state.location.city || state.location.label || "",
        temperature: Math.round(current.temperature_2m),
        feels: current.apparent_temperature === undefined ? null : Math.round(current.apparent_temperature),
        wind: Math.round(current.wind_speed_10m),
        humidity: Math.round(current.relative_humidity_2m),
        unit: units.temperature_2m ?? "°C",
        windUnit: units.wind_speed_10m ?? "km/h",
        icon: derived.icon ?? "",
        condition: derived.condition_name ?? "",
        days: days
      };
    } catch (e) {
      root.weather = null;
    }
  }

  function search(): void {
    const query = cityInput.text.trim();
    if (query === "") {
      results = [];
      return;
    }
    searchProc.query = query;
    searchProc.running = false;
    searchProc.running = true;
  }

  function choose(index: int): void {
    const place = results[index];
    if (!place) {
      return;
    }
    const label = [place.name, place.region.split(", ")[0]].filter(part => part).join(", ");
    Quickshell.execDetached([`${Omadora.omadoraPath}/libexec/omadora-weather-location`, "set", `${place.latitude}`, `${place.longitude}`, label]);
    pendingPlace = place.name;
    stopEditing();
  }

  function stopEditing(): void {
    editing = false;
    results = [];
    cityInput.text = "";
  }

  // Ask the weather check for fresh data when what we have is old
  function refresh(): void {
    if (!weather || staleMinutes > 20) {
      Quickshell.execDetached(["systemctl", "--user", "start", "--no-block", "omadora-weather-check.service"]);
    }
  }

  panelWidth: 520
  centered: true
  onOpenChanged: {
    if (open) {
      refresh();
    } else {
      stopEditing();
    }
  }

  Timer {
    id: debounce

    interval: 300
    onTriggered: root.search()
  }

  Process {
    id: searchProc

    property string query: ""

    command: [`${Omadora.omadoraPath}/libexec/omadora-weather-search`, query]
    stdout: StdioCollector {
      onStreamFinished: {
        // Ignore answers to a query that has since changed
        if (searchProc.query !== cityInput.text.trim()) {
          return;
        }
        try {
          root.results = JSON.parse(text.trim());
        } catch (e) {
          root.results = [];
        }
        root.selected = 0;
      }
    }
  }

  FileView {
    path: root.stateFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parse(text())
  }

  component Caption: Text {
    color: Qt.alpha(Omadora.foreground, 0.6)
    font.family: root.mono
    font.pointSize: Omadora.fontSize - 2.5
    font.letterSpacing: 1
  }

  component Stat: Column {
    property string label
    property string value

    spacing: 4

    Caption {
      text: parent.label
    }

    Text {
      text: parent.value
      color: Omadora.foreground
      font.family: root.mono
      font.pointSize: Omadora.fontSize + 1
    }
  }

  Caption {
    visible: root.weather === null
    text: "WEATHER DATA UNAVAILABLE"
  }

  Item {
    visible: root.weather !== null
    width: parent.width
    height: visible ? 100 : 0

    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 18

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.weather?.icon ?? ""
        color: Qt.alpha(Omadora.foreground, 0.8)
        font.family: root.mono
        font.pointSize: Omadora.pt(40)
      }

      Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
          text: `${root.weather?.temperature ?? "--"}`
          color: Omadora.accent
          font.family: root.mono
          font.pointSize: Omadora.pt(44)
          font.weight: Font.Light
        }

        Text {
          y: 10
          text: root.weather?.unit ?? ""
          color: Omadora.accent
          font.family: root.mono
          font.pointSize: Omadora.fontSize + 3
        }
      }
    }

    Column {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 14

      // City: click to search for another one
      Item {
        anchors.right: parent.right
        width: root.editing ? 300 : cityRow.implicitWidth
        height: root.editing ? 40 : cityRow.implicitHeight

        Row {
          id: cityRow

          visible: !root.editing
          spacing: 6

          Text {
            text: Omadora.glyph(0xf041)
            color: Qt.alpha(Omadora.foreground, cityMouse.containsMouse ? 1 : 0.6)
            font.family: root.mono
            font.pointSize: Omadora.fontSize - 2
          }

          Caption {
            text: (root.pendingPlace !== "" ? root.pendingPlace : (root.weather?.place ?? "")).toUpperCase()
            color: Qt.alpha(Omadora.foreground, cityMouse.containsMouse ? 1 : 0.6)
          }
        }

        MouseArea {
          id: cityMouse

          anchors.fill: cityRow
          anchors.margins: -4
          visible: !root.editing
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.editing = true;
            cityInput.forceActiveFocus();
          }
        }

        Row {
          visible: root.editing
          spacing: 12

          Rectangle {
            width: 260
            height: 40
            color: Qt.alpha(Omadora.foreground, 0.07)
            border.width: 1
            border.color: Qt.alpha(Omadora.accent, 0.6)

            TextInput {
              id: cityInput

              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              verticalAlignment: TextInput.AlignVCenter
              color: Omadora.foreground
              selectionColor: Omadora.accent
              font.family: root.mono
              font.pointSize: Omadora.fontSize + 1
              clip: true
              onTextChanged: debounce.restart()
              onAccepted: root.choose(root.selected)

              Keys.onEscapePressed: event => {
                root.stopEditing();
                event.accepted = true;
              }
              Keys.onDownPressed: root.selected = Math.min(root.selected + 1, root.results.length - 1)
              Keys.onUpPressed: root.selected = Math.max(root.selected - 1, 0)
            }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "×"
            color: Qt.alpha(Omadora.foreground, closeMouse.containsMouse ? 1 : 0.6)
            font.family: root.mono
            font.pointSize: Omadora.fontSize + 2

            MouseArea {
              id: closeMouse

              anchors.fill: parent
              anchors.margins: -6
              hoverEnabled: true
              onClicked: root.stopEditing()
            }
          }
        }
      }

      Row {
        spacing: 28

        Stat {
          label: "FEELS"
          value: root.weather?.feels !== null && root.weather?.feels !== undefined ? `${root.weather.feels}${root.weather.unit}` : "—"
        }
        Stat {
          label: "WIND"
          value: `${root.weather?.wind ?? "--"} ${root.weather?.windUnit ?? ""}`
        }
        Stat {
          label: "HUMID"
          value: `${root.weather?.humidity ?? "--"}%`
        }
      }
    }
  }

  // City search results
  Column {
    visible: root.editing && root.results.length > 0
    width: parent.width

    Repeater {
      model: root.results

      Rectangle {
        id: place

        required property var modelData
        required property int index

        width: parent.width
        height: 36
        color: index === root.selected ? Qt.alpha(Omadora.foreground, 0.07) : (placeMouse.containsMouse ? Qt.alpha(Omadora.foreground, 0.04) : "transparent")

        Row {
          anchors.verticalCenter: parent.verticalCenter
          x: 12
          spacing: 10

          Text {
            text: place.modelData.name
            color: Omadora.foreground
            font.family: root.mono
            font.pointSize: Omadora.fontSize
            font.bold: true
          }

          Text {
            text: place.modelData.region
            color: Qt.alpha(Omadora.foreground, 0.5)
            font.family: root.mono
            font.pointSize: Omadora.fontSize - 1
            anchors.baseline: undefined
          }
        }

        MouseArea {
          id: placeMouse

          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.choose(place.index)
        }
      }
    }
  }

  Rectangle {
    visible: root.weather !== null
    width: parent.width
    height: 1
    color: Qt.alpha(Omadora.foreground, 0.1)
  }

  Row {
    visible: root.weather !== null
    width: parent.width

    Repeater {
      model: root.weather?.days ?? []

      Item {
        id: day

        required property var modelData

        width: parent.width / 3
        height: 44

        Row {
          anchors.centerIn: parent
          spacing: 12

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: day.modelData.icon
            color: Qt.alpha(Omadora.foreground, 0.8)
            font.family: root.mono
            font.pointSize: Omadora.fontSize + 6
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Caption {
              text: day.modelData.name
            }

            Text {
              text: `${day.modelData.high}°  ${day.modelData.low}°`
              color: Omadora.foreground
              font.family: root.mono
              font.pointSize: Omadora.fontSize
            }
          }
        }
      }
    }
  }

  Caption {
    visible: root.weather !== null && root.staleMinutes > 30
    text: `UPDATED ${root.staleMinutes} MIN AGO`
  }
}
