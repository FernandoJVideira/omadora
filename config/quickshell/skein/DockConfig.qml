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
  property var pinned: []

  readonly property string script: `${Skein.skeinPath}/libexec/skein-dock`

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
      root.pinned = Array.isArray(data.pinned) ? data.pinned : [];
    } catch (e) {
      // keep what we have
    }
  }

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
