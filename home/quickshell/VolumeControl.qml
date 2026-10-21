import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Rectangle {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var audio: sink && sink.ready ? sink.audio : null
  property real wheelRemainder: 0

  implicitWidth: caption.implicitWidth + 12
  implicitHeight: 28
  radius: 0
  color: pointer.containsMouse ? Theme.surface : "transparent"

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  Text {
    id: caption
    anchors.centerIn: parent
    text: root.audio
      ? `${root.audio.muted ? "󰖁" : "󰕾"} ${Math.round(root.audio.volume * 100)}%`
      : "󰖁 --"
    color: root.audio && root.audio.muted ? Theme.red : Theme.text
    font.pixelSize: 12
    font.family: "JetBrainsMono Nerd Font"
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.audio !== null
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["desktop-volume", "mute"])
    onWheel: wheel => {
      root.wheelRemainder += wheel.angleDelta.y
      while (Math.abs(root.wheelRemainder) >= 120) {
        const direction = root.wheelRemainder > 0 ? 1 : -1
        Quickshell.execDetached(["desktop-volume", direction > 0 ? "up" : "down"])
        root.wheelRemainder -= direction * 120
      }
    }
  }
}
