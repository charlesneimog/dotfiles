// ╭──────────────────────────────────────────────────────────────────────────╮
// │   N O T I F I C A T I O N   L I S T                                    │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Notifications

import "../../../theme"
import "../../../services"
import "../../../components"

Card {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Notifications"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: Theme.text
            }

            Rectangle {
                visible: NotificationService.history.length > 0
                implicitWidth: Math.max(18, count.implicitWidth + 10)
                implicitHeight: 17
                radius: height / 2
                color: Theme.islandSurfaceHover

                Text {
                    id: count

                    anchors.centerIn: parent
                    text: NotificationService.history.length

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLabel
                    font.weight: Font.DemiBold

                    color: Theme.textMuted
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                visible: NotificationService.history.length > 0
                text: "Clear"

                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall

                color: clearMouse.containsMouse
                    ? Theme.accent
                    : Theme.textMuted

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durationFast
                    }
                }

                MouseArea {
                    id: clearMouse

                    anchors.fill: parent
                    anchors.margins: -6

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: NotificationService.clearHistory()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: NotificationService.history.length === 0

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: "Nothing new"

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall

            color: Theme.textMuted
        }

        ListView {
            id: notificationList

            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: NotificationService.history.length > 0
            clip: true
            spacing: 6

            // Do not expose the array of Notification QObjects directly
            // to QQuickItemView. The ListView only receives a count.
            model: NotificationService.history.length

            delegate: Rectangle {
                id: entry

                required property int index

                readonly property var notification:
                    NotificationService.history[index] ?? null

                readonly property bool critical:
                    entry.notification !== null
                    && entry.notification.urgency === NotificationUrgency.Critical

                width: ListView.view.width
                height: 54
                radius: Theme.radiusSmall

                color: entryMouse.containsMouse
                    ? Theme.islandSurfaceHover
                    : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durationFast
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 6
                    spacing: 9

                    ClippingRectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        Layout.alignment: Qt.AlignVCenter

                        radius: width * Theme.pictureCorner

                        color: entry.critical
                            ? Theme.red
                            : Theme.islandSurfaceHover

                        Image {
                            id: image

                            anchors.fill: parent

                            source: entry.notification?.image ?? ""
                            visible: source != "" && status === Image.Ready

                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true

                            sourceSize.width: 60
                            sourceSize.height: 60
                        }

                        Text {
                            anchors.centerIn: parent

                            visible: !image.visible
                            text: entry.critical ? "󰀪" : "󰂚"

                            font.family: Theme.fontMono
                            font.pixelSize: 13

                            color: entry.critical
                                ? Theme.accentText
                                : Theme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            Layout.fillWidth: true

                            text: entry.notification?.summary ?? ""
                            elide: Text.ElideRight

                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold

                            color: Theme.text
                        }

                        Text {
                            Layout.fillWidth: true

                            text: entry.notification?.body ?? ""
                            visible: text !== ""

                            textFormat: Text.StyledText
                            elide: Text.ElideRight
                            maximumLineCount: 1

                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLabel

                            color: Theme.textMuted
                        }

                        Text {
                            Layout.fillWidth: true

                            text: entry.notification?.appName ?? ""
                            elide: Text.ElideRight

                            font.family: Theme.fontFamily
                            font.pixelSize: 9

                            color: Theme.textMuted
                            opacity: 0.7
                        }
                    }

                    IconButton {
                        Layout.alignment: Qt.AlignVCenter

                        visible: entryMouse.containsMouse
                        icon: "󰅖"
                        iconSize: 11

                        onClicked: {
                            if (entry.notification)
                                NotificationService.remove(entry.notification)
                        }
                    }
                }

                MouseArea {
                    id: entryMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }
    }
}
