// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B A R   C H I P                                                        │
// │   one bar item, placed by the layout                                     │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Controls
import Quickshell

import "../../theme"
import "../../services"
import "../modules"

// One item on the bar. A module is drawn by `ChipFace` (symbol or ring, with
// its figure never, always or on hover), and a click asks the bar to open its
// detail in the island (`Bar.qml`). A button opens or closes its panel.
//
// Sharing a capsule, the chip is drawn inside it, the ring at 0.85 so it does
// not touch the capsule's outline. Alone, the chip is the capsule: a full-size
// ring, a circular button, or a pill just wide enough for symbol and figure.
//
// `reveal` is animated here and the Row reads the resulting width each frame,
// so each chip has exactly one clock.
Item {
    id: root

    property string moduleId: ""

    // Where a click comes from: "zone" on the island's own screen,
    // "elsewhere" on the others, whose bar has no island to open it in.
    property string origin: "zone"

    property bool alone: false

    // The piece's own look, "" for the bar's (`SettingsService.barItems`).
    property string ownShape: ""
    property string ownFigure: ""
    property string ownWhen: ""
    readonly property string figure: ModuleService.figureOf(root.ownFigure)

    readonly property bool button: ModuleService.isButton(root.moduleId)
    readonly property var door: ModuleService.buttons[root.moduleId] ?? null

    readonly property bool open: root.button
        ? ModuleService.shownPanel === root.door.panel
        : ModuleService.openId === root.moduleId

    // Out always, never, or while the pointer is on it.
    property real reveal: {
        if (root.figure === "on")
            return 1
        if (root.figure === "hover" && mouse.containsMouse)
            return 1
        return 0
    }

    // Fast, on a curve that starts quickly, so it answers the pointer at once.
    Behavior on reveal {
        NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutCubic }
    }

    // Hidden when the machine lacks the module, or when it is set to show only
    // while running and is not; the Row closes up.
    visible: ModuleService.shows(root.moduleId, root.ownWhen)
    implicitWidth: root.button ? Theme.capsuleHeight : face.implicitWidth
    implicitHeight: Theme.capsuleHeight
    width: root.implicitWidth
    height: root.implicitHeight

    // Highlight on hover and while its detail or panel is open. Alone, it
    // fills the capsule less its outline.
    Rectangle {
        anchors.centerIn: parent
        width: parent.width - (root.alone ? 2 : 4)
        height: parent.height - 2
        radius: height / 2
        color: Theme.islandSurfaceHover
        opacity: mouse.containsMouse || root.open ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
    }

    Text {
        anchors.centerIn: parent
        visible: root.button
        text: root.door ? root.door.glyph : ""
        font.family: Theme.fontMono
        font.pixelSize: Math.min(11, Theme.capsuleHeight - 4)
        color: Theme.islandText
    }

    ChipFace {
        id: face
        barMode: true

        visible: !root.button
        moduleId: root.button || !ModuleService.shows(root.moduleId, root.ownWhen) ? "" : root.moduleId
        shape: ModuleService.shapeOf(root.moduleId, root.ownShape)
        alone: root.alone
        reveal: root.reveal
    }

    ToolTip {
        visible: mouse.containsMouse && !root.open
        delay: 600
        text: String((root.button ? root.door?.name : ModuleService.tooltipOf(root.moduleId)) ?? "")
        contentItem: Text {
            text: String((root.button ? root.door?.name : ModuleService.tooltipOf(root.moduleId)) ?? "")
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.islandText
        }
        background: Rectangle {
            color: Theme.islandSurface
            border.color: Theme.islandBorder
            radius: 6
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onWheel: event => {
            if (root.moduleId === "volume")
                AudioService.setVolume(AudioService.volume + (event.angleDelta.y > 0 ? 5 : -5))
        }
        onClicked: event => {
            if (root.moduleId === "volume" && event.button === Qt.MiddleButton) {
                AudioService.toggleMute()
                return
            }
            if (root.moduleId === "volume" && event.button === Qt.RightButton) {
                Quickshell.execDetached(["flatpak", "run", "com.saivert.pwvucontrol"])
                return
            }
            if (root.button)
                ModuleService.togglePanel(root.door.panel)
            // The player with no player open has nothing to open onto.
            else if (ModuleService.has(root.moduleId))
                ModuleService.activate(root.moduleId, root.origin)
        }
    }
}
