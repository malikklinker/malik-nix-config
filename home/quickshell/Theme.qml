pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`
  property var catalog: []
  property var current: ({
    slug: "catppuccin-mocha", name: "Catppuccin Mocha", variant: "dark",
    colors: {
      background: "#1e1e2e", surface: "#313244", overlay: "#45475a", muted: "#6c7086",
      subtext: "#a6adc8", text: "#cdd6f4", accent: "#cba6f7", secondary: "#89b4fa",
      red: "#f38ba8", yellow: "#f9e2af"
    }
  })
  readonly property color background: current.colors.background
  readonly property color surface: current.colors.surface
  readonly property color overlay: current.colors.overlay
  readonly property color muted: current.colors.muted
  readonly property color subtext: current.colors.subtext
  readonly property color text: current.colors.text
  readonly property color accent: current.colors.accent
  readonly property color red: current.colors.red
  readonly property color yellow: current.colors.yellow

  FileView {
    path: `${root.configHome}/desktop-theme/catalog.json`
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.catalog = JSON.parse(text()) }
      catch (error) { console.warn("Could not read theme catalog:", error) }
    }
  }

  FileView {
    path: `${root.stateHome}/desktop-theme/theme.json`
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        const theme = JSON.parse(text())
        if (theme.colors && theme.slug) root.current = theme
      } catch (error) { console.warn("Could not read selected palette:", error) }
    }
  }
}
