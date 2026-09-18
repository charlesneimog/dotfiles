// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T H E M E   B U T T O N                                                │
// │   toggle system application theme                                        │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell.Io

import "../../theme"
import "../../components"

IconButton {
    id: root

    property bool dark: true
    property bool themeReady: false

    function readTheme(output: string): void {
        try {
            const report = JSON.parse(output)

            if (report.alt !== "dark" && report.alt !== "light")
                throw new Error("Invalid theme")

            root.dark = report.alt === "dark"
            root.themeReady = true
        } catch (error) {
            root.themeReady = false
            console.warn("Could not read system theme:", error)
        }
    }

    icon: root.dark ? "" : ""
    enabled: root.themeReady
        && !themeQuery.running
        && !themeChange.running

    onClicked: {
        themeChange.running = true
    }

    Process {
        id: themeQuery

        command: [
            "bash",
            "-c",
            'exec "$HOME/.functions.sh" get_theme'
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: root.readTheme(text)
        }

        onExited: code => {
            if (code !== 0)
                root.themeReady = false
        }
    }

    Process {
        id: themeChange

        command: [
            "bash",
            "-c",
            'exec "$HOME/.functions.sh" change_theme'
        ]

        onExited: code => {
            if (code === 0)
                themeQuery.running = true
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true

        onTriggered: {
            if (!themeQuery.running && !themeChange.running)
                themeQuery.running = true
        }
    }
}
