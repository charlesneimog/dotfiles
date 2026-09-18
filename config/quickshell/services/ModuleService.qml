// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   M O D U L E   S E R V I C E                                            │
// │   module catalogue · activity and open panel state                       │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQml
import QtQuick
import Quickshell

import "../theme"

// The bar's catalogue: what each module is, its glyph and figure, whether this
// machine can show it, and which detail is open.
//
// A module is a chip on the bar that opens a detail in the island. Detail
// sizes are declared here because the island has to reach that size before
// the detail exists. A button has no detail; it opens one of the panels.
//
// Adding a module: a file in bar/modules, a row in `catalogue` and a line in
// Module.qml. Adding a button: a row in `buttons`.
Singleton {
    id: root

    //   bar      whether it can go on the bar (board, deck and arcade live on
    //            the desktop and behind their panels instead)
    //   desk     false for the one module with no desktop face
    //   width    detail size
    //   height
    //
    // The chip look is global (`Config.chipShape`, `chipFigure`);
    readonly property var catalogue: [
        { id: "planify",       name: "Planify",        bar: true,  width: 0,   height: 0 },
        { id: "media",         name: "Media",          bar: true,  width: 380, height: 150 },
        { id: "timer",         name: "Timer",          bar: true,  width: 348, height: 116 },
        { id: "battery",       name: "Battery",        bar: true,  width: 320, height: 132 },
        { id: "bluetooth",     name: "Bluetooth",      bar: true,  width: 356, height: 132 },
        { id: "network",       name: "Network",        bar: true,  width: 356, height: 132 },
        { id: "volume",        name: "Volume",         bar: true,  width: 340, height: 116 },
        { id: "brightness",    name: "Brightness",     bar: true,  width: 340, height: 100 },
        { id: "notifications", name: "Notifications",  bar: true,  desk: false, width: 380, height: 340 },
        { id: "weather",       name: "Weather",        bar: true,  width: 380, height: 150 },
        { id: "updates",       name: "Updates",        bar: true,  width: 356, height: 132 },
        { id: "calendar",      name: "Calendar",       bar: true,  width: 340, height: 330 },
        { id: "photo",         name: "Photo",          bar: false, width: 356, height: 150 },
        { id: "clock",         name: "Clock",          bar: false, width: 140, height: Theme.capsuleHeight }
    ]

    function entry(id: string): var {
        return root.catalogue.find(item => item.id === id) ?? root.catalogue[0]
    }

    // ── BUTTONS ─────────────────────────────────────────────────────────────
    //
    // Open one of the island's panels. Same glyphs as the control centre's
    // shortcuts. Alone in a capsule, a button is drawn as a circle.
    readonly property var buttons: ({
        launcher: { name: "Search",         glyph: "󰍉", panel: "launcher" },
        controls: { name: "Control centre", glyph: "󰨚", panel: "controls" },
        session:  { name: "Session",        glyph: "󰐥", panel: "session" }
    })

    function isButton(id: string): bool {
        return root.buttons[id] !== undefined
    }

    // Buttons cannot see the island, so they ask here and the bar listens.
    // The bar writes the open panel back to `shownPanel` so a button can stay
    // lit.
    signal panelToggled(string panel)

    function togglePanel(panel: string): void {
        root.panelToggled(panel)
    }

    property string shownPanel: ""

    // ── CHIP SHAPE ──────────────────────────────────────────────────────────
    //
    // Modules with a ring face. A ring is a gauge, so the bell, with nothing
    // to measure, keeps its symbol; on/off links get an empty ring.
    readonly property var ringed: [
        "bluetooth",
        "network",
        "media",
        "timer",
        "battery",
        "volume",
        "brightness",
        "weather",
        "updates"
    ]

    // A piece's own shape when it has one, the bar's when it does not.
    function shapeOf(id: string, own: var): string {
        const chosen = own ? own : Config.chipShape
        return chosen === "ring" && root.ringed.indexOf(id) >= 0
            ? "ring"
            : "icon"
    }

    function figureOf(own: var): string {
        return own ? own : Config.chipFigure
    }

    // ── GLYPH AND FIGURE ────────────────────────────────────────────────────
    //
    // One table for every place a module's symbol and figure appear.
    function glyphOf(id: string): string {
        switch (id) {
        case "planify":
            return ""
        case "network":
            return NetworkService.icon
        case "bluetooth":
            return BluetoothService.icon
        case "volume":
            return AudioService.icon
        case "brightness":
            return BrightnessService.icon
        case "battery":
            return BatteryService.icon
        case "weather":
            return WeatherService.glyph || "󰖐"
        case "updates":
            return "󰏖"
        case "notifications":
            return NotificationService.doNotDisturb ? "󰂛" : "󰂚"
        case "media":
            return "󰎇"
        case "timer":
            return "󰔛"
        case "calendar":
            return "󰃭"
        }

        return ""
    }

    // Never empty, so "always show the figure" applies to every module.
    function valueOf(id: string): string {
        if (id === "aur" || id === "flathub") {
            const report = id === "aur"
                ? UpdatesService.aurReport
                : UpdatesService.flatpakReport

            return report ? String(report.alt) : "…"
        }

        switch (id) {
        case "volume":
            return AudioService.muted
                ? "Muted"
                : `${AudioService.volume}%`

        case "brightness":
            return `${BrightnessService.percent}%`

        case "battery":
            return `${BatteryService.percent}%`

        case "weather":
            return WeatherService.available
                ? `${WeatherService.temperature}°`
                : "--°"

        case "updates":
            return `${UpdatesService.count}`

        case "notifications":
            return `${NotificationService.history.length}`

        case "media":
            return MediaService.available
                ? (MediaService.title || MediaService.identity || "Playing")
                : "Nothing playing"

        case "timer":
            return TimerService.running
                ? TimerService.display
                : "0:00"

        case "network":
            return NetworkService.connectionName

        case "bluetooth":
            return BluetoothService.summary

        case "calendar":
            return Qt.formatDate(root.today.date, "ddd d")
        }

        return ""
    }

    // For the calendar's figure, which only changes at midnight.
    readonly property SystemClock today: SystemClock {
        precision: SystemClock.Minutes
    }

    // Maximum width for text figures (track title, network or device name)
    // before they are elided.
    function figureLimit(id: string): int {
        switch (id) {
        case "media":
            return 150

        case "network":
        case "bluetooth":
            return 110
        }

        return 0
    }

    // Keep labels neutral and use the selected accent for connected devices.
    function tintOf(id: string): color {
        if (id === "volume" && AudioService.muted)
            return Theme.textMuted

        if (id === "network")
            return NetworkService.wifiConnected || NetworkService.wiredConnected
                ? Theme.accent
                : Theme.textMuted

        if (id === "bluetooth")
            return BluetoothService.connectedDevices.length > 0
                ? Theme.accent
                : Theme.textMuted

        if (id === "battery" && BatteryService.low)
            return Theme.indicatorWarn

        return Theme.text
    }

    // The full names remain in tooltips and the existing detail panels.
    function barValueOf(id: string): string {
        return root.valueOf(id)
    }

    function tooltipOf(id: string): string {
        if (id === "aur")
            return UpdatesService.aurError
                || UpdatesService.aurReport?.tooltip
                || "Checking Arch / AUR updates…"

        if (id === "flathub")
            return UpdatesService.flatpakError
                || UpdatesService.flatpakReport?.tooltip
                || "Checking Flatpak updates…"

        if (id === "weather")
            return WeatherService.error
                || `${WeatherService.place} · ${WeatherService.description}`

        if (id === "planify")
            return "Add task in Planify"

        if (id === "network")
            return NetworkService.connectionName
                + " · "
                + NetworkService.stateLine

        if (id === "bluetooth")
            return "Bluetooth · " + BluetoothService.summary

        if (id === "volume")
            return "Volume · "
                + root.valueOf(id)
                + "\nScroll to adjust · middle click to mute · right click for mixer"

        const value = root.valueOf(id)

        return root.entry(id).name
            + (value ? " · " + value : "")
    }

    // ── VISIBILITY ──────────────────────────────────────────────────────────
    //
    // A placed piece always shows; the player says "Nothing playing" rather
    // than disappearing. Timer and player can instead be set to show
    // only while running (`when: "running"`).
    readonly property var runners: [
        "timer",
        "media"
    ]

    function runs(id: string): bool {
        switch (id) {
        case "timer":
            return TimerService.running

        case "media":
            return MediaService.playing
        }

        return false
    }

    function shows(id: string, when: var): bool {
        if (when === "running"
                && root.runners.indexOf(id) >= 0)
            return root.runs(id)

        return id === "media" || root.has(id)
    }

    // ── ACTIVITIES ──────────────────────────────────────────────────────────
    //
    // Activities retain their original behaviour. Privacy deliberately does
    // not participate here, otherwise activating the microphone/camera would
    // rearrange media or timer between the two sides.
    readonly property var activities: {
        const list = []

        if (TimerService.running
                && Config.beside("timer"))
            list.push("timer")

        if (MediaService.playing
                && Config.beside("media"))
            list.push("media")

        return list.slice(0, 2)
    }

    // ── RESTING ISLAND GEOMETRY ─────────────────────────────────────────────
    //
    // The original island layout keeps its own width. Privacy is appended as
    // a completely separate slot on the right.
    //
    // This means:
    //
    //   media:
    //       [ artwork ][ clock ][ spectrum ]
    //
    //   media + privacy:
    //       [ artwork ][ clock ][ spectrum ][ privacy ]
    //
    // Nothing inside the original content changes position when privacy
    // appears.

    readonly property int clockCore:
        Config.clockShowsDate
            ? 150
            : (Config.clockShowsSeconds ? 88 : 72)

    readonly property int activitySide:
        root.activities.length > 1
            ? 110
            : 92

    // Width the island would have had without privacy.
    readonly property int restContentWidth:
        root.activities.length === 0
            ? root.entry("clock").width
            : root.clockCore + 2 * root.activitySide

    // Additional slot appended to the right.
    readonly property int privacySide:
        PrivacyService.active ? 32 : 0

    // Total resting island width.
    readonly property int restWidth:
        root.restContentWidth + root.privacySide

    // The glance the island opens under a resting pointer.
    readonly property int summaryWidth: 384
    readonly property int summaryHeight:
        MediaService.available ? 168 : 116

    // ── OPEN DETAIL ─────────────────────────────────────────────────────────
    //
    // One detail at a time, always shown by the island (`Bar.qml` writes
    // "island" to `openHost`).
    property string openId: ""
    property string openHost: ""

    function close(): void {
        root.openId = ""
        root.openHost = ""
    }

    // The catalogue size, except network and Bluetooth, which open the
    // control centre's lists, and an empty notification list, which is short.
    function openSize(id: string): var {
        if (id === "network" || id === "bluetooth")
            return {
                width: 420,
                height: 500
            }

        const item = root.entry(id)

        if (id === "notifications"
                && NotificationService.history.length === 0)
            return {
                width: item.width,
                height: 124
            }

        return {
            width: item.width,
            height: item.height
        }
    }

    // A module that becomes unavailable closes its open detail.
    readonly property bool openGone:
        root.openId !== ""
        && !root.has(root.openId)

    onOpenGoneChanged: {
        if (root.openGone)
            root.close()
    }

    // Chips cannot see their bar, so they ask here and the bar listens.
    signal activationRequested(string id, string from)

    function activate(id: string, from: string): void {
        if (id === "aur" || id === "flathub") {
            UpdatesService.update(
                id === "aur"
                    ? "aur"
                    : "flatpak"
            )
            return
        }

        if (id === "planify") {
            Quickshell.execDetached([
                "flatpak",
                "run",
                "--command=io.github.alainm23.planify.quick-add",
                "io.github.alainm23.planify"
            ])
            return
        }

        root.activationRequested(id, from)
    }

    // A module asking for a panel.
    signal panelRequested(string panel)

    function requestPanel(panel: string): void {
        root.panelRequested(panel)
    }

    // ── AVAILABILITY ────────────────────────────────────────────────────────
    //
    // Whether this machine can show the module at all.
    function has(id: string): bool {
        if (root.isButton(id))
            return true

        switch (id) {
        case "clock":
        case "calendar":
        case "timer":
        case "aur":
        case "flathub":
        case "planify":
        case "workspaces":
        case "notifications":
            return true

        case "media":
            return MediaService.available

        case "battery":
            return BatteryService.available

        case "volume":
            return AudioService.ready

        case "brightness":
            return BrightnessService.available

        case "network":
            return true

        case "bluetooth":
            return BluetoothService.available

        case "weather":
            return true

        case "updates":
            return UpdatesService.available

        case "photo":
            return true
        }

        return false
    }
}
