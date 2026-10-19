pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

PanelWindow {
  anchors {
    top: true
    left: true
    right: true
  }

  implicitHeight: 36
  exclusiveZone: 36

  Rectangle {
    anchors.fill: parent
    color: Theme.background
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    spacing: 12

    ThemePicker {}

    Text {
      text: "zephyrus"
      color: Theme.text
      font.pixelSize: 13
      font.bold: true
      font.family: "JetBrainsMono Nerd Font"
    }

    Rectangle {
      Layout.preferredWidth: 1
      Layout.preferredHeight: 16
      color: Theme.overlay
    }

    Loader {
      source: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
        ? "HyprlandWorkspaces.qml"
        : Quickshell.env("NIRI_SOCKET") !== "" ? "NiriWorkspaces.qml" : ""
    }

    Item { Layout.fillWidth: true }

    VolumeControl {}

    Text {
      text: {
        const battery = UPower.displayDevice
        if (!battery.ready) return "--%"
        const percentage = battery.state === UPowerDeviceState.FullyCharged && battery.percentage >= 0.99
          ? 100 : Math.round(battery.percentage * 100)
        return `${Math.max(0, Math.min(100, percentage))}%`
      }
      color: Theme.subtext
      font.pixelSize: 12
      font.family: "JetBrainsMono Nerd Font"
    }

    Text {
      color: Theme.text
      font.pixelSize: 12
      font.family: "JetBrainsMono Nerd Font"
      text: Qt.formatDateTime(clock.date, "ddd MMM d  h:mm AP")
    }

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }

    Rectangle {
      id: powerButton
      Layout.preferredWidth: 28
      Layout.preferredHeight: 28
      radius: 6
      color: powerMouse.containsMouse ? Theme.overlay : "transparent"

      Text {
        anchors.centerIn: parent
        text: "⏻"
        color: Theme.red
        font.pixelSize: 18
        font.family: "JetBrainsMono Nerd Font"
      }

      MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          powerMenu.confirmAction = ""
          powerMenu.visible = !powerMenu.visible
        }
      }
    }

    PopupWindow {
      id: powerMenu
      property string confirmAction: ""

      anchor.item: powerButton
      anchor.edges: Edges.Bottom | Edges.Right
      anchor.gravity: Edges.Bottom | Edges.Left
      implicitWidth: 190
      implicitHeight: menuColumn.implicitHeight + 20
      color: "transparent"
      visible: false
      grabFocus: true

      Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.background

        Column {
          id: menuColumn
          anchors.fill: parent
          anchors.margins: 10
          spacing: 4

          Text {
            visible: powerMenu.confirmAction !== ""
            width: parent.width
            height: visible ? 28 : 0
            verticalAlignment: Text.AlignVCenter
            text: `Confirm ${powerMenu.confirmAction}?`
            color: Theme.yellow
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
          }

          Repeater {
            model: powerMenu.confirmAction === ""
              ? ["Lock", "Suspend", "Restart…", "Shut down…"]
              : ["Cancel", `Confirm ${powerMenu.confirmAction}`]

            delegate: Rectangle {
              id: actionButton
              required property string modelData
              width: menuColumn.width
              height: 32
              radius: 6
              color: actionMouse.containsMouse ? Theme.surface : "transparent"

              Text {
                anchors.fill: parent
                anchors.leftMargin: 10
                verticalAlignment: Text.AlignVCenter
                text: actionButton.modelData
                color: actionButton.modelData.startsWith("Confirm") ? Theme.red : Theme.text
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
              }

              MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (powerMenu.confirmAction !== "") {
                    if (actionButton.modelData === "Cancel") {
                      powerMenu.confirmAction = ""
                      return
                    }
                    Quickshell.execDetached(["systemctl", powerMenu.confirmAction === "Restart" ? "reboot" : "poweroff"])
                    powerMenu.visible = false
                    powerMenu.confirmAction = ""
                  } else if (actionButton.modelData === "Restart…") {
                    powerMenu.confirmAction = "Restart"
                  } else if (actionButton.modelData === "Shut down…") {
                    powerMenu.confirmAction = "Shut down"
                  } else {
                    Quickshell.execDetached(actionButton.modelData === "Lock"
                      ? ["swaylock"]
                      : ["systemctl", "suspend"])
                    powerMenu.visible = false
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
