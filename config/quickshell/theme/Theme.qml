// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T H E M E                                                              │
// │   design tokens · consumed by every component                            │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick

import "../services"

// Design tokens for the whole shell. Components read Theme.<token> and never
// hardcode a colour, so a palette change repaints everything.
QtObject {
    id: root

    // ── ACTIVE THEME ────────────────────────────────────────────────────────

    property string activeId: "adaptive"
    property string activeName: "Adaptive (Wallpaper)"

    // ── ISLAND ──────────────────────────────────────────────────────────────

    // The bar and menus follow the selected palette, including light themes.
    // readonly property color island: root.background
    // readonly property color islandSurface: root.surface
    // readonly property color islandSurfaceHover: root.surfaceHover
    // readonly property color islandBorder: root.border

    // ── SEMANTIC COLOURS ────────────────────────────────────────────────────
    readonly property color island: "#000000"
    readonly property color islandText: "#ffffff"
    readonly property color islandTextMuted: "#8e8e93"
    readonly property color islandSurface: ThemeService.dark ? "#1d1d20" : "#ffffff"
    readonly property color islandSurfaceHover: ThemeService.dark ? "#2E2E32" : "#e5e5e5"
    readonly property color islandBorder: ThemeService.dark ? "#282828" : "#d1d1d6"

    readonly property color barBackground: "#000000"
    readonly property color barAccent: root.accent

    property color background: ThemeService.dark ? "#000000" : "#ffffff"
    property color surface: ThemeService.dark ? "#1D1D20" : "#f2f2f2"
    property color surfaceHover: ThemeService.dark ? "#2E2E32" : "#e5e5e5"
    property color border: ThemeService.dark ? "#282828" : "#d1d1d6"

    property color text: ThemeService.dark ? "#ffffff" : "#1c1c1e"
    property color textMuted: ThemeService.dark ? "#8e8e93" : "#6e6e73"

    property color accent: ThemeService.dark ? "#0a84ff" : "#007aff"
    property color accentHover: ThemeService.dark ? "#409cff" : "#0a84ff"
    property color accentText: "#ffffff"

    property color red: ThemeService.dark ? "#ff453a" : "#ff3b30"
    property color green: ThemeService.dark ? "#32d74b" : "#34c759"
    property color yellow: ThemeService.dark ? "#ffd60a" : "#ffcc00"
    property color blue: ThemeService.dark ? "#0a84ff" : "#007aff"

    // Status indicators are fixed: a wallpaper-derived accent must not change
    // what a battery ring means.
    readonly property color indicator: root.islandText
    readonly property color indicatorDim: root.border
    readonly property color indicatorGood: root.green
    readonly property color indicatorWarn: root.yellow
    readonly property color indicatorBad: root.red
    readonly property color indicatorTimer: root.blue

    readonly property color scrim: "#bf000000"
    readonly property color scrimText: "#ffffff"
    readonly property color hairline: "#20ffffff"

    readonly property color paperWash: "#c4ffffff"
    readonly property color paperInk: "#1c1c1e"
    readonly property color paperInkMuted: "#8a1c1c1e"
    readonly property color paperLine: "#261c1c1e"
    readonly property int paperRadius: 10

    readonly property int paletteTransition: 260

    Behavior on background   { ColorAnimation { duration: root.paletteTransition } }
    Behavior on surface      { ColorAnimation { duration: root.paletteTransition } }
    Behavior on surfaceHover { ColorAnimation { duration: root.paletteTransition } }
    Behavior on border       { ColorAnimation { duration: root.paletteTransition } }
    Behavior on text         { ColorAnimation { duration: root.paletteTransition } }
    Behavior on textMuted    { ColorAnimation { duration: root.paletteTransition } }
    Behavior on accent       { ColorAnimation { duration: root.paletteTransition } }
    Behavior on accentHover  { ColorAnimation { duration: root.paletteTransition } }
    Behavior on accentText   { ColorAnimation { duration: root.paletteTransition } }

    // ── METRICS ─────────────────────────────────────────────────────────────

    // The bar's scale. Ring chips, the resting island and the one-capsule
    // band are all one capsule tall.
    readonly property int capsuleHeight: Config.barHeight
    readonly property int barTopMargin: Config.barMargin
    readonly property int capsuleSpacing: 5

    // Exclusive zone: exactly what the bar paints. Hyprland adds `gaps_out`
    // below it, so reserving more leaves a larger top gap than on the other
    // edges.
    readonly property int barReserve: root.barTopMargin + root.capsuleHeight

    // Where the bar's input region ends: 8 px of slack under the capsules.
    readonly property int barBand: root.barReserve

    // ── DESKTOP GRID ────────────────────────────────────────────────────────
    //
    // Widgets span whole cells. The gutter matches Hyprland's `gaps_out`.
    // A square is at least `desktopCell` and grows up to `desktopCellLargest`
    // so the board's margin is the same on all four sides
    // which fits the largest island detail (380 × 172) with one gutter around
    // it; a larger detail needs a larger cell.
    readonly property int desktopCell: 86
    readonly property int desktopCellLargest: 108
    readonly property int desktopGutter: 18
    readonly property int desktopStride: root.desktopCell + root.desktopGutter

    // ── CONTROL CENTRE GRID ─────────────────────────────────────────────────
    //
    // 6 × 8 cells; one cell is one toggle tile, and blocks span whole cells.
    readonly property int centreColumns: 8
    readonly property int centreRows: 8
    readonly property int centreCellWidth: 140
    readonly property int centreCellHeight: 64
    readonly property int centreGutter: 12
    readonly property int centreStrideX: root.centreCellWidth + root.centreGutter
    readonly property int centreStrideY: root.centreCellHeight + root.centreGutter

    // The pager strip (dots and chevrons) along the bottom of a paged block.
    readonly property int centrePagerLane: 18

    readonly property int panelPadding: 20

    // ── DOCK ────────────────────────────────────────────────────────────────
    //
    // Everything scales off the icon size. The margin matches `gaps_out`.
    readonly property int dockIcon: Config.dockIconSize
    readonly property int dockPadding: 8
    readonly property int dockGap: root.capsuleSpacing
    readonly property int dockMargin: root.desktopGutter

    // Depth is the icon plus a lane for the running dots, so icons sit off
    // centre, away from the screen edge.
    readonly property int dockDot: 5
    readonly property int dockDotLane: 9
    readonly property int dockDepth: root.dockIcon + root.dockDotLane
    readonly property int dockThickness: root.dockDepth + 2 * root.dockPadding

    // Screen-edge strip a hidden dock still listens on.
    readonly property int dockReveal: 4

    // Fixed width so a long window title does not stretch the menu.
    readonly property int dockMenuWidth: 250
    readonly property int dockMenuRow: 30
    readonly property int dockMenuPadding: 6

    readonly property int dockRadius: root.desktopRadius

    // Hover scale. Small enough that neighbours never move, which keeps the
    // input region computable.
    readonly property real dockLift: 1.125

    // Matches Hyprland's `rounding`: widgets sit among windows.
    readonly property int desktopRadius: 22

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 18
    readonly property int radiusPill: 999

    // Corner radius for pictures, as a fraction of the box. They range from
    // 20 px to 58 px, and no fixed radius looks right at both ends.
    readonly property real pictureCorner: 0.24

    // Where the notch meets the screen edge.
    readonly property int radiusNotch: 6

    // ── SHADOW ──────────────────────────────────────────────────────────────
    //
    // Shared by Hyprland's `decoration:shadow` (CompositorService) and the
    // bar's own capsule shadow, so both sit at the same height. Only drawn
    // when the setting is on.
    readonly property int shadowRange: 14
    readonly property real shadowOpacity: 0.5
    readonly property color shadowColor: "#000000"

    // Bar only. A Gaussian is at half strength on the edge of its source
    // shape, while Hyprland's shadow is at full strength against the window;
    // blurring a slightly grown copy moves the half-way point outside the
    // capsule.
    readonly property int shadowSpread: 4

    // The bar's capsules are small and have open wallpaper on every side, so
    // the same reach reads much heavier. Scale the reach, keep the darkness.
    readonly property real shadowBarScale: 0.6
    readonly property int shadowBarRange: Math.round(root.shadowRange * root.shadowBarScale)
    readonly property int shadowBarSpread: Math.round(root.shadowSpread * root.shadowBarScale)

    // ── TYPOGRAPHY ──────────────────────────────────────────────────────────

    readonly property string fontFamily: resolveFont(Config.fontFamily)
    readonly property string fontMono: resolveFont(Config.fontMono)

    // Qt expects one installed family, not a CSS comma-separated stack.
    function resolveFont(value: string): string {
        const installed = Qt.fontFamilies()
        const choices = value.split(",").map(name => name.trim())
        return choices.find(name => installed.indexOf(name) >= 0)
            ?? (installed.indexOf("JetBrainsMono Nerd Font") >= 0 ? "JetBrainsMono Nerd Font" : "monospace")
    }

    // Script face for the shell's own name. Checked explicitly because Qt
    // substitutes silently when a family is missing.
    readonly property string fontSignature: {
        const installed = Qt.fontFamilies()
        for (const family of ["Grape Nuts", "Georgia"]) {
            if (installed.indexOf(family) !== -1)
                return family
        }
        return root.fontFamily
    }

    // Note bodies: handwriting unless switched off.
    readonly property string fontHand: Config.notesHandwriting
        ? root.fontSignature : root.fontFamily

    readonly property int fontSizeLabel: 10
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeRegular: 13
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 16

    // Desktop widgets are read from further away. `fontSizeDisplay` is for
    // faces that are a single number (the large clocks).
    readonly property int fontSizeWidget: 30
    readonly property int fontSizeDisplay: 68

    // ── MOTION ──────────────────────────────────────────────────────────────

    readonly property real motion: Config.motionScale / 100

    readonly property var easingCurves: [
        { id: "OutCubic", label: "Smooth",  type: Easing.OutCubic },
        { id: "OutQuint", label: "Snappy",  type: Easing.OutQuint },
        { id: "OutBack",  label: "Springy", type: Easing.OutBack },
        { id: "Linear",   label: "Flat",    type: Easing.Linear }
    ]

    readonly property int easing: {
        const curve = root.easingCurves.find(entry => entry.id === Config.motionCurve)
        return curve ? curve.type : Easing.OutCubic
    }

    // A preset writes `motionScale` and `motionCurve` together; there is no
    // stored preset key.
    readonly property var motionPresets: [
        { id: "smooth",  label: "Smooth",  scale: 100, curve: "OutCubic" },
        { id: "snappy",  label: "Snappy",  scale: 70,  curve: "OutQuint" },
        { id: "springy", label: "Springy", scale: 110, curve: "OutBack" },
        { id: "off",     label: "None",    scale: 0,   curve: "Linear" }
    ]

    function easingTypeOf(id: string): int {
        const curve = root.easingCurves.find(entry => entry.id === id)
        return curve ? curve.type : Easing.OutCubic
    }

    readonly property int durationFast: Math.round(140 * root.motion)
    readonly property int durationMedium: Math.round(200 * root.motion)
    readonly property int durationMorph: Math.round(380 * root.motion)

    // How long anything that screenshots the screen (lock, picker, capture)
    // waits after closing the island: the morph plus a couple of frames.
    readonly property int durationIslandGone: root.durationMorph + 40

    // ── APPLICATION ─────────────────────────────────────────────────────────

    readonly property var tokens: [
        "background", "surface", "surfaceHover", "border", "text", "textMuted",
        "accent", "accentHover", "accentText", "red", "green", "yellow", "blue"
    ]

    // Tokens a palette does not define keep their current value.
    function apply(colors: var, name: string): void {
        if (!colors)
            return
        if (name)
            root.activeName = name
        for (const token of root.tokens) {
            if (colors[token])
                root[token] = colors[token]
        }
    }
}
