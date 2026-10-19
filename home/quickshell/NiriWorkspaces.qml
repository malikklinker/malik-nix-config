import Quickshell
import Quickshell.Io
import QtQuick

Row {
  id: root
  spacing: 4

  property var workspaces: []
  readonly property var visibleWorkspaces: {
    const focused = workspaces.find(workspace => workspace.is_focused)
    return workspaces.filter(workspace => !focused || workspace.output === focused.output)
      .sort((a, b) => a.idx - b.idx)
  }

  function handleEvent(data) {
    let event
    try {
      event = JSON.parse(data)
    } catch (error) {
      console.warn("Invalid Niri workspace event:", error)
      return
    }

    if (event.WorkspacesChanged) {
      workspaces = event.WorkspacesChanged.workspaces
    } else if (event.WorkspaceActivated) {
      const change = event.WorkspaceActivated
      const active = workspaces.find(workspace => workspace.id === change.id)
      if (!active) return
      workspaces = workspaces.map(workspace => Object.assign({}, workspace, {
        is_active: workspace.output === active.output ? workspace.id === change.id : workspace.is_active,
        is_focused: change.focused ? workspace.id === change.id : workspace.is_focused
      }))
    } else if (event.WorkspaceActiveWindowChanged) {
      const change = event.WorkspaceActiveWindowChanged
      workspaces = workspaces.map(workspace => workspace.id === change.workspace_id
        ? Object.assign({}, workspace, { active_window_id: change.active_window_id }) : workspace)
    } else if (event.WorkspaceUrgencyChanged) {
      const change = event.WorkspaceUrgencyChanged
      workspaces = workspaces.map(workspace => workspace.id === change.id
        ? Object.assign({}, workspace, { is_urgent: change.urgent }) : workspace)
    }
  }

  Process {
    id: events
    command: ["niri", "msg", "--json", "event-stream"]
    running: true
    stdout: SplitParser {
      onRead: data => root.handleEvent(data)
    }
    onExited: {
      root.workspaces = []
      reconnect.start()
    }
  }

  Timer {
    id: reconnect
    interval: 2000
    onTriggered: events.running = true
  }

  Repeater {
    model: root.visibleWorkspaces

    delegate: WorkspaceButton {
      required property var modelData
      label: String(modelData.idx)
      selected: modelData.is_focused
      occupied: modelData.active_window_id !== null
      urgent: modelData.is_urgent || false
      onActivated: Quickshell.execDetached([
        "niri", "msg", "action", "focus-workspace", String(modelData.idx)
      ])
    }
  }
}
