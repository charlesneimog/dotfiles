// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   A P P   T R A Y   W I D G E T                                          │
// │   system tray                                                             │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

import "../../theme"

// System tray.
//
// This widget contains only StatusNotifierItem entries exposed by
// Quickshell's SystemTray. Running Niri windows are handled separately by
// WindowsWidget.
Item {
    id: root

    required property var hostWindow

    property real maximumWidth: 400

    // BarZone sizes special widgets through implicitWidth.
    implicitWidth: icons.implicitWidth > 0
        ? Math.min(maximumWidth, icons.implicitWidth + 8)
        : 0

    implicitHeight: Theme.capsuleHeight

    width: implicitWidth
    height: implicitHeight

    visible: implicitWidth > 0

    // ── BACKGROUND ──────────────────────────────────────────────────────────

    Rectangle {
        x: 0
        y: -1

        width: parent.width
        height: parent.height + 1

        radius: height / 2
        topLeftRadius: 0
        topRightRadius: 0

        color: Theme.island

        border.color: Theme.islandBorder
        border.width: 0
    }

    // ── CONTENT ─────────────────────────────────────────────────────────────

    Flickable {
        anchors.fill: parent
        anchors.margins: 4

        contentWidth: icons.implicitWidth
        contentHeight: height

        clip: true

        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds

        Row {
            id: icons

            height: parent.height
            spacing: 5

            Repeater {
                model: SystemTray.items

                delegate: MouseArea {
                    id: tray

                    required property var modelData

                    width: 18
                    height: icons.height

                    acceptedButtons:
                        Qt.LeftButton
                        | Qt.MiddleButton
                        | Qt.RightButton

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    // ── ICON ────────────────────────────────────────────────

                    Image {
                        anchors.centerIn: parent

                        width: 12
                        height: 12

                        sourceSize: Qt.size(12, 12)
                        source: tray.modelData.icon
                    }

                    // ── CLICK ───────────────────────────────────────────────

                    onClicked: event => {
                        // Middle click uses the tray item's secondary action.
                        if (event.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                            return
                        }

                        // If the application exposes a tray menu, show it.
                        if (modelData.hasMenu) {
                            const point = tray.mapToItem(
                                root.hostWindow.contentItem,
                                0,
                                tray.height
                            )

                            modelData.display(
                                root.hostWindow,
                                Math.round(point.x),
                                Math.round(point.y)
                            )

                            return
                        }

                        // Otherwise use the item's primary action.
                        if (event.button === Qt.LeftButton)
                            modelData.activate()
                    }

                    // ── SCROLL ──────────────────────────────────────────────

                    onWheel: event => {
                        const delta =
                            event.angleDelta.y
                            || event.angleDelta.x

                        const horizontal =
                            event.angleDelta.y === 0

                        modelData.scroll(
                            delta,
                            horizontal
                        )

                        event.accepted = true
                    }
                }
            }
        }
    }
}
