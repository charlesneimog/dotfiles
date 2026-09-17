import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "../../services"
import "../../theme"

Item {
    id: root
    required property var hostWindow
    property real maximumWidth: 400
    width: Math.min(maximumWidth, icons.implicitWidth + 8)
    height: Theme.capsuleHeight
    visible: icons.implicitWidth > 0
    // Extend the background to the top edge of the surface.
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
            spacing: 3

            Repeater {
                model: SystemTray.items
                delegate: MouseArea {
                    id: tray
                    required property var modelData
                    width: visible ? 18 : 0
                    height: icons.height
                    visible: modelData.status !== Status.Passive
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    ToolTip.visible: containsMouse
                    ToolTip.text: modelData.tooltipTitle || modelData.title || modelData.id
                    ToolTip.delay: 500
                    Image {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        sourceSize: Qt.size(12, 12)
                        source: tray.modelData.icon
                    }
                    onClicked: event => {
                        if (event.button === Qt.RightButton || modelData.onlyMenu) {
                            if (modelData.hasMenu) {
                                const point = mapToItem(null, 0, height)
                                modelData.display(root.hostWindow, point.x, point.y)
                            }
                        } else if (event.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                        } else modelData.activate()
                    }
                    onWheel: event => {
                        modelData.scroll(event.angleDelta.y || event.angleDelta.x, event.angleDelta.y === 0)
                        event.accepted = true
                    }
                }
            }

            Repeater {
                model: NiriService.windows
                delegate: MouseArea {
                    id: app
                    required property var modelData
                    readonly property var entry: DesktopEntries.heuristicLookup(modelData.app_id || "")
                    width: 18
                    height: icons.height
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    ToolTip.visible: containsMouse
                    ToolTip.text: modelData.title || modelData.app_id || "Window"
                    ToolTip.delay: 500
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: Theme.accent
                        opacity: app.modelData.is_focused ? 0.25 : app.containsMouse ? 0.12 : 0
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        sourceSize: Qt.size(12, 12)
                        source: Quickshell.iconPath(app.entry?.icon || app.modelData.app_id || "application-x-executable", "application-x-executable")
                    }
                    onClicked: event => {
                        if (event.button === Qt.MiddleButton)
                            NiriService.closeWindow(String(modelData.id))
                        else NiriService.focusWindow(String(modelData.id))
                    }
                }
            }
        }
    }
}
