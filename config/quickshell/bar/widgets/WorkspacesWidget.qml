// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W O R K S P A C E S   W I D G E T                                      │
// │   dots that stretch into a pill for the one you are on                   │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import "../../theme"
import "../../services"

// Three states, by shape and weight alone:
//
//     focused    a wide pill
//     occupied   a dot, solid but dim
//     empty      a dot, dimmer still
//
// The first few dots are always shown; the rest appear with use. The pill
// slides and stretches between positions rather than switching. Drawn in the
// accent: unlike the battery it carries no warning, so it follows the palette.
Item {
    id: root

    // Inside the one capsule it drops its own capsule and padding.
    property bool chromeless: false

    readonly property int dotSize: 5
    readonly property int activeWidth: 18
    readonly property int slotSpacing: 9

    implicitHeight: Theme.capsuleHeight
    // Each slot carries its own gap, so a collapsed one takes no space; the
    // spare gap is subtracted here.
    implicitWidth: layout.implicitWidth - root.slotSpacing
        + (root.chromeless ? 0 : 20)
    // Extend the background to the top edge of the surface.
    Rectangle {
        x: 0
        y: -1
        width: parent.width
        height: parent.height + 1
        radius: height / 2
        topLeftRadius: 0
        topRightRadius: 0
        color: root.chromeless ? "transparent" : Theme.island
        border.color: Theme.islandBorder
        border.width: 0
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        // Row spacing would still surround a collapsed slot.
        spacing: 0

        // A slot per workspace, shown or not, so arrivals and departures both
        // animate. A Repeater over only the visible ones would destroy items
        // and make the rest jump.
        Repeater {
            model: NiriService.onOutput(root.Screen.name)

            Item {
                id: slot

                required property var modelData
                readonly property int workspaceId: slot.modelData.id
                readonly property bool shown: NiriService.isVisible(slot.workspaceId)
                readonly property bool focused: slot.modelData.is_active
                readonly property bool occupied: NiriService.isOccupied(slot.workspaceId)

                Layout.preferredWidth: slot.shown
                    ? (slot.focused ? root.activeWidth : root.dotSize) + root.slotSpacing
                    : 0
                Layout.preferredHeight: Theme.capsuleHeight
                Layout.alignment: Qt.AlignVCenter

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(0, parent.width - root.slotSpacing)
                    height: root.dotSize
                    radius: height / 2

                    color: {
                        if (slot.modelData.is_urgent)
                            return Theme.indicatorBad
                        if (slot.focused || mouse.containsMouse)
                            return Theme.barAccent
                        return slot.occupied ? Theme.textMuted : Theme.indicatorDim
                    }
                    // Dimming separates occupied from focused without a third
                    // shape.
                    opacity: slot.focused ? 1 : (slot.occupied ? 0.55 : 1)

                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
                }

                // Fills the slot, gap included; a 6 px target is too small.
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NiriService.focus(slot.workspaceId)
                }
            }
        }
    }
}
