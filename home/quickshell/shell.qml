import Quickshell
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

    Text {
      text: Quickshell.env("XDG_CURRENT_DESKTOP") || "Wayland"
      color: "#a6adc8"
      font.pixelSize: 12
      font.family: "JetBrainsMono Nerd Font"
    }

    Item { Layout.fillWidth: true }

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
  }
}
