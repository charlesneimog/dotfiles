// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B A R   Z O N E                                                        │
// │   one side of the bar · its capsules in layout order                     │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Effects

import "../../theme"
import "../../services"

Row {
    id: root

    property var hostWindow: null
    property var entries: []
    property bool chromeless: false
    property string origin: "zone"

    // ── GROUPS ──────────────────────────────────────────────────────────────

    readonly property var groups: {
        const out = []
        let chips = []

        const flush = () => {
            if (chips.length > 0)
                out.push({
                    kind: "chips",
                    items: chips
                })

            chips = []
        }

        for (const item of root.entries) {
            if (item.id === "split") {
                flush()
            } else if (item.id === "workspaces") {
                flush()
                out.push({
                    kind: "workspaces",
                    items: []
                })
            } else if (item.id === "tray") {
                flush()
                out.push({
                    kind: "tray",
                    items: []
                })
            } else if (item.id === "windows") {
                flush()
                out.push({
                    kind: "windows",
                    items: []
                })
            } else {
                chips.push(item)
            }
        }

        flush()
        return out
    }

    spacing: root.chromeless ? 14 : Theme.capsuleSpacing

    Repeater {
        model: root.groups

        Group {
            required property var modelData

            kind: modelData.kind
            items: modelData.items
            chromeless: root.chromeless
            origin: root.origin
            hostWindow: root.hostWindow
        }
    }

    // ── GROUP ───────────────────────────────────────────────────────────────

    component Group: Item {
        id: group

        property string kind: "chips"
        property var items: []
        property bool chromeless: false
        property string origin: "zone"
        property var hostWindow: null


        readonly property bool workspaces:
            group.kind === "workspaces"

        readonly property bool tray:
            group.kind === "tray"

        readonly property bool windows:
            group.kind === "windows"

        readonly property bool special:
            group.workspaces
            || group.tray
            || group.windows

        readonly property var present:
            group.items.filter(item =>
                ModuleService.shows(item.id, item.when)
            )

        readonly property bool alone:
            !group.special && group.present.length === 1

        readonly property bool bare: {
            if (!group.alone)
                return false

            const item = group.present[0]

            return !ModuleService.isButton(item.id)
                && ModuleService.shapeOf(item.id, item.shape) === "ring"
                && ModuleService.figureOf(item.figure) !== "on"
        }

        readonly property int pad:
            group.chromeless || group.alone ? 0 : 4

        visible:
            group.special || group.present.length > 0

        width: group.special
            ? (strip.item ? strip.item.implicitWidth : 0)
            : chips.implicitWidth + 2 * group.pad

        height: Theme.capsuleHeight

        // ── SHADOW ──────────────────────────────────────────────────────────

        Item {
            id: shadow

            readonly property int reach:
                Theme.shadowBarRange + 4

            readonly property int spread:
                Theme.shadowBarSpread

            visible:
                Config.windowShadow
                && !group.chromeless
                && group.width > 0

            x: -shadow.reach
            y: -shadow.reach

            width:
                group.width + 2 * shadow.reach

            height:
                group.height + 2 * shadow.reach

            opacity: Theme.shadowOpacity

            layer.enabled: shadow.visible

            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1

                blurMax:
                    Theme.shadowBarRange
                    - Theme.shadowBarSpread
            }

            Rectangle {
                x:
                    shadow.reach
                    - shadow.spread

                y:
                    shadow.reach
                    - shadow.spread

                width:
                    group.width
                    + 2 * shadow.spread

                height:
                    group.height
                    + 2 * shadow.spread

                radius:
                    group.height / 2
                    + shadow.spread

                color: Theme.shadowColor
            }
        }

        // ── SPECIAL WIDGETS ─────────────────────────────────────────────────

        Loader {
            id: strip

            active: group.special

            sourceComponent: {
                if (group.workspaces)
                    return workspacesComponent

                if (group.tray)
                    return trayComponent

                if (group.windows)
                    return windowsComponent

                return null
            }
        }

        Component {
            id: workspacesComponent

            WorkspacesWidget {
                chromeless: group.chromeless
            }
        }

        Component {
            id: trayComponent

            AppTrayWidget {
                hostWindow: group.hostWindow
            }
        }

        Component {
            id: windowsComponent

            WindowsWidget {}
        }

        // ── NORMAL MODULE CAPSULE ────────────────────────────────────────────

        Rectangle {
            x: 0
            y: -1

            width: parent.width
            height: parent.height + 1

            visible: !group.special

            radius: height / 2
            topLeftRadius: 0
            topRightRadius: 0

            color:
                group.chromeless
                    ? "transparent"
                    : Theme.island

            border.color: Theme.islandBorder
            border.width: 0

            Row {
                id: chips

                x: group.pad
                y: 1
                height: Theme.capsuleHeight

                Repeater {
                    model: group.items

                    BarChip {
                        required property var modelData

                        anchors.verticalCenter:
                            parent.verticalCenter

                        moduleId:
                            modelData.id

                        ownShape:
                            modelData.shape

                        ownFigure:
                            modelData.figure

                        ownWhen:
                            modelData.when ?? ""

                        origin:
                            group.origin

                        alone:
                            group.alone
                    }
                }
            }
        }
    }
}
