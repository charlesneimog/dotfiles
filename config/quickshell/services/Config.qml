// Central static configuration for the shell.
// Edit values here; there is no settings.json and no settings persistence.

pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Runtime files that are not settings (clipboard/history/key cache) still
    // use the shell state directory.
    readonly property string stateDirectory:
        `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/quickshell`

    // Compatibility for services that wait until configuration is available.
    readonly property bool arrived: true

    property string clockFormat: "HH:mm"
    property bool clockShowsDate: false
    property bool clockShowsSeconds: false

    // Capsule height and distance from the top edge. Every other bar
    // metric derives from `barHeight`.
    property int barHeight: 18
    property int barMargin: 0

    // A notch flush with the top edge instead of a floating capsule.
    property bool islandAttached: true

    // One-island style only: the band spans the screen (less
    // `barSideMargin`) instead of fitting its contents. Off by default so
    // the island can still grow and shrink.
    property bool barFullWidth: false

    property int barSideMargin: 20

    property bool windowShadow: false

    // hyprglass. Dimmed in the settings when the plugin is not built;
    // `CompositorService` pushes it at login and after every reload.
    property bool windowGlass: false


    // Row id from `ThemeService.greetings`; `random` is picked by `fa` on
    // each run.
    property string greeting: "random"

    // One of `barStyles`.
    property string barStyle: "spread"

    // Ids either side of the island; null means `barDefaults`.
    property var barLeft: null
    property var barRight: null

    // Hovering the island opens the glance; a click still opens the
    // control centre.
    property bool islandSummary: true

    // Null means `besideDefaults`.
    property var islandActivities: null

    // One of `chipShapes` and one of `chipFigures`.
    property string chipShape: "icon"
    property string chipFigure: "on"

    property int launcherResults: 9

    // Order with an empty query: `recent` ranks by launch count with
    // decay; otherwise alphabetical.
    property string launcherOrder: "recent"

    // Fit the island to the number of results instead of a fixed-height
    // list. Off by default: a list that holds still is easier to aim at.
    // `launcherResults` caps it either way.
    property bool launcherFits: false

    // ── CLIPBOARD ───────────────────────────────────────────────
    //
    // Off stops the watcher, not just the list.
    property bool clipboardHistory: true

    // Payloads are stored as separate files, so the index stays small.
    property int clipboardKeep: 200

    property bool clipboardImages: true

    // Password-manager copies are never stored regardless
    // (`clipboard.py`).
    property bool clipboardWipeOnLock: false

    // Enough to make text unreadable, no more.

    // Empty means read from the system: the passwd full name and
    // `~/.face` (`AccountService`).
    property string userName: ""
    property string userAvatar: ""

    // Persisted so silent mode survives a restart.
    property bool doNotDisturb: false


    // Note bodies in the handwriting font instead of the UI font.
    property bool notesHandwriting: true

    // Show edge note decks only on empty workspaces.
    property bool deckOnEmpty: false


    // Dots always shown, and the total number of workspaces. Workspaces
    // past `workspaceCount` still show while occupied.
    property int workspaceCount: 5
    property int workspaceMax: 10

    // Percentage. 100 is the designed speed; 0 disables animation.
    property int motionScale: 100

    // Named in Theme.easingCurves.
    property string motionCurve: "OutCubic"

    // Hyprland's animation preset, from Motion.presets (the two above
    // are the shell's own). `CompositorService` pushes it at startup and
    // after every reload; `animations.lua` deliberately has no preset.
    property string animationPreset: "macos"

    property string fontFamily: "JetBrainsMono Nerd Font"
    property string fontMono: "JetBrainsMono Nerd Font"

    property int notificationTimeout: 5000

    // ── COMPOSITOR ──────────────────────────────────────────────────
    //
    // Hyprland options changed from the settings window, keyed by
    // option path. Absent keys are left to the Lua config. The option
    // whitelist lives in `compositor.py`.
    property var compositor: ({})

    // The keyboard's own options (`input:kb_*`), kept apart from
    // `compositor` because the keyboard is the machine's, not the desk's.
    property var keyboard: ({})

    // ── DISPLAYS ────────────────────────────────────────────────────
    //
    // Arrangements keyed by the set of connected monitors (their
    // descriptions, sorted and joined). Without one, Hyprland's `auto`
    // applies.
    //
    //   <profile> primary   description of the screen the shell's
    //                       surfaces go on; "" means Quickshell's
    //                       first, where an unset
    //                       `PanelWindow.screen` lands anyway
    //             monitors  per description: mode, position, scale,
    //                       transform, mirror, vrr, disabled — each
    //                       optional, absent when unchanged
    //
    // Fields are defined by `monitors.py`.
    property var displays: ({})

    // ── KEYS ────────────────────────────────────────────────────────
    //
    // A combination per bind in `hypr/keybinds.lua`, keyed by its
    // description; "" leaves it unbound. Empty until the first change,
    // then complete. `ShortcutService` writes it to keys.tsv, which the
    // Lua config reads.
    property var keys: ({})

    // Launcher sigil overrides, keyed by mode id; absent means the
    // default in `launcherPrefixDefaults`.
    property var launcherPrefixes: ({})

    // ── DESKTOP ─────────────────────────────────────────────────────
    //
    // Desktop widgets in placement order; a module may appear more than
    // once:
    //
    //   key      this widget — "clock-1"; a row without one is keyed
    //            by its module on the way in
    //   id       the module, the same id the catalogue uses
    //   col, row the square its top left corner is on
    //   family   "2x2", "4x2", "4x4" or "8x2" — which face it wears
    //   theme    "modern" or "analogue"; absent means the desktop's
    //   style    how its capsule is drawn; absent means the desktop's
    //   opacity  how solid it is; absent means the desktop's
    //   note     for a notes widget, which note; absent means the
    //            front of the deck
    //
    // Or a deck of notes on a screen edge:
    //
    //   key      "notes-2"
    //   id       "notes"
    //   edge     "left", "right" or "bottom"
    //   notes    the note keys on it, in order along the edge
    property var desktopWidgets: []

    // Defaults for widgets without their own: a theme from
    // Colours always come from the palette.
    property string desktopTheme: "modern"
    property string desktopStyle: "capsule"

    // Capsule opacity in percent; below 100 the desktop layer's blur
    // rule (`windowrules.lua`) shows through. Widgets may override it.
    property int desktopOpacity: 100

    // ── CONTROL CENTRE ──────────────────────────────────────────────
    //
    // Top-row buttons, ids from `ControlsService.doors`. Null means the
    // service default, so buttons added later still appear; [] means
    // none.
    property var centreButtons: null

    // The blocks on the control centre's grid, one row each:
    //
    //   id    the block, from `ControlsService.catalogue`
    //   col   which column its top left cell is in
    //   row   and which row
    //   size  "2x3": columns by rows, one of the sizes the block offers
    //
    // Null means the default layout.
    property var centreBlocks: null

    // Toggles on the tile block, in order, from
    // `ControlsService.toggleCatalogue`. Null is the default six;
    // overflow becomes a second page.
    property var centreToggles: null

    // ── DOCK ────────────────────────────────────────────────────────
    //
    // An empty dock is not drawn, so enabling it by default costs
    // nothing on a fresh install.
    property bool dockEnabled: false

    // Pinned desktop entry ids, in order. Name, icon and command are
    // read from the entry.
    property var dockPinned: []

    // Any edge but the top, which is the bar's.
    property string dockEdge: "bottom"

    property string dockAlignment: "center"

    // Every other dock metric derives from the icon size.
    property int dockIconSize: 44

    // Percent; the compositor blurs behind the layer.
    property int dockOpacity: 100

    // Also show running applications that aren't pinned.
    property bool dockRunning: true

    // Reserve an exclusive zone instead of floating over windows.
    property bool dockReserve: false

    // With `dockReserve` on this leaves an empty reserved strip; the
    // settings page warns rather than forbids.
    property bool dockAutohide: false

    // Launcher button at the start of the row.
    property bool dockLauncher: true

    // Anything wttr.in accepts: a city, postcode or airport code. Empty
    // lets wttr.in geolocate by IP, which can be tens of kilometres off.
    property string weatherPlace: ""

    // Idle timeouts in minutes, 0 = never; all off by default.
    // `IdleService` runs one monitor per value.
    property int idleLock: 0
    property int idleScreen: 0
    property int idleSuspend: 0

    // Kelvin. Persisted, unlike keep-awake, so a restart comes back
    // warm. `SunsetService` drives hyprsunset.
    property bool nightLight: false
    property int nightTemperature: 4000

    // Closing the lid with another screen connected: `off` disables the
    // panel and moves its workspaces, `keep` leaves it on, `system`
    // defers to logind. The result is written into the display profile
    // so it survives hotplug. With no other screen, logind decides.
    property string lidPolicy: "off"

    // "palette" follows the accent; otherwise a fixed #rrggbb. Built and
    // applied by compositor.py.
    property string cursorColor: "palette"
    property int cursorSize: 24

    // hypr-dynamic-cursors' shake magnification (`shake.enabled`).
    property bool shakeToFind: true

    // Translations live in `theme/Tr.qml`; missing strings fall back to
    // English.
    property string language: "en"

    // ── CONFIG HELPERS ─────────────────────────────────────────────────────

    readonly property var launcherPrefixDefaults: ({
        calculate: "=", desk: ">", windows: "@", timer: "!", clipboard: "'"
    })

    function launcherPrefix(id: string): string {
        const chosen = launcherPrefixes[id]
        if (typeof chosen === "string" && chosen.length === 1)
            return chosen
        return root.launcherPrefixDefaults[id] ?? ""
    }

    readonly property var barDefaults: ({
        left: ["aur", "workspaces"],
        right: ["notifications", "network", "bluetooth", "volume", "battery"]
    })

    function barItems(side: string): var {
        const kept = side === "left" ? root.barLeft : root.barRight
        const opposite = side === "left" ? root.barRight : root.barLeft
        const oppositeIds = opposite ? Array.from(opposite).map(entry => typeof entry === "string" ? entry : entry.id) : []
        const list = kept ? Array.from(kept) : root.barDefaults[side].filter(id => !oppositeIds.includes(id))
        return list.filter(entry => !["pet", "games", "settings", "notes", "tasks", "board", "brightness", "weather", "flathub", "updates"].includes(typeof entry === "string" ? entry : entry.id))
            .map(entry => typeof entry === "string"
                ? { id: entry, shape: "", figure: "", when: "" }
                : { id: entry.id, shape: entry.shape ?? "", figure: entry.figure ?? "",
                    when: entry.when ?? "" })
    }

    function barZone(side: string): var {
        return root.barItems(side).map(item => item.id)
    }

    function onBar(id: string): bool {
        return root.barZone("left").indexOf(id) >= 0
            || root.barZone("right").indexOf(id) >= 0
    }

    readonly property var besideDefaults: ["timer", "media"]

    function beside(id: string): bool {
        const kept = root.islandActivities
        return (kept ? Array.from(kept) : root.besideDefaults).indexOf(id) >= 0
    }

    // Runtime changes remain possible, but they are intentionally not persisted.
    function set(key: string, value: var): void {
        if (root[key] === undefined) {
            console.warn("Unknown config key:", key)
            return
        }
        root[key] = value
    }
}
