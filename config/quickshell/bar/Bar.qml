// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B A R                                                                  │
// │   the bar · the island and its two sides, in three styles                │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

import "../theme"
import "../services"
import "../components"
import "./widgets"
import "./modules"
import "./island"
import "./island/controls"

// The island in the middle and the two sides (`Config.barZone`), in
// one of three styles:
//
//   grouped   the sides sit against the island and move aside as it grows
//   spread    the sides sit at the screen edges and hold still
//   island    everything in one capsule; the band morphs into whatever the
//             island opens
//
// Every detail opens in the island. Open panels use a full-screen window so
// a click outside can close them; passive layers only allocate their height.
PanelWindow {
    id: root

    readonly property alias island: island

    // Distance from the screen edge to the ends. Matches the compositor's
    // outer gap so the bar lines up with tiled windows.
    readonly property int edgeMargin: Config.barSideMargin

    readonly property string style: Config.barStyle
    readonly property bool spread: root.style === "spread"
    readonly property bool unified: root.style === "island"
    readonly property bool grouped: !root.spread && !root.unified

    // Stretch the band across the screen instead of fitting its contents.
    // Only the one-capsule style has a band.
    readonly property bool fullWidth: root.unified && Config.barFullWidth

    readonly property bool holding: island.expanded

    // Maximum panel width.
    //
    // Normally, spread mode keeps the side zones fixed and reserves their
    // space. When a full panel is open, however, the side zones move away
    // and the panel may use the whole bar width between the edge margins.
    readonly property int panelRoom:
        island.expanded
            && island.state.openPanel !== "module"
                ? root.width - 2 * root.edgeMargin
                : root.spread
                    ? root.width - 2 * (
                        root.edgeMargin
                        + Math.max(leftZone.width, rightZone.width)
                        + Theme.capsuleSpacing
                    )
                    : root.width - 2 * root.edgeMargin

    // Computed rather than read from `island.x`, which comes from an anchor
    // resolved during layout and would lag a frame behind the width.
    // Centre the complete resting group, including unequal side widths.
    property real groupOffset: root.grouped && !island.expanded
        ? (leftZone.width - rightZone.width) / 2
        : 0

    Behavior on groupOffset {
        NumberAnimation {
            duration: Theme.durationMedium
            easing.type: Theme.easing
        }
    }

    readonly property real islandLeft:
        (root.width - island.width) / 2 + root.groupOffset

    readonly property real islandRight:
        root.islandLeft + island.width

    // ── ONE CAPSULE ─────────────────────────────────────────────────────────
    //
    // A band a capsule tall, with the sides at its ends and the island in the
    // middle. When the island shows anything beyond the clock, the band morphs
    // into it and the sides are clipped by its closing ends.

    // Inset of each side from the band's edge, clear of the curve.
    readonly property int hostedInset: 12

    // The same at both ends, so the clock stays centred on the screen.
    readonly property real hostedSlot: root.unified
        ? root.hostedInset
            + Math.max(leftZone.width, rightZone.width)
            + Theme.capsuleSpacing * 2
        : 0

    // The island's width inside the band, animated on the island's clock so
    // the band widens with it. An OSD is wider than the clock and pushes the
    // sides out rather than overlapping them.
    property real restWidth:
        island.state.layer === island.state.layerOsd
            ? Math.max(ModuleService.restWidth, island.size.width)
            : ModuleService.restWidth

    Behavior on restWidth {
        NumberAnimation {
            duration: Theme.durationMorph
            easing.type: Theme.easing
        }
    }

    // The band at rest: the island's rest width plus a slot for each side.
    readonly property real bodyWidth: {
        if (!root.unified)
            return island.width

        if (root.fullWidth)
            return root.width - 2 * root.edgeMargin

        return root.restWidth + 2 * root.hostedSlot
    }

    readonly property real bandRow:
        Theme.capsuleHeight + island.notchPad

    // The island is showing more than the clock: a panel, a detail, the
    // glance or a notification. An OSD fits in the band and does not count.
    readonly property bool islandTaken:
        island.expanded
        || island.state.layer === island.state.layerSummary
        || island.state.layer === island.state.layerNotification

    readonly property real bodyX:
        root.fullWidth
            ? root.edgeMargin
            : (root.width - root.bodyWidth) / 2

    // 0 at rest, 1 once the island has taken over the band. Animated on the
    // island's clock and curve so the two land together.
    property real bandInto:
        root.unified && root.islandTaken ? 1 : 0

    Behavior on bandInto {
        enabled: island.animated

        NumberAnimation {
            duration: Theme.durationMorph
            easing.type: Theme.easing
        }
    }

    // Interpolates from the rest width to the island's animated width as
    // `bandInto` goes from 0 to 1. Both run on the same curve, so this is one
    // morph with no clock of its own. The max() stops a spring curve's
    // overshoot from making the band narrower than the island.
    readonly property real bandWidth:
        root.bandInto === 0 && !root.islandTaken
            ? root.bodyWidth
            : island.width
                + (root.bodyWidth - root.restWidth)
                * Math.max(0, 1 - root.bandInto)

    readonly property real bandX:
        (root.width - root.bandWidth) / 2

    // Attached (notch mode), only the island reaches the screen edge; the
    // sides stay capsules, centred on `laneY`.
    readonly property int islandTopMargin:
        Config.islandAttached ? 0 : Theme.barTopMargin

    // The line everything on the bar is centred on.
    readonly property real laneY: 0

    readonly property int collapsedHeight: Theme.barBand

    // Grouped, the sides make room for a module detail but hide for a panel.
    // Spread now follows the same rule for full panels so a wide control
    // centre can use the available screen width.
    // In one capsule they hide whenever the island takes the band.
    readonly property bool sidesAway: root.unified
        ? root.islandTaken
        : island.expanded
            && island.state.openPanel !== "module"

    anchors {
        top: true
        left: true
        right: true
    }

    // ── SURFACE ─────────────────────────────────────────────────────────────

    // Include both ends of a morph so growing contents and shadows fit.
    // Panels retain the full-screen input area for click-outside dismissal.
    implicitHeight: island.expanded || ControlsService.editing
        ? root.screen.height
        : Math.min(root.screen.height,
            Math.max(root.collapsedHeight,
                root.islandTopMargin + Math.max(island.height,
                    island.size.height + island.notchPad))
            + Theme.shadowBarRange + 12)

    readonly property real shapeLeft: root.unified
        ? Math.min(root.bandX, root.islandLeft)
        : root.islandLeft

    readonly property real shapeRight: root.unified
        ? Math.max(root.bandX + root.bandWidth, root.islandRight)
        : root.islandRight

    readonly property bool wholeScreen:
        root.holding && ControlsService.editing

    mask: Region {
        width: root.width
        height: root.holding ? root.height : root.collapsedHeight

        Region {
            x: root.shapeLeft
            width: root.shapeRight - root.shapeLeft
            height: root.islandTopMargin + island.height + 12
        }
    }

    // Pinned to what the bar paints, so tiled windows never move while the
    // island grows.
    exclusiveZone: Theme.barReserve
    color: "transparent"

    // ── FOCUS ───────────────────────────────────────────────────────────────

    // Niri supports the layer-shell keyboard mode; no Hyprland focus grab.
    readonly property bool holdsKeyboard: island.expanded

    WlrLayershell.keyboardFocus: root.holdsKeyboard
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: root.holdsKeyboard

        onClicked: event => {
            if (event.y > root.collapsedHeight
                    && !(event.x >= root.shapeLeft
                        && event.x <= root.shapeRight
                        && event.y <= root.islandTopMargin
                            + island.height + 12)) {
                root.dismiss()
            }
        }
    }

    // ── OPENING A DETAIL ────────────────────────────────────────────────────

    function activate(id: string, from: string): void {
        if (ModuleService.openId === id) {
            root.dismiss()
            return
        }

        ModuleService.openHost = "island"
        ModuleService.openId = id
        island.open("module")
    }

    function dismiss(): void {
        if (island.expanded)
            island.close()

        ModuleService.close()
    }

    Connections {
        target: ModuleService

        function onActivationRequested(id: string, from: string): void {
            root.activate(id, from)
        }

        function onPanelToggled(panel: string): void {
            island.toggle(panel)
        }

        function onOpenIdChanged(): void {
            if (ModuleService.openId === ""
                    && island.state.openPanel === "module") {
                island.close()
            }
        }
    }

    Binding {
        target: ModuleService
        property: "shownPanel"
        value: island.state.openPanel
    }

    Connections {
        target: island.state

        function onOpenPanelChanged(): void {
            if (island.state.openPanel !== "module"
                    && ModuleService.openHost === "island") {
                ModuleService.close()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.holding
        onClicked: root.dismiss()
    }

    // ── SHADOW ──────────────────────────────────────────────────────────────

    Loader {
        anchors.fill: parent
        active: Config.windowShadow
        sourceComponent: shadowBody
    }

    Component {
        id: shadowBody

        Item {
            id: caster

            width: parent.width

            height: Math.min(
                parent.height,
                root.islandTopMargin
                    + Math.max(root.bandRow, island.height)
                    + Theme.shadowBarRange
            )

            opacity: Theme.shadowOpacity

            layer.enabled: true

            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax:
                    Theme.shadowBarRange
                    - Theme.shadowBarSpread
            }

            readonly property int spread:
                Theme.shadowBarSpread

            Rectangle {
                x: band.x - caster.spread
                y: band.y - caster.spread

                width:
                    band.width + 2 * caster.spread

                height:
                    band.height + 2 * caster.spread

                radius:
                    band.radius + caster.spread

                topLeftRadius:
                    band.topLeftRadius > 0
                        ? band.topLeftRadius + caster.spread
                        : 0

                topRightRadius:
                    band.topRightRadius > 0
                        ? band.topRightRadius + caster.spread
                        : 0

                visible: body.visible
                color: Theme.shadowColor
            }

            Rectangle {
                x: root.islandLeft - caster.spread
                y: island.y - caster.spread

                width:
                    island.width + 2 * caster.spread

                height:
                    island.height + 2 * caster.spread

                radius:
                    island.radius + caster.spread

                topLeftRadius:
                    island.topLeftRadius > 0
                        ? island.topLeftRadius + caster.spread
                        : 0

                topRightRadius:
                    island.topRightRadius > 0
                        ? island.topRightRadius + caster.spread
                        : 0

                color: Theme.shadowColor
            }

            Repeater {
                model: [notchLeft, notchRight]

                NotchFillet {
                    required property var modelData

                    x: modelData.x
                    y: modelData.y
                    width: modelData.width
                    height: modelData.height
                    visible: modelData.visible
                    opacity: modelData.opacity
                    mirrored: modelData.mirrored
                    color: Theme.shadowColor
                }
            }
        }
    }

    // ── BAND ────────────────────────────────────────────────────────────────

    Item {
        id: body

        anchors.fill: parent
        visible: root.unified

        Rectangle {
            id: band

            x: root.bandX
            y: root.islandTopMargin
            width: root.bandWidth
            height: Math.max(root.bandRow, island.height)
            radius: island.radius

            topLeftRadius:
                Config.islandAttached ? 0 : band.radius

            topRightRadius:
                Config.islandAttached ? 0 : band.radius

            color: island.surfaceColor

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: island.open("controls")
            }
        }
    }

    DynamicIsland {
        id: island

        hosted: root.unified
        roomForPanel: root.panelRoom

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.groupOffset
        anchors.top: parent.top
        anchors.topMargin: root.islandTopMargin

        Behavior on anchors.topMargin {
            enabled: island.animated

            NumberAnimation {
                duration: Theme.durationMedium
                easing.type: Theme.easing
            }
        }
    }

    // The island's hairline, drawn round the band once it takes the island's
    // shape.
    Rectangle {
        id: outline

        x: band.x
        y: band.y
        width: band.width
        height: band.height
        radius: band.radius
        topLeftRadius: band.topLeftRadius
        topRightRadius: band.topRightRadius
        visible: root.unified
        color: "transparent"

        border.width: 1

        border.color:
            island.menuBorder
                ? Theme.islandBorder
                : "transparent"

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.durationMedium
            }
        }
    }

    // The control centre's tray card while its grid is being arranged.
    Item {
        id: overlay

        anchors.fill: parent
        z: 3

        Loader {
            anchors.fill: parent
            active: ControlsService.editing

            sourceComponent: ControlsTray {
                host: overlay
                homeTop:
                    root.islandTopMargin
                    + island.height
                    + Theme.desktopGutter
            }
        }
    }

    // Notch fillets flaring from the island's edges out to the screen edge.
    NotchFillet {
        id: notchLeft

        x: (
            root.unified
                ? Math.min(root.bandX, root.islandLeft)
                : root.islandLeft
        ) - width

        anchors.top: parent.top

        visible: Config.islandAttached
        mirrored: true
        color: island.surfaceColor
    }

    NotchFillet {
        id: notchRight

        x: root.unified
            ? Math.max(
                root.bandX + root.bandWidth,
                root.islandRight
            )
            : root.islandRight

        anchors.top: parent.top

        visible: Config.islandAttached
        color: island.surfaceColor
    }

    // ── SIDES ───────────────────────────────────────────────────────────────

    Item {
        id: sides

        readonly property bool cropped:
            root.unified && root.bandInto > 0

        x: sides.cropped ? band.x : 0
        y: 0

        width:
            sides.cropped
                ? band.width
                : root.width

        height: root.height
        clip: sides.cropped

        // ── LEFT ────────────────────────────────────────────────────────────

        BarZone {
            id: leftZone

            entries: Config.barItems("left")
            chromeless: root.unified
            hostWindow: root

            x: (
                root.unified
                    ? root.bodyX + root.hostedInset
                    : root.spread
                        ? root.edgeMargin
                        : root.islandLeft
                            - Theme.capsuleSpacing
                            - leftZone.width
            ) - sides.x

            y: root.laneY

            opacity:
                root.sidesAway ? 0 : 1

            visible:
                opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration:
                        root.unified && root.sidesAway
                            ? Theme.durationFast
                            : Theme.durationMedium

                    easing.type: Theme.easing
                }
            }
        }

        // ── RIGHT ───────────────────────────────────────────────────────────

        BarZone {
            id: rightZone

            entries: Config.barItems("right")
            chromeless: root.unified
            hostWindow: root

            x: (
                root.unified
                    ? root.bodyX
                        + root.bodyWidth
                        - root.hostedInset
                        - rightZone.width
                    : root.spread
                        ? root.width
                            - root.edgeMargin
                            - rightZone.width
                        : root.islandRight
                            + Theme.capsuleSpacing
            ) - sides.x

            y: root.laneY

            opacity:
                root.sidesAway ? 0 : 1

            visible:
                opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration:
                        root.unified && root.sidesAway
                            ? Theme.durationFast
                            : Theme.durationMedium

                    easing.type: Theme.easing
                }
            }
        }
    }
}
