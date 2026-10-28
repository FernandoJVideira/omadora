import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Launcher and dmenu-style picker (replaces Wofi).
// Opened over IPC by skein-launch-picker, which waits for the choice on a FIFO.
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

  // Every picker shares one Spotlight-style look. The app launcher (drun) adds the
  // Applications / Files / Actions / Clipboard search; menus (dmenu) just list their choices.
  readonly property bool apps: mode === "drun"
  property int pendingSelect: -1
  property string scope: "all" // all | apps | files | actions | clipboard
  property var fileResults: []
  property string fileQuery: ""
  property var clipItems: []

  readonly property var scopes: [
    {
      id: "apps",
      label: "Applications",
      glyph: "\uf009"
    },
    {
      id: "files",
      label: "Files",
      glyph: "\uf07b"
    },
    {
      id: "actions",
      label: "Actions",
      glyph: "\uf0e7"
    },
    {
      id: "clipboard",
      label: "Clipboard",
      glyph: "\uf0ea"
    }
  ]

  // Nothing here is destructive; shutting down goes through the power menu, which confirms
  readonly property var actionItems: [
    {
      label: "Settings",
      glyph: "\uf013",
      cmd: ["qs", "-c", "skein", "ipc", "call", "settings", "toggle"]
    },
    {
      label: "Lock Screen",
      glyph: "\uf023",
      cmd: [`${Skein.skeinPath}/libexec/skein-system-lock`]
    },
    {
      label: "Take Screenshot",
      glyph: "\uf030",
      cmd: [`${Skein.skeinPath}/libexec/skein-capture-screenshot`]
    },
    {
      label: "Power Menu",
      glyph: "\uf011",
      cmd: [`${Skein.skeinPath}/libexec/skein-menu`, "system"]
    },
    {
      label: "Skein Menu",
      glyph: "\uf0c9",
      cmd: [`${Skein.skeinPath}/libexec/skein-menu`]
    },
    {
      label: "Clear Clipboard History",
      glyph: "\uf1f8",
      cmd: [`${Skein.skeinPath}/libexec/skein-clipboard`, "clear"]
    }
  ]

  readonly property var spotRows: root.spotBuild()
  onSpotRowsChanged: {
    if (root.pendingSelect < 0) {
      spotList.currentIndex = root.stepSelection(-1, 1);
    }
  }

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

  function rankByName(list: var, q: string): var {
    if (q === "") {
      return list;
    }
    const starts = list.filter(item => item.label.toLowerCase().startsWith(q));
    const rest = list.filter(item => !item.label.toLowerCase().startsWith(q) && item.label.toLowerCase().includes(q));
    return starts.concat(rest);
  }

  function spotBuild(): var {
    const q = root.query.trim().toLowerCase();
    const match = text => q === "" || text.toLowerCase().includes(q);

    if (!root.apps) {
      const menu = root.filtered.map((item, i) => ({
            type: "menu",
            label: item.label,
            rich: root.markup ? root.richText(item.text) : "",
            glyph: item.glyph,
            icon: item.icon,
            sub: item.trailing,
            fi: i
          }));
      return menu.length > 0 ? menu : [
        {
          type: "empty",
          label: "No results"
        }
      ];
    }

    if (root.scope === "all" && q === "") {
      return root.scopes.map((entry, i) => ({
            type: "category",
            scope: entry.id,
            label: entry.label,
            glyph: entry.glyph,
            icon: "",
            sub: `Ctrl+${i + 1}`
          }));
    }

    const apps = root.rankByName(root.items.map(item => ({
            type: "app",
            label: item.label,
            glyph: "",
            icon: item.icon,
            sub: "",
            id: item.id
          })).filter(item => match(item.label)), q);
    const actions = root.actionItems.filter(item => match(item.label)).map(item => ({
          type: "action",
          label: item.label,
          glyph: item.glyph,
          icon: "",
          sub: "",
          cmd: item.cmd
        }));
    const files = root.fileResults;
    const clips = root.clipItems.filter(item => match(item.text)).map(item => ({
          type: "clip",
          label: item.text,
          glyph: "\uf0ea",
          icon: "",
          sub: "",
          id: item.id
        }));
    const section = (title, list, max) => list.length > 0 ? [
      {
        type: "header",
        label: title
      }
    ].concat(list.slice(0, max)) : [];

    let rows = [];
    switch (root.scope) {
    case "apps":
      rows = apps;
      break;
    case "files":
      rows = files;
      break;
    case "actions":
      rows = actions;
      break;
    case "clipboard":
      rows = clips;
      break;
    default:
      rows = section("Applications", apps, 4).concat(section("Actions", actions, 2), section("Files", files, 5), section("Clipboard", clips, 3));
    }

    if (rows.length === 0) {
      const hint = root.scope === "files" && q.length < 2 ? "Type to search your files" : "No results";
      return [
        {
          type: "empty",
          label: hint
        }
      ];
    }
    return rows;
  }

  function selectable(row: var): bool {
    return row !== undefined && row.type !== "header" && row.type !== "empty";
  }

  // Next selectable row from `from` in direction `dir` (+1/-1), staying put at the ends
  function stepSelection(from: int, dir: int): int {
    let i = from + dir;
    while (i >= 0 && i < root.spotRows.length) {
      if (root.selectable(root.spotRows[i])) {
        return i;
      }
      i += dir;
    }
    return from;
  }

  function spotActivate(row: var): void {
    if (!root.selectable(row)) {
      return;
    }
    switch (row.type) {
    case "menu":
      root.choose(row.fi);
      return;
    case "category":
      root.scope = row.scope;
      spotInput.text = "";
      return;
    case "app":
      Quickshell.execDetached(["uwsm-app", "--", `${row.id}.desktop`]);
      break;
    case "file":
      Quickshell.execDetached(["xdg-open", row.path]);
      break;
    case "clip":
      Quickshell.execDetached([`${Skein.skeinPath}/libexec/skein-clipboard`, "copy", row.id]);
      break;
    case "action":
      Quickshell.execDetached(row.cmd);
      break;
    }
    root.active = false;
  }

  function setScope(name: string): void {
    root.scope = name;
    spotInput.text = "";
    root.searchFiles();
  }

  function searchFiles(): void {
    const q = root.query.trim();
    fileProc.running = false;
    if (!root.apps || q.length < 2 || (root.scope !== "all" && root.scope !== "files")) {
      root.fileResults = [];
      return;
    }
    root.fileQuery = q;
    fileProc.command = ["bash", "-c", 'plocate -i -b -l 20000 -- "$1" 2>/dev/null | grep -E "^$HOME/" | grep -vE "/(\\.|node_modules/|site-packages/|miniconda3/)" | awk \'{ print length($0) "\\t" $0 }\' | sort -n | head -n 30 | cut -f2- | while IFS= read -r path; do if [ -d "$path" ]; then printf "d\\t%s\\n" "$path"; else printf "f\\t%s\\n" "$path"; fi; done', "_", q];
    fileProc.running = true;
  }

  function parseFiles(text: string): var {
    const home = Quickshell.env("HOME");
    return text.split("\n").filter(line => line !== "").map(line => {
      const [kind, path] = line.split("\t");
      const cut = path.lastIndexOf("/");
      const folder = path.slice(0, cut).replace(home, "~");
      return {
        type: "file",
        label: path.slice(cut + 1),
        glyph: kind === "d" ? "\uf07b" : "\uf15b",
        icon: "",
        sub: folder,
        path: path
      };
    });
  }

  function parseClips(text: string): var {
    return text.split("\n").filter(line => line !== "").map(line => {
      const tab = line.indexOf("\t");
      return {
        id: line.slice(0, tab),
        text: line.slice(tab + 1)
      };
    });
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

  // The installed apps. Quickshell scans the desktop entries in the background, so this is empty
  // until that is done; the Connections below fills the list in when it arrives.
  function appItems(): var {
    return DesktopEntries.applications.values.filter(entry => !entry.noDisplay).sort((a, b) => a.name.localeCompare(b.name)).map(entry => ({
          text: entry.name,
          label: entry.name,
          plain: entry.name,
          glyph: "",
          trailing: "",
          id: entry.id,
          icon: Quickshell.iconPath(entry.icon, true) ?? ""
        }));
  }

  function loadItems(itemsFile: string): void {
    if (root.mode === "drun") {
      root.items = root.appItems();
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

  Connections {
    target: DesktopEntries.applications

    function onValuesChanged(): void {
      if (root.active && root.mode === "drun") {
        root.items = root.appItems();
        spotList.currentIndex = root.stepSelection(-1, 1);
      }
    }
  }

  Process {
    id: fileProc

    stdout: StdioCollector {
      onStreamFinished: {
        // Ignore a search that was already replaced by a newer query
        if (root.fileQuery === root.query.trim()) {
          root.fileResults = root.parseFiles(text);
        }
      }
    }
  }

  Process {
    id: clipProc

    command: [`${Skein.skeinPath}/libexec/skein-clipboard`, "list"]
    stdout: StdioCollector {
      onStreamFinished: root.clipItems = root.parseClips(text)
    }
  }

  Timer {
    id: fileTimer

    interval: 140
    onTriggered: root.searchFiles()
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
      root.pendingSelect = preselect > 0 && preselect <= root.items.length ? preselect - 1 : -1;
      root.scope = "all";
      root.fileResults = [];
      if (root.apps) {
        clipProc.running = false;
        clipProc.running = true;
      }
      root.active = true;
      if (root.pendingSelect >= 0) {
        spotList.currentIndex = root.pendingSelect;
        root.pendingSelect = -1;
      }
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
    WlrLayershell.namespace: "skein-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
      if (visible) {
        spotInput.text = root.query;
        spotInput.forceActiveFocus();
        if (root.pendingSelect >= 0) {
          spotList.currentIndex = root.pendingSelect;
          root.pendingSelect = -1;
        }
        spotFade.restart();
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }

    Item {
      id: spotRoot

      width: root.apps ? Math.max(root.panelWidth, 700) : Math.max(root.panelWidth, 360)
      x: Math.round((parent.width - width) / 2)
      // The launcher sits high like Spotlight; menus stay centred
      y: root.apps ? Math.round(parent.height * 0.2) : Math.round((parent.height - height) / 2)
      height: bar.height + 10 + card.height

      NumberAnimation on opacity {
        id: spotFade

        running: false
        from: 0
        to: 1
        duration: 130
        easing.type: Easing.OutCubic
      }

      // Search field
      Rectangle {
        id: bar

        width: parent.width
        height: 58
        radius: height / 2
        color: Qt.alpha(Skein.background, 0.88)
        border.width: 1
        border.color: Qt.alpha(Skein.foreground, 0.16)

        MouseArea {
          anchors.fill: parent
        }

        Text {
          id: magnifier

          anchors.verticalCenter: parent.verticalCenter
          x: 22
          text: ""
          color: Qt.alpha(Skein.foreground, 0.55)
          font.family: root.mono
          font.pointSize: Skein.pt(14)
        }

        // The chosen category, shown in front of the text like Spotlight's token
        Rectangle {
          id: scopeChip

          readonly property var info: root.scopes.find(entry => entry.id === root.scope)

          visible: root.scope !== "all"
          anchors.verticalCenter: parent.verticalCenter
          x: magnifier.x + magnifier.width + 14
          width: chipText.implicitWidth + 24
          height: 30
          radius: 15
          color: Qt.alpha(Skein.accent, 0.9)

          Text {
            id: chipText

            anchors.centerIn: parent
            text: scopeChip.info ? scopeChip.info.label : ""
            color: Skein.background
            font.family: Skein.fontFamily
            font.pointSize: Skein.pt(11)
            font.weight: Font.Medium
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          x: spotInput.x
          visible: spotInput.text === ""
          text: root.apps ? "Skein Search" : root.prompt
          color: Qt.alpha(Skein.foreground, 0.5)
          font.family: Skein.fontFamily
          font.pointSize: Skein.pt(15)
        }

        TextInput {
          id: spotInput

          x: scopeChip.visible ? scopeChip.x + scopeChip.width + 12 : magnifier.x + magnifier.width + 14
          width: parent.width - x - 24
          height: parent.height
          verticalAlignment: TextInput.AlignVCenter
          color: Skein.foreground
          selectionColor: Skein.accent
          font.family: Skein.fontFamily
          font.pointSize: Skein.pt(15)
          clip: true
          onTextChanged: {
            root.query = text;
            fileTimer.restart();
            spotList.currentIndex = root.stepSelection(-1, 1);
          }
          onAccepted: root.spotActivate(root.spotRows[spotList.currentIndex])

          Keys.onEscapePressed: root.close()
          Keys.onDownPressed: spotList.currentIndex = root.stepSelection(spotList.currentIndex, 1)
          Keys.onUpPressed: spotList.currentIndex = root.stepSelection(spotList.currentIndex, -1)
          Keys.onTabPressed: spotList.currentIndex = root.stepSelection(spotList.currentIndex, 1)
          Keys.onBacktabPressed: spotList.currentIndex = root.stepSelection(spotList.currentIndex, -1)
          Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier) {
              const number = event.key - Qt.Key_0;
              if (root.apps && number >= 1 && number <= root.scopes.length) {
                root.setScope(root.scopes[number - 1].id);
                event.accepted = true;
              } else if (event.key === Qt.Key_N || event.key === Qt.Key_J) {
                spotList.currentIndex = root.stepSelection(spotList.currentIndex, 1);
                event.accepted = true;
              } else if (event.key === Qt.Key_P || event.key === Qt.Key_K) {
                spotList.currentIndex = root.stepSelection(spotList.currentIndex, -1);
                event.accepted = true;
              }
            } else if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
              const dir = event.key === Qt.Key_PageDown ? 1 : -1;
              for (let n = 0; n < 8; n++) {
                spotList.currentIndex = root.stepSelection(spotList.currentIndex, dir);
              }
              event.accepted = true;
            } else if (event.key === Qt.Key_Backspace && text === "" && root.scope !== "all") {
              // Backspace on an empty field drops the category token
              root.setScope("all");
              event.accepted = true;
            }
          }
        }
      }

      // Results
      Rectangle {
        id: card

        y: bar.height + 10
        width: parent.width
        height: Math.min(spotList.contentHeight, root.apps ? 8 * 46 : Math.max(root.panelHeight - 80, 8 * 46)) + 20
        radius: 24
        color: Qt.alpha(Skein.background, 0.88)
        border.width: 1
        border.color: Qt.alpha(Skein.foreground, 0.16)
        clip: true

        Behavior on height {
          NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
          }
        }

        MouseArea {
          anchors.fill: parent
        }

        ListView {
          id: spotList

          x: 10
          y: 10
          width: parent.width - 20
          height: parent.height - 20
          clip: true
          model: root.spotRows
          currentIndex: 0
          highlightMoveDuration: 0
          boundsBehavior: Flickable.StopAtBounds

          delegate: Item {
            id: srow

            required property var modelData
            required property int index

            readonly property bool current: ListView.isCurrentItem && root.selectable(srow.modelData)
            readonly property bool plain: srow.modelData.type === "header" || srow.modelData.type === "empty"

            width: spotList.width
            height: srow.modelData.type === "header" ? 32 : 46

            Text {
              visible: srow.modelData.type === "header"
              anchors.verticalCenter: parent.verticalCenter
              anchors.verticalCenterOffset: 4
              x: 14
              text: srow.modelData.label
              color: Qt.alpha(Skein.foreground, 0.5)
              font.family: Skein.fontFamily
              font.pointSize: Skein.pt(10)
              font.weight: Font.Medium
            }

            Text {
              visible: srow.modelData.type === "empty"
              anchors.centerIn: parent
              text: srow.modelData.label
              color: Qt.alpha(Skein.foreground, 0.5)
              font.family: Skein.fontFamily
              font.pointSize: Skein.pt(12)
            }

            Rectangle {
              visible: !srow.plain
              anchors.fill: parent
              radius: 14
              color: srow.current ? Qt.alpha(Skein.accent, 0.9) : "transparent"

              Text {
                visible: (srow.modelData.icon ?? "") === "" && (srow.modelData.glyph ?? "") !== ""
                anchors.verticalCenter: parent.verticalCenter
                x: 12
                width: 30
                horizontalAlignment: Text.AlignHCenter
                text: srow.modelData.glyph ?? ""
                color: srow.current ? Skein.background : Qt.alpha(Skein.foreground, 0.8)
                font.family: root.mono
                font.pointSize: Skein.pt(14)
              }

              Image {
                visible: (srow.modelData.icon ?? "") !== ""
                anchors.verticalCenter: parent.verticalCenter
                x: 12
                width: 30
                height: 30
                source: srow.modelData.icon ?? ""
                sourceSize: Qt.size(60, 60)
                asynchronous: true
              }

              Text {
                id: rowLabel

                anchors.verticalCenter: parent.verticalCenter
                x: 54
                width: parent.width - x - (rowSub.visible ? Math.min(rowSub.implicitWidth, parent.width * 0.4) + 30 : 14)
                elide: Text.ElideRight
                textFormat: (srow.modelData.rich ?? "") !== "" ? Text.RichText : Text.PlainText
                text: (srow.modelData.rich ?? "") !== "" ? srow.modelData.rich : (srow.modelData.label ?? "")
                color: srow.current ? Skein.background : Skein.foreground
                font.family: Skein.fontFamily
                font.pointSize: Skein.pt(12)
              }

              Text {
                id: rowSub

                visible: (srow.modelData.sub ?? "") !== ""
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 16
                width: Math.min(implicitWidth, parent.width * 0.4)
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignRight
                text: srow.modelData.sub ?? ""
                color: srow.current ? Qt.alpha(Skein.background, 0.7) : Qt.alpha(Skein.foreground, 0.45)
                font.family: Skein.fontFamily
                font.pointSize: Skein.pt(11)
              }
            }

            MouseArea {
              anchors.fill: parent
              enabled: !srow.plain
              hoverEnabled: true
              onEntered: spotList.currentIndex = srow.index
              onClicked: root.spotActivate(srow.modelData)
            }
          }
        }
      }
    }
  }
}
