pragma ComponentBehavior: Bound

import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

ColumnLayout {
  id: root
  property bool active: false
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var devices: adapter ? adapter.devices.values.slice().sort((a, b) => Number(b.connected) - Number(a.connected) || Number(b.paired) - Number(a.paired) || a.name.localeCompare(b.name)) : []
  property var selected: null
  property var prompt: ({type: ""})
  property string errorMessage: ""
  property string notice: ""
  spacing: 8

  function stopScan() { if (adapter) adapter.discovering = false }
  onActiveChanged: {
    if (active && adapter?.enabled) {
      adapter.discovering = true
      scanTimeout.restart()
    } else if (!active) {
      stopScan()
      if (action.running && action.verb === "pair") action.write(JSON.stringify({cancel: true}) + "\n")
      pin.clear()
      prompt = {type: ""}
    }
  }
  Component.onDestruction: stopScan()
  function execute(verb) {
    if (!selected || action.running) return
    errorMessage = ""
    notice = ""
    prompt = {type: ""}
    action.verb = verb
    action.command = ["desktop-network-agent", verb, selected.dbusPath]
    action.running = true
  }
  function respond(accept) {
    action.write(JSON.stringify({accept: accept, value: pin.text}) + "\n")
    pin.clear()
    prompt = {type: ""}
  }
  RowLayout {
    Layout.fillWidth: true
    PanelButton {
      Layout.fillWidth: true
      text: root.adapter?.enabled ? "Turn Bluetooth off" : "Turn Bluetooth on"
      enabled: root.adapter !== null && !action.running
      onClicked: root.adapter.enabled = !root.adapter.enabled
    }
    PanelButton {
      text: root.adapter?.discovering ? "Stop scan" : "Scan"
      enabled: !!root.adapter?.enabled && !action.running
      onClicked: {
        root.adapter.discovering = !root.adapter.discovering
        if (root.adapter.discovering) scanTimeout.restart()
      }
    }
  }
  Timer { id: scanTimeout; interval: 30000; onTriggered: root.stopScan() }
  Text {
    Layout.fillWidth: true
    text: !root.adapter ? "No Bluetooth adapter" : root.adapter.state === BluetoothAdapterState.Blocked ? "Bluetooth is hardware blocked" : !root.adapter.enabled ? "Bluetooth is off" : root.adapter.discovering ? "Scanning… put your device in pairing mode." : "Saved and nearby devices"
    color: Theme.subtext
    font.pixelSize: 12
    wrapMode: Text.WordWrap
  }
  Controls.ScrollView {
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(250, Math.max(42, deviceList.implicitHeight))
    clip: true
    contentWidth: availableWidth
    ColumnLayout {
      id: deviceList
      width: parent.width
      spacing: 4
      Repeater {
        model: root.adapter?.enabled ? root.devices : []
        delegate: PanelButton {
          required property var modelData
          Layout.fillWidth: true
          text: `${modelData.connected ? "✓ " : ""}${modelData.name || modelData.address}  ·  ${modelData.connected ? "Connected" : modelData.paired ? "Saved" : "New"}`
          enabled: !action.running
          onClicked: { root.selected = modelData; root.errorMessage = ""; root.notice = ""; forget.text = "Forget" }
        }
      }
      Text {
        visible: root.devices.length === 0 && !!root.adapter?.enabled
        text: "No devices yet. Use Scan to find one."
        color: Theme.muted
        font.pixelSize: 12
      }
    }
  }
  Text {
    Layout.fillWidth: true
    visible: root.selected !== null
    text: root.selected ? `${root.selected.name} · ${root.selected.address}${root.selected.batteryAvailable ? ` · ${Math.round(root.selected.battery * 100)}%` : ""}` : ""
    color: Theme.accent
    font.pixelSize: 12
    wrapMode: Text.WordWrap
  }
  RowLayout {
    Layout.fillWidth: true
    visible: root.selected !== null
    PanelButton {
      Layout.fillWidth: true
      text: action.running ? "Working…" : root.selected?.connected ? "Disconnect" : root.selected?.paired ? "Connect" : "Pair & connect"
      enabled: !!root.adapter?.enabled && !action.running
      onClicked: root.execute(root.selected.connected ? "disconnect" : root.selected.paired ? "connect" : "pair")
    }
    PanelButton {
      id: forget
      text: "Forget"
      visible: root.selected?.paired ?? false
      enabled: !action.running
      onClicked: {
        if (text !== "Confirm forget") { text = "Confirm forget"; return }
        root.execute("forget")
        text = "Forget"
      }
    }
  }
  Text {
    Layout.fillWidth: true
    visible: root.prompt.type !== ""
    text: root.prompt.type === "confirm" ? `Does ${root.prompt.code} match the code on your device?`
      : root.prompt.type === "display" ? `Type ${root.prompt.code} on your Bluetooth device, then press Enter.`
      : root.prompt.type === "authorize" ? "Allow this device to pair / use the requested service?"
      : "Enter the PIN / passkey shown on your device."
    color: Theme.text
    font.pixelSize: 13
    wrapMode: Text.WordWrap
  }
  PanelField {
    id: pin
    Layout.fillWidth: true
    visible: ["pin", "passkey"].includes(root.prompt.type)
    placeholderText: "PIN / passkey"
    Accessible.name: "Bluetooth pairing PIN or passkey"
    maximumLength: root.prompt.type === "passkey" ? 6 : 16
    onAccepted: root.respond(true)
  }
  RowLayout {
    Layout.fillWidth: true
    visible: root.prompt.type !== "" && root.prompt.type !== "display"
    PanelButton { Layout.fillWidth: true; text: "Accept"; onClicked: root.respond(true) }
    PanelButton { text: "Reject"; onClicked: root.respond(false) }
  }
  PanelButton {
    visible: action.running && action.verb === "pair"
    text: "Cancel pairing"
    onClicked: action.write(JSON.stringify({cancel: true}) + "\n")
  }
  Text {
    Layout.fillWidth: true
    visible: root.errorMessage !== "" || root.notice !== ""
    text: root.errorMessage || root.notice
    color: root.errorMessage ? Theme.red : Theme.subtext
    font.pixelSize: 12
    wrapMode: Text.WrapAnywhere
  }
  Process {
    id: action
    property string verb: ""
    stdinEnabled: true
    stdout: SplitParser {
      onRead: data => {
        try {
          const message = JSON.parse(data)
          root.prompt = message.type === "cancel" ? {type: ""} : message
        } catch (error) { root.errorMessage = "Could not read pairing request." }
      }
    }
    stderr: StdioCollector { onStreamFinished: { if (text.trim()) root.errorMessage = text.trim() } }
    onExited: (code, status) => {
      root.prompt = {type: ""}
      pin.clear()
      if (code !== 0 && root.errorMessage === "") root.errorMessage = "Bluetooth action failed."
      if (code === 0) root.notice = verb === "forget" ? "Device forgotten." : verb === "disconnect" ? "Disconnected." : "Connected."
    }
  }
}
