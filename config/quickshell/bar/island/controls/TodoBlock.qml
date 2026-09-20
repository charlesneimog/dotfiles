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

Card {
    id: root

    readonly property var tasks: TodoService.tasks
    readonly property var lists: TodoService.lists

    property bool adding: false
    property var selectedList: null

    readonly property var listColors: [
        "#4C9AFF",
        "#F2C94C",
        "#4CC38A",
        "#F87171",
        "#A78BFA"
    ]

    function listColor(name): color {
        const value = String(name || "")
        let hash = 0

        for (let i = 0; i < value.length; ++i) {
            hash = ((hash << 5) - hash) + value.charCodeAt(i)
            hash |= 0
        }

        return listColors[Math.abs(hash) % listColors.length]
    }

    function beginAdding(): void {
        adding = true

        if (!selectedList && lists.length > 0)
            selectedList = lists[0]

        Qt.callLater(() => taskInput.forceActiveFocus())
    }

    function cancelAdding(): void {
        taskInput.text = ""
        adding = false
    }

    function submitTask(): void {
        const title = taskInput.text.trim()

        if (!title || !selectedList)
            return

        TodoService.addTask(title, selectedList)

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
                text: root.adding ? "Cancel" : "Add"
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
                        if (root.adding)
                            root.cancelAdding()
                        else
                            root.beginAdding()
                    }
                }
            }
        }

        // ── Add task ────────────────────────────────────────────────────────

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.adding
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
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
                            root.cancelAdding()
                        }
                    }

                    Text {
                        text: "Add"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: submitMouse.containsMouse
                            && taskInput.text.trim() !== ""
                            && root.selectedList
                            ? Theme.accent
                            : Theme.textMuted
                        opacity:
                            taskInput.text.trim() !== ""
                            && root.selectedList
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
                                && root.selectedList
                            cursorShape: enabled
                                ? Qt.PointingHandCursor
                                : Qt.ArrowCursor

                            onClicked: {
                                root.submitTask()
                            }
                        }
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                contentWidth: listSelector.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                Row {
                    id: listSelector
                    spacing: 6

                    Repeater {
                        model: root.lists

                        delegate: Rectangle {
                            id: listOption

                            required property var modelData

                            readonly property bool selected:
                                root.selectedList
                                && root.selectedList.href === modelData.href

                            height: 26
                            width: listName.implicitWidth + 22
                            radius: Theme.radiusSmall
                            color: selected
                                ? Qt.alpha(
                                    root.listColor(modelData.name),
                                    0.18
                                )
                                : optionMouse.containsMouse
                                    ? Theme.islandSurfaceHover
                                    : "transparent"

                            border.width: selected ? 1 : 0
                            border.color: root.listColor(modelData.name)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durationFast
                                }
                            }

                            Text {
                                id: listName
                                anchors.centerIn: parent
                                text: listOption.modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeLabel
                                font.weight: listOption.selected
                                    ? Font.DemiBold
                                    : Font.Normal
                                color: listOption.selected
                                    ? root.listColor(listOption.modelData.name)
                                    : Theme.textMuted
                            }

                            MouseArea {
                                id: optionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    root.selectedList = listOption.modelData
                                    taskInput.forceActiveFocus()
                                }
                            }
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

                readonly property color listColor:
                    root.listColor(entry.modelData.list)

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
                        border.color: entry.listColor

                        Text {
                            anchors.centerIn: parent
                            text: "󰄬"
                            opacity: checkboxMouse.containsMouse ? 1 : 0
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: entry.listColor

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
                            cursorShape: Qt.PointingHandCursor
                            enabled: !TodoService.loading

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
                            text: entry.modelData.title
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: entry.modelData.list !== ""
                            text: entry.modelData.list
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLabel
                            color: entry.listColor
                        }
                    }

                    // ── Remove ──────────────────────────────────────────────

                    IconButton {
                        Layout.alignment: Qt.AlignVCenter
                        visible: entryMouse.containsMouse
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
