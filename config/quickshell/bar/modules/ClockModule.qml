// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C L O C K   M O D U L E                                                │
// │   clock · the island's resting face                                      │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../../theme"
import "../../services"

// The time, optionally with the date. It has no chip or layout slot: it is
// what the island shows at rest.
Item {
    id: root

    implicitWidth: holder.implicitWidth
    implicitHeight: Theme.capsuleHeight

    // The clock opens controls on left click; right click opens themes.
    MouseArea {
        anchors.fill: parent
        z: 1
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: ModuleService.requestPanel("palette")
    }

    // Tick every second only when seconds are shown.
    SystemClock {
        id: clock
        precision: SystemClock.Seconds 
    }

    // Seconds are appended to the chosen format so the two settings stay
    // independent.
    readonly property string format: "hh:mm"
    Loader {
        id: holder
        anchors.centerIn: parent
        sourceComponent: detail
    }

    Component {
        id: detail

        Item {
            implicitWidth: content.implicitWidth
            implicitHeight: Theme.capsuleHeight

            Row {
                id: content

                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, root.format)
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.min(11, Theme.capsuleHeight - 2)
                    font.weight: Font.DemiBold
                    color: Theme.islandText
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "ddd d MMM").toUpperCase()
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.islandTextMuted
                }
            }
        }
    }
}
