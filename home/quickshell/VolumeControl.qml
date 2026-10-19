import Quickshell.Services.Pipewire
import QtQuick

Rectangle {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var audio: sink && sink.ready ? sink.audio : null

  implicitWidth: caption.implicitWidth + 12
  implicitHeight: 28
  radius: 6
  color: pointer.containsMouse ? Theme.surface : "transparent"

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  Text {
    id: caption
    anchors.centerIn: parent
    text: root.audio
      ? root.audio.muted ? "󰖁 Muted" : `󰕾 ${Math.round(root.audio.volume * 100)}%`
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
    onClicked: root.audio.muted = !root.audio.muted
    onWheel: wheel => {
      const steps = wheel.angleDelta.y / 120
      root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + steps * 0.05))
    }
  }
}
