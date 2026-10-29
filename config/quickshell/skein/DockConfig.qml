pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Dock settings, read from ~/.config/skein/dock.json. Changes go through skein-dock, which
// writes the file; the values are also updated here at once so the dock reacts without delay.
Singleton {
  id: root

  property bool enabled: false
  property string position: "bottom" // bottom, left or right
  property int iconSize: 48
  property bool magnify: true
  property int magnifySize: 72
  property bool autoHide: false
  property bool showRunning: true
  property bool showIndicators: true
  property bool showTrash: true
  property bool showDownloads: true
  property var pinned: []
  // Where the app icons come from: the folder of an icon pack, or empty for the system icon theme.
  // Until a choice is made, the WhiteSur pack (rounded squares, like macOS) if it is installed.
  property string iconPack: `${Skein.home}/.local/share/icons/WhiteSur/apps/scalable`
  property string iconPackName: "WhiteSur"
  // Icons you picked yourself: {"<app id>": "/path/to/image"}
  property var icons: ({})
  // The pack's files by lowercase icon name, so the dock only ever asks for files that exist
  property var packIndex: ({})

  readonly property string script: `${Skein.skeinPath}/libexec/skein-dock`
  readonly property string packTool: `${Skein.skeinPath}/libexec/skein-icon-pack`

  onIconPackChanged: {
    indexProc.running = false;
    indexProc.running = true;
  }

  function resetIcon(app: string): void {
    const next = Object.assign({}, icons);
    delete next[app];
    icons = next;
    Quickshell.execDetached([script, "icon-reset", app]);
  }

  function set(key: string, value: var): void {
    root[key] = value;
    Quickshell.execDetached([script, "set", key, JSON.stringify(value)]);
  }

  function pin(id: string): void {
    if (!pinned.includes(id)) {
      pinned = [...pinned, id];
    }
    Quickshell.execDetached([script, "pin", id]);
  }

  function unpin(id: string): void {
    pinned = pinned.filter(p => p !== id);
    Quickshell.execDetached([script, "unpin", id]);
  }

  // Your own dock entry (see skein-dock launcher): a desktop entry running a command, pinned at the end
  function addLauncher(name: string, command: string, icon: string): void {
    Quickshell.execDetached([script, "launcher", name, command, icon]);
  }

  function removeLauncher(id: string): void {
    pinned = pinned.filter(p => p !== id);
    Quickshell.execDetached([script, "launcher-remove", id]);
  }

  // Drag and drop: put an app at a position, adding it to the dock if it was not there
  function place(id: string, index: int): void {
    const rest = pinned.filter(p => p !== id);
    const at = Math.max(0, Math.min(rest.length, index));
    pinned = [...rest.slice(0, at), id, ...rest.slice(at)];
    Quickshell.execDetached([script, "place", id, `${at}`]);
  }

  // Use a whole dock preset at once: {position, iconSize, magnify, ...}; the apps stay as they are
  function applyLayout(settings: var): void {
    for (const key of Object.keys(settings)) {
      root[key] = settings[key];
    }
    Quickshell.execDetached([script, "apply", JSON.stringify(settings)]);
  }

  function move(id: string, delta: int): void {
    const i = pinned.indexOf(id);
    const j = i + delta;
    if (i < 0 || j < 0 || j >= pinned.length) {
      return;
    }
    const next = [...pinned];
    [next[i], next[j]] = [next[j], next[i]];
    pinned = next;
    Quickshell.execDetached([script, "move", id, `${delta}`]);
  }

  function apply(text: string): void {
    try {
      const data = JSON.parse(text);
      root.enabled = data.enabled ?? false;
      root.position = ["bottom", "left", "right"].includes(data.position) ? data.position : "bottom";
      root.iconSize = Math.max(28, Math.min(112, data.iconSize ?? 48));
      root.magnify = data.magnify ?? true;
      root.magnifySize = Math.max(root.iconSize, Math.min(160, data.magnifySize ?? 72));
      root.autoHide = data.autoHide ?? false;
      root.showRunning = data.showRunning ?? true;
      root.showIndicators = data.showIndicators ?? true;
      root.showTrash = data.showTrash ?? true;
      root.showDownloads = data.showDownloads ?? true;
      root.pinned = Array.isArray(data.pinned) ? data.pinned : [];
      if (typeof data.iconPack === "string") {
        root.iconPack = data.iconPack;
        root.iconPackName = data.iconPackName ?? "";
      }
      root.icons = data.icons && typeof data.icons === "object" ? data.icons : {};
    } catch (e) {
      // keep what we have
    }
  }

  Process {
    id: indexProc

    command: [root.packTool, "index"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.packIndex = JSON.parse(text);
        } catch (e) {
          root.packIndex = {};
        }
      }
    }
  }

  Component.onCompleted: indexProc.running = true

  FileView {
    path: `${Skein.home}/.config/skein/dock.json`
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.apply(text())
    // First run: create the file with a few of your apps already pinned
    onLoadFailed: Quickshell.execDetached([root.script, "init"])
  }
}
