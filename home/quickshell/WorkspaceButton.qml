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
  radius: 0
  color: selected ? Theme.accent : pointer.containsMouse ? Theme.overlay : "transparent"
  border.width: urgent && !selected ? 1 : 0
  border.color: Theme.red

  Text {
    id: caption
    anchors.centerIn: parent
    text: root.label
    color: root.selected ? Theme.background : root.occupied ? Theme.text : Theme.muted
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
