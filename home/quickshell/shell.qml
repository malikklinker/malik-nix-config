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
    color: "#1e1e2e"
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    spacing: 12

    Text {
      text: "❀"
      color: "#cba6f7"
      font.pixelSize: 16
      font.family: "JetBrainsMono Nerd Font"
    }

    Text {
      text: "zephyrus"
      color: "#cdd6f4"
      font.pixelSize: 13
      font.bold: true
      font.family: "JetBrainsMono Nerd Font"
    }

    Rectangle {
      Layout.preferredWidth: 1
      Layout.preferredHeight: 16
      color: "#45475a"
    }

    Loader {
      source: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
        ? "HyprlandWorkspaces.qml"
        : Quickshell.env("NIRI_SOCKET") !== "" ? "NiriWorkspaces.qml" : ""
    }

    Item { Layout.fillWidth: true }

    VolumeControl {}

    Text {
      text: UPower.displayDevice.ready
        ? `${Math.round(UPower.displayDevice.percentage * 100)}%`
        : "--%"
      color: "#a6adc8"
      font.pixelSize: 12
      font.family: "JetBrainsMono Nerd Font"
    }

    Text {
      color: "#cdd6f4"
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
      color: powerMouse.containsMouse ? "#45475a" : "transparent"

      Text {
        anchors.centerIn: parent
        text: "⏻"
        color: "#f38ba8"
        font.pixelSize: 18
        font.family: "JetBrainsMono Nerd Font"
      }

      MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
          confirmAction = ""
          powerMenu.visible = !powerMenu.visible
        }
      }
    }

    PopupWindow {
      id: powerMenu
      anchor.item: powerButton
      anchor.edges: Edges.Bottom | Edges.Right
      anchor.gravity: Edges.Bottom | Edges.Right
      width: 190
      height: menuColumn.implicitHeight + 20
      visible: false
      grabFocus: true

      Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#1e1e2e"
        border.color: "#45475a"
        border.width: 1

        Column {
          id: menuColumn
          anchors.fill: parent
          anchors.margins: 10
          spacing: 4

          Text {
            visible: confirmAction !== ""
            width: parent.width
            height: visible ? 28 : 0
            verticalAlignment: Text.AlignVCenter
            text: `Confirm ${confirmAction}?`
            color: "#f9e2af"
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
          }

          Repeater {
            model: confirmAction === ""
              ? ["Lock", "Suspend", "Restart…", "Shut down…"]
              : ["Cancel", `Confirm ${confirmAction}`]

            delegate: Rectangle {
              required property string modelData
              width: menuColumn.width
              height: 32
              radius: 6
              color: actionMouse.containsMouse ? "#313244" : "transparent"

              Text {
                anchors.fill: parent
                anchors.leftMargin: 10
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: modelData.startsWith("Confirm") ? "#f38ba8" : "#cdd6f4"
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
              }

              MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                  if (confirmAction !== "") {
                    if (modelData === "Cancel") {
                      confirmAction = ""
                      return
                    }
                    Quickshell.execDetached(["systemctl", confirmAction === "Restart" ? "reboot" : "poweroff"])
                    powerMenu.visible = false
                    confirmAction = ""
                  } else if (modelData === "Restart…") {
                    confirmAction = "Restart"
                  } else if (modelData === "Shut down…") {
                    confirmAction = "Shut down"
                  } else {
                    Quickshell.execDetached(modelData === "Lock"
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

    property string confirmAction: ""
  }
}
