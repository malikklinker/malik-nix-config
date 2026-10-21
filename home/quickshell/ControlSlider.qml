pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls

Column {
  id: root
  required property string label
  required property real value
  property int minimum: 0
  property int maximum: 100
  property string suffix: "%"
  property bool available: true
  property bool snap: false
  property var valueLabels: []
  signal committed(int amount)
  spacing: 4

  Text {
    width: parent.width
    text: `${root.label}    ${root.available ? (root.valueLabels[Math.round(slider.value)] ?? Math.round(slider.value) + root.suffix) : "Unavailable"}`
    color: root.available ? Theme.text : Theme.muted
    font.pixelSize: 12
    font.family: "JetBrainsMono Nerd Font"
  }

  Controls.Slider {
    id: slider
    width: parent.width
    height: 28
    from: root.minimum
    to: root.maximum
    stepSize: 1
    snapMode: root.snap ? Controls.Slider.SnapAlways : Controls.Slider.NoSnap
    enabled: root.available
    Accessible.name: root.label
    onMoved: commitTimer.restart()
    Binding {
      target: slider
      property: "value"
      value: root.value
      when: !slider.pressed && !commitTimer.running
      restoreMode: Binding.RestoreNone
    }
    background: Rectangle {
      x: slider.leftPadding
      y: slider.topPadding + slider.availableHeight / 2 - height / 2
      width: slider.availableWidth
      height: 4
      color: Theme.overlay
      Rectangle {
        width: slider.visualPosition * parent.width
        height: parent.height
        color: slider.enabled ? Theme.accent : Theme.muted
      }
      Repeater {
        model: root.snap ? root.maximum - root.minimum + 1 : 0
        delegate: Rectangle {
          required property int index
          x: 6 + index * (parent.width - 12) / (root.maximum - root.minimum) - width / 2
          y: (parent.height - height) / 2
          width: 4
          height: 10
          color: Theme.subtext
        }
      }
    }
    handle: Rectangle {
      x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
      y: slider.topPadding + slider.availableHeight / 2 - height / 2
      width: 12
      height: 18
      color: slider.pressed ? Theme.text : Theme.accent
      border.width: slider.activeFocus ? 2 : 0
      border.color: Theme.text
    }
  }
  Timer {
    id: commitTimer
    interval: 120
    onTriggered: root.committed(Math.round(slider.value))
  }
}
