pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Share Waybar's JSON producers and click actions, including its poll periods.
Singleton {
    id: root
    property var aurReport: null
    property var flatpakReport: null
    property string aurError: ""
    property string flatpakError: ""
    property string actionError: ""
    property real checkedAt: 0
    readonly property bool available: aurReport !== null || flatpakReport !== null
    readonly property bool checking: aurQuery.running || flatpakQuery.running
    readonly property bool busy: action.running
    readonly property int count: Number(aurReport?.alt ?? 0) + Number(flatpakReport?.alt ?? 0)
    readonly property var packages: [aurReport, flatpakReport]
        .filter(report => report && Number(report.alt) > 0)
        .reduce((rows, report) => rows.concat(report.tooltip.split("\n")), [])
    readonly property string tool: "waybar"
    readonly property string age: checkedAt > 0
        ? `${Math.max(0, Math.floor((clock.date.getTime() - checkedAt) / 60000))} min ago` : ""
    readonly property SystemClock clock: SystemClock { precision: SystemClock.Minutes }

    function subscribe(): void {}
    function release(): void {}
    function refresh(): void {
        if (!aurQuery.running) aurQuery.running = true
        if (!flatpakQuery.running) flatpakQuery.running = true
    }
    function read(text: string, source: string): void {
        try {
            const report = JSON.parse(text)
            if (!Number.isFinite(Number(report.alt)) || typeof report.tooltip !== "string")
                throw new Error("Invalid update report")
            if (source === "aur") { aurReport = report; aurError = "" }
            else { flatpakReport = report; flatpakError = "" }
            checkedAt = Date.now()
        } catch (error) {
            failed(source)
        }
    }
    function failed(source: string): void {
        const message = "Could not check updates; verify ~/.functions.sh and the package tool"
        if (source === "aur") aurError = message
        else flatpakError = message
    }
    function update(source: string): void {
        if (busy || checking || !["aur", "flatpak"].includes(source)) return
        actionError = ""
        // The old AUR helper only counts updates. Use a terminal for sudo and
        // package prompts; -e keeps a separate Ghostty process until it exits.
        action.command = ["ghostty", "-e", "bash", "-c",
            (source === "aur" ? "paru -Syu" : "flatpak update")
            + '; result=$?; printf "\\nFinished (exit %s). Press Enter to close. " "$result"; read -r; exit "$result"']
        action.running = true
    }
    Component.onCompleted: refresh()
    readonly property Timer aurTimer: Timer {
        interval: 900000; running: true; repeat: true
        onTriggered: { if (!aurQuery.running) aurQuery.running = true }
    }
    readonly property Timer flatpakTimer: Timer {
        interval: 43200000; running: true; repeat: true
        onTriggered: { if (!flatpakQuery.running) flatpakQuery.running = true }
    }
    readonly property Process aurQuery: Process {
        command: ["bash", "-c", 'command -v paru >/dev/null || exit 127; exec "$HOME/.functions.sh" get_aur_waybar_icon']
        onExited: (code) => { if (code !== 0) root.failed("aur") }
        stdout: StdioCollector { onStreamFinished: root.read(text, "aur") }
    }
    readonly property Process flatpakQuery: Process {
        command: ["bash", "-c", 'command -v flatpak >/dev/null || exit 127; exec "$HOME/.functions.sh" get_flatpak_waybar_icon']
        onExited: (code) => { if (code !== 0) root.failed("flatpak") }
        stdout: StdioCollector { onStreamFinished: root.read(text, "flatpak") }
    }
    readonly property Process action: Process {
        onRunningChanged: if (!running) root.refresh()
        onStarted: root.actionError = ""
        onExited: (code) => {
            if (code !== 0) root.actionError = "The update terminal exited with an error; check its output."
        }
    }
}
