import Quickshell.Hyprland
import QtQuick

Row {
  id: root
  spacing: 4

  // Keep the shortcut workspaces available even when they have no windows.
  readonly property var workspaceIds: [1, 2, 3, 4, 5].concat(
    Hyprland.workspaces.values.filter(workspace => workspace.id > 5)
      .map(workspace => workspace.id))

  Repeater {
    model: root.workspaceIds

    delegate: WorkspaceButton {
      required property int modelData
      readonly property var workspace: Hyprland.workspaces.values.find(
        candidate => candidate.id === modelData) || null

      label: String(modelData)
      selected: workspace !== null && workspace.focused
      occupied: workspace !== null && workspace.toplevels.values.length > 0
      urgent: workspace !== null && workspace.urgent
      onActivated: {
        if (workspace) {
          workspace.activate()
        } else {
          Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = "${modelData}" })`
            : `workspace ${modelData}`)
        }
      }
    }
  }
}
