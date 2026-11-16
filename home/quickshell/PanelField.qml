import QtQuick
import QtQuick.Controls as Controls

Controls.TextField {
  id: root
  implicitHeight: 34
  color: Theme.text
  placeholderTextColor: Theme.muted
  selectionColor: Theme.accent
  selectedTextColor: Theme.background
  font.family: "JetBrainsMono Nerd Font"
  font.pixelSize: 12
  background: Rectangle {
    color: Theme.surface
    border.color: root.activeFocus ? Theme.accent : Theme.overlay
    border.width: 1
  }
}
