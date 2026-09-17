pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Niri's event stream supplies a full snapshot on connection, then updates.
// Workspace IDs remain stable when Niri renumbers or moves workspaces.
Singleton {
    id: root
    readonly property bool active: Quickshell.env("NIRI_SOCKET") !== ""
    property var workspaces: []
    property var windows: []
    readonly property int activeId: workspaces.find(w => w.is_focused)?.id ?? 0
    readonly property string focusedAddress: String(windows.find(w => w.is_focused)?.id ?? "")
    readonly property var occupiedIds: workspaces.filter(w => w.active_window_id !== null).map(w => w.id)
    readonly property var visibleIds: workspaces.map(w => w.id)
    readonly property int maximum: workspaces.length
    property bool watchClients: false
    property var binds: []
    readonly property var modifierNames: [
        {bit: 64, name: "SUPER"}, {bit: 4, name: "CTRL"},
        {bit: 8, name: "ALT"}, {bit: 1, name: "SHIFT"}
    ]
    readonly property var monitors: Quickshell.screens.map(s => ({
        name: s.name, description: s.name, width: s.width, height: s.height,
        x: s.x, y: s.y, reserved: [0, 0, 0, 0]
    }))
    // Retain the shape consumed by the existing launcher and overview.
    readonly property var clients: windows.map(w => ({
        address: String(w.id), class: w.app_id ?? "", title: w.title ?? "",
        workspace: {id: w.workspace_id}, mapped: true, floating: w.is_floating,
        fullscreen: w.is_fullscreen ? 1 : 0,
        at: w.layout?.pos_in_scrolling_layout ?? [0, 0],
        size: w.layout?.window_size ?? [640, 480]
    }))

    function onOutput(name: string): var {
        return workspaces.filter(w => !name || w.output === name).sort((a, b) => a.idx - b.idx)
    }
    function isOccupied(id: int): bool { return occupiedIds.indexOf(id) >= 0 }
    function isVisible(id: int): bool { return visibleIds.indexOf(id) >= 0 }
    function clientsOn(id: int): var { return clients.filter(w => w.workspace.id === id) }
    function spell(bind: var): string { return bind.key ?? "" }
    function loadClients(): void {} // Already kept current by the event stream.
    function loadMonitors(): void {}
    function loadBinds(): void {} // Niri bindings remain in config.kdl.
    function refresh(): void {}

    function dispatch(value: var): void {
        actions.connected = false
        actions.request = JSON.stringify({Action: value})
        actions.connected = true
    }
    function focus(id: int): void { dispatch({FocusWorkspace: {reference: {Id: id}}}) }
    function focusWindow(id: string): void { dispatch({FocusWindow: {id: Number(id)}}) }
    function closeWindow(id: string): void { dispatch({CloseWindow: {id: Number(id)}}) }
    function toggleFloating(id: string): void { dispatch({ToggleWindowFloating: {id: Number(id)}}) }
    function moveClient(id: string, workspace: int): void {
        dispatch({MoveWindowToWorkspace: {window_id: Number(id), reference: {Id: workspace}, focus: false}})
    }
    // Niri controls tiled placement; overview drag-to-swap is disabled there.
    function swapWindows(id: string, target: string): void {}
    function moveFloating(id: string, x: int, y: int): void {
        dispatch({MoveFloatingWindow: {id: Number(id), x: {SetFixed: x}, y: {SetFixed: y}}})
    }

    function receive(line: string): void {
        let e
        try { e = JSON.parse(line) } catch (_) { return }
        if (e.WorkspacesChanged) workspaces = e.WorkspacesChanged.workspaces
        else if (e.WorkspaceActivated) {
            const c = e.WorkspaceActivated
            const target = workspaces.find(w => w.id === c.id)
            if (!target) return
            workspaces = workspaces.map(w => Object.assign({}, w, {
                is_active: w.output === target.output ? w.id === c.id : w.is_active,
                is_focused: c.focused ? w.id === c.id : w.is_focused
            }))
        } else if (e.WorkspaceActiveWindowChanged) {
            const c = e.WorkspaceActiveWindowChanged
            workspaces = workspaces.map(w => w.id === c.workspace_id
                ? Object.assign({}, w, {active_window_id: c.active_window_id}) : w)
        } else if (e.WorkspaceUrgencyChanged) {
            const c = e.WorkspaceUrgencyChanged
            workspaces = workspaces.map(w => w.id === c.id ? Object.assign({}, w, {is_urgent: c.urgent}) : w)
        } else if (e.WindowsChanged) windows = e.WindowsChanged.windows
        else if (e.WindowOpenedOrChanged) {
            const c = e.WindowOpenedOrChanged.window
            windows = windows.filter(w => w.id !== c.id).map(w => c.is_focused
                ? Object.assign({}, w, {is_focused: false}) : w).concat([c])
        } else if (e.WindowClosed) windows = windows.filter(w => w.id !== e.WindowClosed.id)
        else if (e.WindowFocusChanged) windows = windows.map(w => Object.assign({}, w,
            {is_focused: w.id === e.WindowFocusChanged.id}))
    }

    Socket {
        id: events
        path: Quickshell.env("NIRI_SOCKET")
        connected: root.active
        onConnectionStateChanged: {
            if (connected) write('"EventStream"\n')
            else { root.workspaces = []; root.windows = []; reconnect.restart() }
        }
        onError: reconnect.restart()
        parser: SplitParser { onRead: data => root.receive(data) }
    }
    Timer {
        id: reconnect
        interval: 2000
        onTriggered: if (root.active) events.connected = true
    }
    Socket {
        id: actions
        property string request: ""
        path: Quickshell.env("NIRI_SOCKET")
        onConnectionStateChanged: if (connected) write(request + "\n")
        parser: SplitParser {
            onRead: data => {
                const reply = JSON.parse(data)
                if (reply.Err) console.warn("Niri:", reply.Err)
                actions.connected = false
            }
        }
    }
}
