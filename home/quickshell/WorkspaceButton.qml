import QtQuick

Rectangle {
  id: root

  required property string label
  property bool selected: false
  property bool occupied: false
  property bool urgent: false
  signal activated()

  implicitWidth: Math.max(28, caption.implicitWidth + 12)
  implicitHeight: 26
  radius: 6
  color: selected ? "#cba6f7" : pointer.containsMouse ? "#45475a" : "transparent"
  border.width: urgent && !selected ? 1 : 0
  border.color: "#f38ba8"

  Text {
    id: caption
    anchors.centerIn: parent
    text: root.label
    color: root.selected ? "#1e1e2e" : root.occupied ? "#cdd6f4" : "#6c7086"
    font.pixelSize: 12
    font.bold: root.selected
    font.family: "JetBrainsMono Nerd Font"
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()
  }
}
