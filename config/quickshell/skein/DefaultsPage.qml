import QtQuick

// Settings > Defaults: the default browser, terminal and editor.
SettingsPage {
  id: root

  readonly property var sys: backend?.sysState ?? ({})

  function entries(names: var): var {
    return names.map(n => ({
          label: n[0],
          value: n[1]
        }));
  }

  SettingsSection {
    title: "Defaults"

    ComboRow {
      label: "Browser"
      options: root.entries([["Chromium", "chromium"], ["Firefox", "firefox"], ["Helium", "helium"], ["Brave", "brave"], ["Brave Origin", "brave-origin"], ["Chrome", "chrome"], ["Edge", "edge"], ["Zen", "zen"]])
      current: root.sys.browser ?? ""
      onChosen: value => root.backend.set("browser", value, "skein-default-browser", [value])
    }

    ComboRow {
      label: "Terminal"
      options: root.entries([["Alacritty", "alacritty"], ["Foot", "foot"], ["Ghostty", "ghostty"], ["Kitty", "kitty"]])
      current: root.sys.terminal ?? ""
      onChosen: value => root.backend.set("terminal", value, "skein-default-terminal", [value])
    }

    ComboRow {
      label: "Editor"
      options: root.entries([["Neovim", "nvim"], ["Vim", "vim"], ["Helix", "helix"], ["Emacs", "emacs"], ["VSCode", "code"], ["Zed", "zed"]])
      current: root.sys.editor ?? ""
      onChosen: value => root.backend.set("editor", value, "skein-default-editor", [value])
    }
  }
}
