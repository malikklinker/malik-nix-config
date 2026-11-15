pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls

Controls.ComboBox {
  id: root
  implicitHeight: 32
  contentItem: Text {
    text: root.displayText
    color: Theme.text
    leftPadding: 8
    rightPadding: 24
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }
  background: Rectangle {
    color: Theme.surface
    border.color: root.activeFocus ? Theme.accent : Theme.overlay
    border.width: 1
  }
  indicator: Text {
    x: root.width - width - 8
    anchors.verticalCenter: parent.verticalCenter
    text: "▾"
    color: Theme.subtext
  }
  delegate: Controls.ItemDelegate {
    required property int index
    required property string modelData
    width: root.width
    text: modelData
    contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 12 }
    background: Rectangle { color: parent.hovered ? Theme.overlay : Theme.surface }
  }
  popup: Controls.Popup {
    y: root.height
    width: root.width
    padding: 1
    implicitHeight: contentItem.implicitHeight + 2
    contentItem: ListView {
      clip: true
      implicitHeight: contentHeight
      model: root.popup.visible ? root.delegateModel : null
      currentIndex: root.highlightedIndex
    }
    background: Rectangle { color: Theme.surface; border.color: Theme.overlay }
  }
}
