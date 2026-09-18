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

    readonly property var tasks: TodoService.tasks

    property bool adding: false

    function submitTask(): void {
        const title = taskInput.text.trim()

        if (!title)
            return

        TodoService.addTask(title)

        taskInput.text = ""
        adding = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ── Header ──────────────────────────────────────────────────────────

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

                implicitWidth: Math.max(
                    18,
                    count.implicitWidth + 10
                )

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
                text: root.adding
                    ? "Cancel"
                    : "Add"

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
                        Qt.callLater(() => {
                            root.adding = !root.adding

                            if (root.adding)
                                taskInput.forceActiveFocus()
                            else
                                taskInput.text = ""
                        })
                    }
                }
            }
        }

        // ── Add task ────────────────────────────────────────────────────────

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            visible: root.adding
            radius: Theme.radiusSmall
            color: Theme.islandSurfaceHover

            RowLayout {
                anchors.fill: parent

                anchors.leftMargin: 10
                anchors.rightMargin: 10

                spacing: 10

                TextInput {
                    id: taskInput

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    clip: true

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall

                    color: Theme.text
                    selectionColor: Theme.accent

                    onAccepted: {
                        root.submitTask()
                    }

                    Keys.onEscapePressed: {
                        text = ""
                        root.adding = false
                    }
                }

                Text {
                    text: "Add"

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold

                    color: submitMouse.containsMouse
                        && taskInput.text.trim() !== ""
                        ? Theme.accent
                        : Theme.textMuted

                    opacity:
                        taskInput.text.trim() !== ""
                        ? 1
                        : 0.5

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

                    MouseArea {
                        id: submitMouse

                        anchors.fill: parent
                        anchors.margins: -6

                        hoverEnabled: true

                        enabled:
                            taskInput.text.trim() !== ""

                        cursorShape:
                            enabled
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor

                        onClicked: {
                            root.submitTask()
                        }
                    }
                }
            }
        }

        // ── Empty / loading / error state ───────────────────────────────────

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible:
                root.tasks.length === 0
                && !root.adding

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: TodoService.loading
                ? "Loading…"
                : TodoService.error
                    ? TodoService.error
                    : "Nothing to do"

            wrapMode: Text.Wrap

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall

            color: TodoService.error
                ? Theme.red
                : Theme.textMuted
        }

        // ── Tasks ──────────────────────────────────────────────────────────

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

                    // ── Complete ────────────────────────────────────────────

                    Rectangle {
                        id: checkbox

                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        Layout.alignment: Qt.AlignVCenter

                        radius: 5

                        color: "transparent"

                        border.width: 1

                        border.color:
                            checkboxMouse.containsMouse
                            ? Theme.accent
                            : Theme.textMuted

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Theme.durationFast
                            }
                        }

                        Text {
                            anchors.centerIn: parent

                            text: "󰄬"

                            opacity:
                                checkboxMouse.containsMouse
                                ? 1
                                : 0

                            font.family: Theme.fontMono
                            font.pixelSize: 11

                            color: Theme.accent

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Theme.durationFast
                                }
                            }
                        }

                        MouseArea {
                            id: checkboxMouse

                            anchors.fill: parent
                            anchors.margins: -5

                            hoverEnabled: true

                            cursorShape:
                                Qt.PointingHandCursor

                            enabled:
                                !TodoService.loading

                            onClicked: {
                                TodoService.completeTask(
                                    entry.modelData
                                )
                            }
                        }
                    }

                    // ── Description ─────────────────────────────────────────

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        spacing: 1

                        Text {
                            Layout.fillWidth: true

                            text:
                                entry.modelData.title

                            elide: Text.ElideRight

                            font.family:
                                Theme.fontFamily

                            font.pixelSize:
                                Theme.fontSizeSmall

                            font.weight:
                                Font.DemiBold

                            color:
                                Theme.text
                        }

                        Text {
                            Layout.fillWidth: true

                            visible:
                                entry.modelData.list !== ""

                            text:
                                entry.modelData.list

                            elide:
                                Text.ElideRight

                            font.family:
                                Theme.fontFamily

                            font.pixelSize:
                                Theme.fontSizeLabel

                            color:
                                Theme.textMuted
                        }
                    }

                    // ── Remove ──────────────────────────────────────────────

                    IconButton {
                        Layout.alignment:
                            Qt.AlignVCenter

                        visible:
                            entryMouse.containsMouse

                        icon: "󰅖"
                        iconSize: 11

                        onClicked: {
                            console.log(
                                "[TodoList] TODO: remove",
                                entry.modelData.title
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
