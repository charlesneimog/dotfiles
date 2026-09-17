pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Query real MPRIS players. playerctld is a proxy which returns D-Bus errors
// while empty; excluding it before discovery avoids those GetAll warnings.
Singleton {
    id: root
    property var players: []
    readonly property var active: players.find(player => player.status === "Playing") ?? players[0] ?? null
    readonly property bool available: active !== null
    readonly property bool playing: active?.status === "Playing"
    readonly property string title: active?.title ?? ""
    readonly property string artist: active?.artist ?? ""
    readonly property string album: active?.album ?? ""
    readonly property string artUrl: active?.artUrl ?? ""
    readonly property string identity: active?.name ?? ""
    readonly property real length: active?.length ?? 0
    readonly property real position: active?.position ?? 0
    readonly property bool seekable: length > 0
    readonly property real progress: seekable ? Math.max(0, Math.min(1, position / length)) : 0
    readonly property bool canNext: available
    readonly property bool canPrevious: available
    readonly property bool canToggle: available
    readonly property bool canSeek: available && seekable
    property int watchers: 0
    function subscribe(): void { watchers++; refresh() }
    function release(): void { watchers = Math.max(0, watchers - 1) }
    function refresh(): void { if (!query.running) query.running = true }
    Component.onCompleted: refresh()

    readonly property Timer poll: Timer {
        interval: root.watchers > 0 && root.playing ? 1000 : 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
    readonly property Process query: Process {
        // Record and field separators keep quotes, tabs and newlines in track
        // metadata intact without constructing JSON from unescaped strings.
        command: ["playerctl", "--ignore-player=playerctld", "--all-players",
            "--format", "{{playerInstance}}\u001f{{playerName}}\u001f{{status}}\u001f{{title}}\u001f{{artist}}\u001f{{album}}\u001f{{mpris:artUrl}}\u001f{{mpris:length}}\u001f{{position}}\u001e",
            "metadata"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.players = text.split("\u001e").map(record => record.trim().split("\u001f"))
                    .filter(fields => fields.length === 9 && fields[0] !== "playerctld")
                    .map(fields => ({ id: fields[0], name: fields[1], status: fields[2],
                        title: fields[3], artist: fields[4], album: fields[5], artUrl: fields[6],
                        length: Math.max(0, Number(fields[7]) || 0) / 1000000,
                        position: Math.max(0, Number(fields[8]) || 0) / 1000000 }))
            }
        }
    }
    readonly property Process action: Process { onExited: root.refresh() }
    function run(command: string, argument: string): void {
        if (!root.active || action.running) return
        action.command = ["playerctl", "--ignore-player=playerctld", "--player", root.active.id, command]
            .concat(argument ? [argument] : [])
        action.running = true
    }
    function toggle(): void { run("play-pause", "") }
    function next(): void { run("next", "") }
    function previous(): void { run("previous", "") }
    function seek(fraction: real): void {
        if (canSeek) run("position", String(Math.max(0, Math.min(1, fraction)) * length))
    }
}
