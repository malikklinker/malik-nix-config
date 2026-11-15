import QtQuick
import QtQuick.Controls as Controls

Controls.Button {
  id: root
  implicitHeight: 32
  contentItem: Text {
    text: root.text
    color: root.enabled ? Theme.text : Theme.muted
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }
  background: Rectangle {
    color: root.hovered ? Theme.overlay : Theme.surface
    border.color: Theme.accent
    border.width: root.activeFocus ? 1 : 0
  }
}
