import QtQuick
import Quickshell

import "../../services"
import "../../theme"

Item {
    id: root

    property real maximumWidth: 400

    implicitWidth: Math.min(
        maximumWidth,
        icons.implicitWidth + 8
    )

    implicitHeight: Theme.capsuleHeight

    width: implicitWidth
    height: implicitHeight

    visible: icons.implicitWidth > 0

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
                model: NiriService.windows

                delegate: MouseArea {
                    id: app

                    required property var modelData

                    readonly property var entry:
                        DesktopEntries.heuristicLookup(
                            modelData.app_id || ""
                        )

                    width: 18
                    height: icons.height

                    acceptedButtons:
                        Qt.LeftButton | Qt.MiddleButton

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    Rectangle {
                        anchors.fill: parent

                        radius: 4
                        color: Theme.accent

                        opacity:
                            app.modelData.is_focused
                                ? 0.25
                                : app.containsMouse
                                    ? 0.12
                                    : 0
                    }

                    Image {
                        anchors.centerIn: parent

                        width: 12
                        height: 12

                        sourceSize: Qt.size(12, 12)

                        source: Quickshell.iconPath(
                            app.entry?.icon
                                || app.modelData.app_id
                                || "application-x-executable",
                            "application-x-executable"
                        )
                    }

                    onClicked: event => {
                        if (event.button === Qt.MiddleButton) {
                            NiriService.closeWindow(
                                String(modelData.id)
                            )
                        } else {
                            NiriService.focusWindow(
                                String(modelData.id)
                            )
                        }
                    }
                }
            }
        }
    }
}
