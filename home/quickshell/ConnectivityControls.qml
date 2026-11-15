pragma ComponentBehavior: Bound

import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: root
  property bool active: false
  signal requested(string mode)
  readonly property var wifi: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null
  spacing: 4

  Repeater {
    model: ["wifi", "bluetooth"]
    delegate: RowLayout {
      id: row
      required property string modelData
      readonly property bool isWifi: modelData === "wifi"
      readonly property var adapter: row.isWifi ? root.wifi : Bluetooth.defaultAdapter
      readonly property bool powered: row.isWifi ? Networking.wifiEnabled : !!adapter?.enabled
      Layout.fillWidth: true
      spacing: 6
      PanelButton {
        Layout.fillWidth: true
        text: {
          const name = row.isWifi ? "Wi-Fi" : "Bluetooth"
          const connected = row.isWifi ? root.wifi?.networks.values.find(network => network.connected)?.name
            : Bluetooth.devices.values.filter(device => device.connected).length
          return `${name}  ·  ${!row.adapter ? "Unavailable" : !row.powered ? "Off" : connected || "On"}`
        }
        Accessible.name: row.isWifi ? "Open Wi-Fi networks" : "Open Bluetooth devices"
        onClicked: root.requested(row.modelData)
      }
      PanelButton {
        implicitWidth: 48
        text: row.powered ? "On" : "Off"
        enabled: row.adapter !== null
        Accessible.name: `Turn ${row.isWifi ? "Wi-Fi" : "Bluetooth"} ${row.powered ? "off" : "on"}`
        onClicked: {
          if (row.isWifi) Networking.wifiEnabled = !Networking.wifiEnabled
          else row.adapter.enabled = !row.adapter.enabled
        }
      }
    }
  }
}
