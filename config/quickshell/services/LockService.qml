pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Hyprlock owns the lock and authentication, independently of shell reloads.
// Niri publishes logind's LockedHint only after the session is covered.
Singleton {
    id: root
    property bool secure: false
    readonly property bool locked: secure
    property bool requested: false

    function lock(): void {
        if (root.secure || root.requested) return
        root.requested = true
        Quickshell.execDetached(["sh", "-c",
            'pgrep -xu "$(id -u)" hyprlock >/dev/null || exec hyprlock --grace 0'])
        root.query.running = true
        root.giveUp.restart()
    }

    readonly property Timer giveUp: Timer {
        interval: 5000
        onTriggered: root.requested = false
    }
    readonly property Timer poll: Timer {
        interval: 250
        repeat: true
        running: root.requested || root.secure
        onTriggered: { if (!root.query.running) root.query.running = true }
    }
    readonly property Process query: Process {
        command: ["loginctl", "show-session", Quickshell.env("XDG_SESSION_ID") || "self",
            "--property=LockedHint", "--value"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.secure = text.trim() === "yes"
                if (root.secure) {
                    root.requested = false
                    root.giveUp.stop()
                }
            }
        }
    }
}
