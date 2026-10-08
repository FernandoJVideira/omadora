import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Launcher and dmenu-style picker (replaces Wofi).
// Opened over IPC by omadora-launch-picker, which waits for the choice on a FIFO.
Scope {
  id: root

  property bool active: false
  property string mode: "dmenu" // dmenu | drun
  property string prompt: ""
  property int panelWidth: 600
  property int panelHeight: 400
  property bool markup: false
  property string outFile: ""
  property var items: []
  property var extraItems: [] // only shown while searching
  property string query: ""

  readonly property string mono: "JetBrainsMono Nerd Font"
  readonly property int rowHeight: 34

  readonly property var filtered: {
    const q = root.query.toLowerCase();
    if (q === "") {
      return root.items;
    }
    const direct = root.items.filter(item => item.plain.toLowerCase().includes(q));
    // Deeper entries: those whose own name matches rank first, then ones matching their path
    const ranked = root.extraItems.map(item => {
      const name = item.plain.toLowerCase();
      const rank = name.startsWith(q) ? 0 : (name.includes(q) ? 1 : (item.search.includes(q) ? 2 : 3));
      return {
        item: item,
        rank: rank
      };
    }).filter(entry => entry.rank < 3);
    ranked.sort((a, b) => a.rank - b.rank);
    return direct.concat(ranked.map(entry => entry.item));
  }

  function plainText(text: string): string {
    return root.markup ? text.replace(/<[^>]*>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&") : text;
  }

  function richText(text: string): string {
    return text.replace(/<tt>/g, '<span style="font-family:monospace">').replace(/<\/tt>/g, "</span>");
  }

  // Hand the choice (or nothing, when cancelled) to whoever is waiting on the FIFO
  function reply(text: string): void {
    if (root.outFile !== "") {
      Quickshell.execDetached(["bash", "-c", 'printf %s "$1" > "$2"', "_", text, root.outFile]);
      root.outFile = "";
    }
  }

  function close(): void {
    root.reply("");
    root.active = false;
  }

  function choose(index: int): void {
    const item = root.filtered[index];
    if (!item) {
      return;
    }
    if (root.mode === "drun") {
      Quickshell.execDetached(["uwsm-app", "--", `${item.id}.desktop`]);
      root.active = false;
    } else {
      root.reply(item.text);
      root.active = false;
    }
  }

  function glyphOf(text: string): var {
    const glyph = text.match(/^([\uE000-\uF8FF]|[\uD800-\uDBFF][\uDC00-\uDFFF])\s+/);
    return glyph;
  }

  function loadExtraItems(extraFile: string): void {
    if (extraFile === "") {
      root.extraItems = [];
      return;
    }
    extraView.path = "";
    extraView.path = extraFile;
    root.extraItems = extraView.text().split("\n").filter(line => line !== "").map(line => {
      const [left, parent = "", result = ""] = line.split("\t");
      const glyph = root.glyphOf(left);
      const label = glyph ? left.slice(glyph[0].length) : left;
      return {
        text: result,
        label: label,
        plain: label,
        search: `${label} ${parent}`.toLowerCase(),
        glyph: glyph ? glyph[1] : "",
        trailing: parent,
        id: "",
        icon: ""
      };
    });
  }

  function loadItems(itemsFile: string): void {
    if (root.mode === "drun") {
      root.items = DesktopEntries.applications.values.filter(entry => !entry.noDisplay).sort((a, b) => a.name.localeCompare(b.name)).map(entry => ({
            text: entry.name,
            label: entry.name,
            plain: entry.name,
            glyph: "",
            trailing: "",
            id: entry.id,
            icon: Quickshell.iconPath(entry.icon, true) ?? ""
          }));
    } else {
      itemsView.path = "";
      itemsView.path = itemsFile;
      root.items = itemsView.text().split("\n").filter(line => line !== "").map(line => {
        // "<glyph>  Label<TAB>trailing": the glyph gets its own column, the trailing text sits on the right
        const [left, trailing = ""] = line.split("\t");
        const glyph = left.match(/^([\uE000-\uF8FF]|[\uD800-\uDBFF][\uDC00-\uDFFF])\s+/);
        const label = glyph ? left.slice(glyph[0].length) : left;
        return {
          text: line,
          label: label,
          plain: root.plainText(label),
          glyph: glyph ? glyph[1] : "",
          trailing: trailing,
          id: "",
          icon: ""
        };
      });
    }
  }

  IpcHandler {
    target: "picker"

    function open(mode: string, prompt: string, width: int, height: int, markup: bool, preselect: int, itemsFile: string, outFile: string, extraFile: string, search: string): void {
      if (root.active) {
        root.reply("");
      }
      root.mode = mode;
      root.prompt = prompt;
      root.panelWidth = width;
      root.panelHeight = height;
      root.markup = markup;
      root.outFile = outFile;
      root.query = search;
      root.loadItems(itemsFile);
      root.loadExtraItems(extraFile);
      list.currentIndex = preselect > 0 && preselect <= root.items.length ? preselect - 1 : 0;
      root.active = true;
    }

    function close(): void {
      if (root.active) {
        root.close();
      }
    }

    function isOpen(): bool {
      return root.active;
    }
  }

  FileView {
    id: itemsView

    blockLoading: true
    printErrors: false
  }

  FileView {
    id: extraView

    blockLoading: true
    printErrors: false
  }

  PanelWindow {
    id: window

    visible: root.active
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omadora-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
      if (visible) {
        input.text = root.query;
        input.forceActiveFocus();
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }

    Rectangle {
      id: panel

      readonly property int headerHeight: 44

      anchors.centerIn: parent
      // Wider while searching, so the path of each result fits
      width: root.query !== "" && root.extraItems.length > 0 ? Math.max(root.panelWidth, 500) : root.panelWidth
      height: Math.min(root.panelHeight, headerHeight + Math.max(root.items.length, Math.min(root.filtered.length, 10)) * root.rowHeight + 28)
      color: Qt.alpha(Omadora.background, 0.97)
      border.width: 2
      border.color: Qt.alpha(Omadora.accent, 0.8)

      MouseArea {
        anchors.fill: parent
      }

      Item {
        id: header

        x: 14
        width: parent.width - 28
        height: panel.headerHeight

        Text {
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: 4
          x: 12
          visible: input.text === ""
          text: root.prompt
          color: Qt.alpha(Omadora.foreground, 0.5)
          font.family: root.mono
          font.pointSize: Omadora.pt(11)
        }

        TextInput {
          id: input

          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.topMargin: 4
          verticalAlignment: TextInput.AlignVCenter
          color: Omadora.foreground
          selectionColor: Omadora.accent
          font.family: root.mono
          font.pointSize: Omadora.pt(11)
          clip: true
          onTextChanged: {
            root.query = text;
            list.currentIndex = 0;
          }
          onAccepted: root.choose(list.currentIndex)

          Keys.onEscapePressed: root.close()
          Keys.onDownPressed: list.incrementCurrentIndex()
          Keys.onUpPressed: list.decrementCurrentIndex()
          Keys.onTabPressed: list.incrementCurrentIndex()
          Keys.onBacktabPressed: list.decrementCurrentIndex()
          Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier) {
              if (event.key === Qt.Key_N || event.key === Qt.Key_J) {
                list.incrementCurrentIndex();
                event.accepted = true;
              } else if (event.key === Qt.Key_P || event.key === Qt.Key_K) {
                list.decrementCurrentIndex();
                event.accepted = true;
              }
            } else if (event.key === Qt.Key_PageDown) {
              list.currentIndex = Math.min(list.currentIndex + 8, list.count - 1);
              event.accepted = true;
            } else if (event.key === Qt.Key_PageUp) {
              list.currentIndex = Math.max(list.currentIndex - 8, 0);
              event.accepted = true;
            }
          }
        }
      }

      ListView {
        id: list

        x: 14
        y: panel.headerHeight
        width: parent.width - 28
        height: parent.height - panel.headerHeight - 14
        clip: true
        model: root.filtered
        currentIndex: 0
        highlightMoveDuration: 0
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
          id: row

          required property var modelData
          required property int index

          readonly property bool current: ListView.isCurrentItem

          width: list.width
          height: root.rowHeight
          color: current ? Qt.alpha(Omadora.foreground, 0.07) : "transparent"

          Text {
            id: glyph

            visible: row.modelData.glyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            width: visible ? 28 : 0
            text: row.modelData.glyph
            color: row.current ? Omadora.accent : Omadora.foreground
            font.family: Omadora.fontFamily
            font.pointSize: Omadora.pt(11)
          }

          Image {
            visible: row.modelData.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            width: visible ? 22 : 0
            height: 22
            source: row.modelData.icon
            sourceSize: Qt.size(44, 44)
            asynchronous: true
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 12 + (row.modelData.glyph !== "" ? 28 : 0) + (row.modelData.icon !== "" ? 32 : 0)
            width: parent.width - x - (row.modelData.trailing !== "" ? trailingText.implicitWidth + 28 : 12)
            elide: Text.ElideRight
            textFormat: root.markup ? Text.RichText : Text.PlainText
            text: root.markup ? root.richText(row.modelData.text) : row.modelData.label
            color: row.current ? Omadora.accent : Omadora.foreground
            font.family: root.mono
            font.pointSize: Omadora.pt(11)
          }

          Text {
            id: trailingText

            visible: row.modelData.trailing !== ""
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 18
            text: row.modelData.trailing
            color: Qt.alpha(Omadora.foreground, 0.45)
            font.family: root.mono
            font.pointSize: Omadora.pt(11)
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.choose(row.index)
          }
        }
      }
    }
  }
}
