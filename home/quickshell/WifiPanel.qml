pragma ComponentBehavior: Bound

import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

ColumnLayout {
  id: root
  property bool active: false
  readonly property var device: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null
  readonly property var networks: device ? device.networks.values.slice().sort((a, b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength) : []
  property var selected: null
  property string errorMessage: ""
  property string notice: ""
  readonly property bool enterprise: selected && [WifiSecurityType.WpaEap, WifiSecurityType.Wpa2Eap].includes(selected.security)
  readonly property bool psk: selected && [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(selected.security)
  spacing: 8

  function updateScanner() { if (device) device.scannerEnabled = active && Networking.wifiEnabled }
  onActiveChanged: {
    updateScanner()
    if (!active) { password.clear(); selected = null; errorMessage = ""; notice = "" }
  }
  onDeviceChanged: updateScanner()
  Component.onCompleted: updateScanner()
  Component.onDestruction: { if (device) device.scannerEnabled = false }
  Connections {
    target: Networking
    function onWifiEnabledChanged() { root.updateScanner() }
  }
  Connections {
    target: root.selected
    function onConnectionFailed(reason) {
      root.notice = ""
      root.errorMessage = `Connection failed: ${ConnectionFailReason.toString(reason)}. Check the credentials and try again.`
    }
    function onConnectedChanged() {
      if (root.selected?.connected) { root.notice = "Connected."; root.errorMessage = ""; password.clear() }
    }
  }
  RowLayout {
    Layout.fillWidth: true
    Text {
      Layout.fillWidth: true
      text: !root.device ? "No Wi-Fi adapter" : !Networking.wifiHardwareEnabled ? "Wi-Fi is hardware blocked" : Networking.wifiEnabled ? "Nearby networks" : "Wi-Fi is off"
      color: Theme.subtext
      font.pixelSize: 12
    }
    PanelButton {
      text: Networking.wifiEnabled ? "Turn off" : "Turn on"
      enabled: root.device !== null && Networking.wifiHardwareEnabled
      onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
    }
  }
  Controls.ScrollView {
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(210, Math.max(42, networkList.implicitHeight))
    clip: true
    contentWidth: availableWidth
    ColumnLayout {
      id: networkList
      width: parent.width
      spacing: 4
      Repeater {
        model: Networking.wifiEnabled ? root.networks : []
        delegate: PanelButton {
          id: networkButton
          required property var modelData
          Layout.fillWidth: true
          text: `${modelData.connected ? "✓ " : ""}${modelData.name || "Hidden network"}  ·  ${Math.round(modelData.signalStrength * 100)}%`
          enabled: modelData.name !== "" && !enterpriseAction.running
          onClicked: {
            root.selected = modelData
            root.errorMessage = ""
            root.notice = ""
            forget.text = "Forget"
            password.clear()
            identity.clear()
            anonymous.clear()
            domain.clear()
            ca.text = "/etc/ssl/certs/ca-certificates.crt"
          }
        }
      }
      Text {
        visible: !Networking.wifiEnabled || root.networks.length === 0
        text: Networking.wifiEnabled ? "Looking for networks…" : "Enable Wi-Fi to scan."
        color: Theme.muted
        font.pixelSize: 12
      }
    }
  }
  Text {
    Layout.fillWidth: true
    visible: root.selected !== null
    text: root.selected?.name ?? ""
    color: Theme.accent
    font.pixelSize: 13
    elide: Text.ElideRight
  }
  ColumnLayout {
    Layout.fillWidth: true
    visible: root.enterprise && root.selected !== null && !root.selected.connected
    spacing: 6
    Text {
      Layout.fillWidth: true
      text: "Use your institution’s EAP, CA and server domain settings."
      color: Theme.subtext
      font.pixelSize: 11
      wrapMode: Text.WordWrap
    }
    RowLayout {
      Layout.fillWidth: true
      PanelChoice { id: eap; Layout.fillWidth: true; model: ["PEAP", "TTLS"] }
      PanelChoice { id: phase2; Layout.fillWidth: true; model: eap.currentIndex === 0 ? ["MSCHAPv2"] : ["PAP", "MSCHAPv2", "MSCHAP", "CHAP"] }
    }
    PanelField { id: identity; Layout.fillWidth: true; placeholderText: "Username / identity (user@institution)"; Accessible.name: "Enterprise username" }
    PanelField { id: anonymous; Layout.fillWidth: true; placeholderText: "Anonymous identity (if required)"; Accessible.name: "Anonymous identity" }
    PanelField { id: domain; Layout.fillWidth: true; placeholderText: "Authentication server domain"; Accessible.name: "Certificate server domain" }
    PanelField { id: ca; Layout.fillWidth: true; text: "/etc/ssl/certs/ca-certificates.crt"; placeholderText: "CA certificate file path"; Accessible.name: "CA certificate path" }
  }
  PanelField {
    id: password
    Layout.fillWidth: true
    visible: root.selected !== null && !root.selected.connected && (root.psk || root.enterprise)
    echoMode: Controls.TextField.Password
    placeholderText: root.selected?.known ? "Password (leave blank to use saved profile)" : "Password"
    Accessible.name: "Wi-Fi password"
    enabled: !enterpriseAction.running
  }
  RowLayout {
    visible: root.selected !== null
    Layout.fillWidth: true
    PanelButton {
      Layout.fillWidth: true
      text: enterpriseAction.running || root.selected?.stateChanging ? "Connecting…" : root.selected?.connected ? "Disconnect" : "Connect"
      enabled: Networking.wifiEnabled && !enterpriseAction.running && !root.selected?.stateChanging
      onClicked: {
        if (!root.selected) return
        root.errorMessage = ""
        root.notice = ""
        if (root.selected.connected) root.selected.disconnect()
        else if (root.selected.known && password.text === "") root.selected.connect()
        else if (root.enterprise) {
          enterpriseAction.payload = JSON.stringify({ssid: root.selected.name, device: root.device.name,
            identity: identity.text, anonymous: anonymous.text, domain: domain.text, ca: ca.text,
            eap: eap.currentText.toLowerCase(), phase2: phase2.currentText.toLowerCase(), password: password.text})
          enterpriseAction.running = true
          password.clear()
        } else if (root.psk && password.text !== "") {
          root.selected.connectWithPsk(password.text)
          password.clear()
        } else if (root.psk && !root.selected.known) root.errorMessage = "Enter the network password."
        else if ([WifiSecurityType.Open, WifiSecurityType.Owe].includes(root.selected.security)) root.selected.connect()
        else root.errorMessage = "This network’s authentication method is not supported by this popup."
      }
    }
    PanelButton {
      id: forget
      text: "Forget"
      visible: root.selected?.known ?? false
      enabled: !enterpriseAction.running && !root.selected?.stateChanging
      onClicked: {
        if (text !== "Confirm forget") { text = "Confirm forget"; return }
        root.selected.forget()
        text = "Forget"
      }
    }
  }
  Text {
    Layout.fillWidth: true
    visible: root.notice !== "" || root.errorMessage !== ""
    text: root.errorMessage || root.notice
    color: root.errorMessage ? Theme.red : Theme.subtext
    font.pixelSize: 12
    wrapMode: Text.WrapAnywhere
  }
  Process {
    id: enterpriseAction
    property string payload: ""
    command: ["desktop-network-agent", "enterprise"]
    stdinEnabled: true
    onStarted: { write(payload + "\n"); payload = "" }
    stderr: StdioCollector { onStreamFinished: { if (text.trim()) root.errorMessage = text.trim() } }
    onExited: (code, status) => {
      payload = ""
      if (code !== 0 && root.errorMessage === "") root.errorMessage = "Could not configure enterprise Wi-Fi."
      if (code === 0) root.notice = "Profile saved; connecting…"
    }
  }
}
