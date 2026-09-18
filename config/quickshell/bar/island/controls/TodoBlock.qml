// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T O D O   L I S T                                                      │
// │   Nextcloud task list                                                    │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import "../../../theme"
import "../../../services"
import "../../../components"

// Todo list synchronized with Nextcloud through TodoService.
Card {
    id: root

    // Temporary data while TodoService is being implemented.
    // Remove this once TodoService.tasks is available.
    readonly property var mockTasks: [
        {
            summary: "Review pull requests",
            completed: false
        },
        {
            summary: "Write documentation",
            completed: false
        },
        {
            summary: "Fix Quickshell config",
            completed: true
        }
    ]

    readonly property var tasks: root.mockTasks

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ── Header ────────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Todo"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: Theme.text
            }

            Rectangle {
                visible: root.tasks.length > 0
                implicitWidth: Math.max(18, count.implicitWidth + 10)
                implicitHeight: 10
                radius: height / 2
                color: Theme.islandSurfaceHover
                Text {
                    id: count
                    anchors.centerIn: parent
                    text: root.tasks.length
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
                text: "Add"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: addMouse.containsMouse
                    ? Theme.accent
                    : Theme.textMuted

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durationFast
                    }
                }

                MouseArea {
                    id: addMouse

                    anchors.fill: parent
                    anchors.margins: -6

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        console.log("TODO: add task")
                    }
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────────────

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: root.tasks.length === 0

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: "Nothing to do"

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textMuted
        }

        // ── Tasks ─────────────────────────────────────────────────────────

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: root.tasks.length > 0

            clip: true
            spacing: 6

            model: root.tasks

            delegate: Rectangle {
                id: entry

                required property var modelData

                width: ListView.view.width
                height: 46

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

                    // ── Checkbox ──────────────────────────────────────────

                    Rectangle {
                        id: checkbox

                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        Layout.alignment: Qt.AlignVCenter

                        radius: 5

                        color: entry.modelData.completed
                            ? Theme.accent
                            : "transparent"

                        border.width: 1

                        border.color: entry.modelData.completed
                            ? Theme.accent
                            : Theme.textMuted

                        Text {
                            anchors.centerIn: parent

                            visible: entry.modelData.completed

                            text: "󰄬"

                            font.family: Theme.fontMono
                            font.pixelSize: 11

                            color: Theme.accentText
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                console.log(
                                    "TODO: toggle",
                                    entry.modelData.summary
                                )
                            }
                        }
                    }

                    // ── Description ───────────────────────────────────────

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        text: entry.modelData.summary

                        elide: Text.ElideRight

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold

                        color: entry.modelData.completed
                            ? Theme.textMuted
                            : Theme.text

                        opacity: entry.modelData.completed ? 0.55 : 1.0

                        font.strikeout: entry.modelData.completed

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationFast
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.durationFast
                            }
                        }
                    }

                    // ── Remove ────────────────────────────────────────────

                    IconButton {
                        Layout.alignment: Qt.AlignVCenter

                        visible: entryMouse.containsMouse

                        icon: "󰅖"
                        iconSize: 11

                        onClicked: {
                            console.log(
                                "TODO: remove",
                                entry.modelData.summary
                            )
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
