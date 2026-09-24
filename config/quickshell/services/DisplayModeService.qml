pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string script: Quickshell.shellPath("scripts/niri_displays.py")
    property var outputs: []
    property bool canMirror: false
    property string error: ""
    property string pending: ""
    readonly property bool busy: applyProcess.running || pending !== ""
    readonly property bool hasNotebook: outputs.some(o => /^(eDP|LVDS|DSI)/.test(o.name))
    readonly property bool hasExternal: outputs.some(o => !/^(eDP|LVDS|DSI)/.test(o.name))
    readonly property bool duplicating: mirrorProcess.running

    function refresh(): void {
        if (!reader.running && !busy) reader.running = true
    }

    function apply(mode: string): void {
        if (busy) return
        error = ""
        pending = mode
        // Stop only the mirror processes owned by this shell.
        if (mirrorProcess.running) mirrorProcess.signal(15)
        else startPending()
    }

    function startPending(): void {
        if (!pending) return
        applyProcess.mode = pending
        pending = ""
        applyProcess.running = true
    }

    readonly property Process reader: Process {
        command: ["python3", root.script, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const state = JSON.parse(text)
                    root.outputs = state.outputs
                    root.canMirror = state.canMirror
                    // Unplugging the external screen must not strand a dark
                    // notebook after choosing External only.
                    if (!root.busy && root.hasNotebook && root.outputs.length
                            && root.outputs.every(o => o.current_mode === null))
                        root.apply("notebook")
                } catch (_) { root.error = "Could not read connected monitors" }
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim() }
    }

    readonly property Process applyProcess: Process {
        property string mode: ""
        command: ["python3", root.script, "apply", mode]
        stdout: StdioCollector { id: result }
        stderr: StdioCollector { id: failure }
        onExited: code => {
            if (code !== 0) root.error = failure.text.trim() || "Could not change monitor mode"
            else if (mode === "duplicate") {
                try {
                    const state = JSON.parse(result.text)
                    mirrorProcess.command = ["python3", root.script, "mirror", state.source].concat(state.targets)
                    mirrorProcess.running = true
                } catch (_) { root.error = "Could not start screen duplication" }
            }
            root.refresh()
        }
    }

    readonly property Process mirrorProcess: Process {
        stderr: StdioCollector { id: mirrorError }
        onExited: code => {
            if (!root.pending && code !== 0)
                root.error = mirrorError.text.trim() || "Screen duplication stopped"
            root.startPending()
        }
    }

    Component.onDestruction: if (mirrorProcess.running) mirrorProcess.signal(15)

    readonly property Connections screens: Connections {
        target: Quickshell
        function onScreensChanged(): void { hotplug.restart() }
    }
    readonly property Timer hotplug: Timer {
        interval: 500
        onTriggered: root.refresh()
    }
}
