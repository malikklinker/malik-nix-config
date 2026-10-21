pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Rectangle {
  id: root
  implicitWidth: caption.implicitWidth + 12
  implicitHeight: 28
  color: pointer.containsMouse || popup.visible ? Theme.surface : "transparent"
  property var state: ({screen: null, keyboard: null, profile: null, themeSync: true})
  property string errorMessage: ""
  property var pending: []

  function refresh() {
    if (!snapshot.running && !action.running) snapshot.running = true
  }
  function execute(verb, value) {
    if (verb === "screen" || verb === "keyboard")
      state = Object.assign({}, state, { [verb]: Number(value) })
    // Coalesce slider drags while preserving independent settings changes.
    pending = pending.filter(command => command[0] !== verb).concat([[verb, String(value)]])
    dispatch()
  }
  function dispatch() {
    if (action.running || pending.length === 0) return
    const next = pending[0]
    pending = pending.slice(1)
    errorMessage = ""
    action.command = ["desktop-hardware"].concat(next)
    action.running = true
  }
  Component.onCompleted: refresh()

  IpcHandler {
    target: "hardware"
    function open(): void { popup.visible = true; root.refresh() }
    function close(): void { popup.visible = false }
  }

  Text {
    id: caption
    anchors.centerIn: parent
    text: root.state.screen === null ? "󰖨 --" : `󰖨 ${root.state.screen}%`
    color: Theme.text
    font.pixelSize: 12
    font.family: "JetBrainsMono Nerd Font"
  }
  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: { popup.visible = !popup.visible; root.refresh() }
    onWheel: wheel => {
      if (wheel.angleDelta.y !== 0) root.execute(wheel.angleDelta.y > 0 ? "screen-up" : "screen-down", "")
    }
  }
  Process {
    id: snapshot
    command: ["desktop-hardware", "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          if (!action.running && root.pending.length === 0) root.state = JSON.parse(text)
        }
        catch (error) { root.errorMessage = "Could not read laptop controls." }
      }
    }
    onExited: (code, status) => {
      if (code !== 0) root.errorMessage = "Laptop controls are unavailable."
    }
  }
  Process {
    id: action
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim()) root.errorMessage = text.trim()
      }
    }
    onExited: (code, status) => {
      if (code !== 0 && root.errorMessage === "") root.errorMessage = "Could not apply setting."
      root.refresh()
      root.dispatch()
    }
  }
  Timer {
    interval: popup.visible ? 1500 : 15000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  PopupWindow {
    id: popup
    anchor.item: root
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    implicitWidth: 340
    implicitHeight: content.implicitHeight + 32
    color: "transparent"
    grabFocus: true

    Rectangle {
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: popup.visible = false
      color: Theme.background
      border.color: Theme.overlay
      border.width: 1

      ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 12

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Laptop controls"
            color: Theme.text
            font.pixelSize: 15
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            Layout.fillWidth: true
          }
          Controls.Button {
            text: "×"
            Accessible.name: "Close laptop controls"
            onClicked: popup.visible = false
            contentItem: Text { text: "×"; color: Theme.subtext; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter }
            background: Rectangle { color: parent.hovered ? Theme.surface : "transparent" }
          }
        }
        ControlSlider {
          Layout.fillWidth: true
          label: "Screen brightness"
          minimum: 1
          value: root.state.screen ?? 1
          available: root.state.screen !== null
          onCommitted: amount => root.execute("screen", amount)
        }
        ControlSlider {
          Layout.fillWidth: true
          label: "Keyboard lighting"
          maximum: 3
          snap: true
          valueLabels: ["Off", "Low", "Medium", "High"]
          suffix: " / 3"
          value: root.state.keyboard ?? 0
          available: root.state.keyboard !== null
          onCommitted: amount => root.execute("keyboard", amount)
        }
        Controls.CheckBox {
          Layout.fillWidth: true
          text: "Match keyboard to theme"
          checked: root.state.themeSync
          enabled: root.state.keyboard !== null
          onClicked: root.execute("theme-sync", checked ? "on" : "off")
          indicator: Rectangle {
            implicitWidth: 18
            implicitHeight: 18
            x: 0
            y: (parent.height - height) / 2
            color: parent.checked ? Theme.accent : Theme.surface
            border.color: parent.activeFocus ? Theme.text : Theme.overlay
            Text { anchors.centerIn: parent; text: "✓"; visible: parent.parent.checked; color: Theme.background }
          }
          contentItem: Text {
            text: parent.text
            leftPadding: 28
            color: Theme.text
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            verticalAlignment: Text.AlignVCenter
          }
        }
        Text {
          text: "Power profile"
          color: Theme.subtext
          font.pixelSize: 12
          font.family: "JetBrainsMono Nerd Font"
        }
        RowLayout {
          Layout.fillWidth: true
          spacing: 6
          Repeater {
            model: ["quiet", "balanced", "performance"]
            delegate: Controls.Button {
              id: profileButton
              required property string modelData
              Layout.fillWidth: true
              text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
              enabled: root.state.profile !== null
              onClicked: root.execute("profile", modelData)
              contentItem: Text {
                text: profileButton.text
                color: root.state.profile === profileButton.modelData ? Theme.background : Theme.text
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                horizontalAlignment: Text.AlignHCenter
              }
              background: Rectangle {
                color: root.state.profile === profileButton.modelData ? Theme.accent : Theme.surface
                border.width: profileButton.activeFocus ? 1 : 0
                border.color: Theme.text
              }
            }
          }
        }
        Text {
          Layout.fillWidth: true
          text: "Profiles switch automatically when power is connected or disconnected."
          color: Theme.muted
          font.pixelSize: 11
          wrapMode: Text.WordWrap
        }
        Text {
          Layout.fillWidth: true
          visible: root.errorMessage !== ""
          text: root.errorMessage
          color: Theme.red
          font.pixelSize: 11
          wrapMode: Text.WrapAnywhere
        }
      }
    }
  }
}
