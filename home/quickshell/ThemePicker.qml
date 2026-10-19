pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
  id: root
  implicitWidth: 28
  implicitHeight: 28
  radius: 6
  color: pointer.containsMouse ? Theme.overlay : "transparent"
  property string errorMessage: ""

  function show() {
    search.text = ""
    errorMessage = ""
    picker.visible = true
    search.forceActiveFocus()
  }

  function choose(theme) {
    if (applyTheme.running) return
    errorMessage = ""
    applyTheme.command = ["theme-set", theme.slug]
    applyTheme.running = true
  }

  IpcHandler {
    target: "theme"
    function openPicker(): void { root.show() }
  }

  Text {
    anchors.centerIn: parent
    text: "❀"
    color: Theme.accent
    font.pixelSize: 16
    font.family: "JetBrainsMono Nerd Font"
  }
  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: picker.visible ? picker.visible = false : root.show()
  }

  Process {
    id: applyTheme
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "") console.warn("Theme switcher:", text.trim())
      }
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0)
        root.errorMessage = "Could not apply palette. Try theme-set in a terminal for details."
    }
  }

  PopupWindow {
    id: picker
    anchor.item: root
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    implicitWidth: 380
    implicitHeight: 468
    color: "transparent"
    grabFocus: true

    Rectangle {
      anchors.fill: parent
      radius: 10
      color: Theme.background

      Text {
        x: 16
        y: 14
        text: "Color scheme"
        color: Theme.text
        font.pixelSize: 15
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
      }

      Rectangle {
        x: 16
        y: 46
        width: parent.width - 32
        height: 34
        color: Theme.surface
        radius: 6

        TextInput {
          id: search
          anchors.fill: parent
          anchors.margins: 8
          color: Theme.text
          selectionColor: Theme.overlay
          font.pixelSize: 12
          font.family: "JetBrainsMono Nerd Font"
          clip: true
          Keys.onEscapePressed: picker.visible = false
          Keys.onDownPressed: schemes.forceActiveFocus()
          Text {
            visible: search.text === ""
            text: "Search palettes…"
            color: Theme.subtext
            font: search.font
          }
        }
      }

      ListView {
        id: schemes
        x: 10
        y: 88
        width: parent.width - 20
        height: 328
        clip: true
        spacing: 3
        keyNavigationEnabled: true
        model: Theme.catalog.filter(theme =>
          `${theme.name} ${theme.slug}`.toLowerCase().includes(search.text.toLowerCase()))
        Keys.onEscapePressed: picker.visible = false
        Keys.onReturnPressed: {
          if (currentIndex >= 0) root.choose(model[currentIndex])
        }

        delegate: Rectangle {
          id: row
          required property var modelData
          required property int index
          width: schemes.width
          height: 48
          radius: 6
          color: row.modelData.slug === Theme.current.slug ? Theme.surface
            : choice.containsMouse || ListView.isCurrentItem && schemes.activeFocus ? Theme.overlay : "transparent"

          Text {
            x: 10
            y: 5
            width: parent.width - 42
            elide: Text.ElideRight
            text: row.modelData.name
            color: Theme.text
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            y: 5
            text: row.modelData.slug === Theme.current.slug ? "✓" : ""
            color: Theme.accent
            font.pixelSize: 12
          }
          Row {
            x: 10
            y: 27
            spacing: 4
            Repeater {
              model: row.modelData.swatches
              delegate: Rectangle {
                required property string modelData
                width: 26
                height: 12
                radius: 3
                color: modelData
              }
            }
          }
          MouseArea {
            id: choice
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: !applyTheme.running
            onClicked: root.choose(row.modelData)
          }
        }
      }

      Text {
        x: 16
        y: 426
        width: parent.width - 32
        height: 32
        elide: Text.ElideRight
        maximumLineCount: 2
        wrapMode: Text.Wrap
        text: root.errorMessage || (applyTheme.running ? "Applying…" : `Selected: ${Theme.current.name}`)
        color: root.errorMessage !== "" ? Theme.red : Theme.subtext
        font.pixelSize: 11
        font.family: "JetBrainsMono Nerd Font"
      }
    }
  }
}
