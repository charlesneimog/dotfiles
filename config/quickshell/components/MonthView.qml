import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"

// Month grid and the selected day’s Nextcloud agenda.
Item {
    id: root
    property color ink: Theme.text
    property int offsetMonths: 0
    readonly property date month: new Date(clock.date.getFullYear(), clock.date.getMonth() + offsetMonths, 1)
    readonly property int leading: month.getDay()
    property date selectedDay: new Date()
    readonly property var dayEvents: CalendarService.eventsForDay(selectedDay)
    onMonthChanged: {
        selectedDay = offsetMonths === 0 ? clock.date : month
        CalendarService.showMonth(month)
    }
    Component.onCompleted: CalendarService.showMonth(month)
    property bool adding: false
    property string selectedCalendar: ""

    SystemClock { id: clock; precision: SystemClock.Minutes }
    ColumnLayout {
        id: monthPane
        width: parent.width
        height: parent.height / 3
        spacing: 4
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "‹"
            color: root.ink
            font.pixelSize: 18
            TapHandler { onTapped: root.offsetMonths-- }
        }
        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(root.month, "MMMM yyyy")
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: root.ink
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            TapHandler { onTapped: root.offsetMonths = 0 }
        }
        Text {
            text: "›"
            color: root.ink
            font.pixelSize: 18
            TapHandler { onTapped: root.offsetMonths++ }
        }
    }
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 2
        Repeater {
            model: ["S", "M", "T", "W", "T", "F", "S"]
            Text {
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                horizontalAlignment: Text.AlignHCenter
                color: root.ink
                opacity: 0.6
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeLabel
            }
        }
        Repeater {
            model: 42
            Rectangle {
                id: cell
                required property int index
                readonly property date day: new Date(root.month.getFullYear(), root.month.getMonth(), index - root.leading + 1)
                readonly property bool today: Qt.formatDate(day, "yyyy-MM-dd") === Qt.formatDate(clock.date, "yyyy-MM-dd")
                readonly property bool selected: Qt.formatDate(day, "yyyy-MM-dd") === Qt.formatDate(root.selectedDay, "yyyy-MM-dd")
                readonly property bool hasEvents: CalendarService.eventsForDay(day).length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 24
                Layout.minimumHeight: 0
                Layout.preferredHeight: 16
                radius: 4
                color: today ? Theme.accent : "transparent"
                border.width: selected ? 1 : 0
                border.color: Theme.accent
                TapHandler { onTapped: root.selectedDay = cell.day }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    width: 3; height: 3; radius: 2
                    visible: cell.hasEvents
                    color: cell.today ? Theme.island : Theme.accent
                }
                Text {
                    anchors.centerIn: parent
                    text: cell.day.getDate()
                    color: cell.today ? Theme.island : root.ink
                    opacity: cell.day.getMonth() === root.month.getMonth() ? 1 : 0.3
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLabel
                }
            }
        }
    }
    }

    ColumnLayout {
        anchors.top: monthPane.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: 6

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(root.selectedDay, "ddd, d MMM")
            color: root.ink
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
        }
        PillButton {
            text: root.adding ? "Cancel" : "Add"
            enabled: !CalendarService.saving
            onClicked: {
                root.adding = !root.adding
                CalendarService.saveError = ""
                if (root.adding) {
                    startDate.text = Qt.formatDate(root.selectedDay, "yyyy-MM-dd")
                    endDate.text = startDate.text
                    if (!CalendarService.writableCalendars.some(c => c.href === root.selectedCalendar))
                        root.selectedCalendar = CalendarService.writableCalendars.length ? CalendarService.writableCalendars[0].href : ""
                    titleInput.forceActiveFocus()
                }
            }
        }
        Text {
            text: CalendarService.loading ? "…" : "↻"
            color: Theme.accent
            font.pixelSize: 18
            TapHandler { onTapped: CalendarService.refresh() }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: !root.adding && (CalendarService.error !== "" || root.dayEvents.length === 0)
        text: CalendarService.error || (CalendarService.loading ? "Loading events…" : "No events")
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeLabel
    }
    ListView {
        visible: !root.adding
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 8
        model: root.dayEvents
        delegate: Column {
            required property var modelData
            width: ListView.view.width
            spacing: 2
            Text {
                width: parent.width
                text: modelData.title
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.ink
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                text: (modelData.allDay ? "All day" : Qt.formatTime(new Date(modelData.start), "HH:mm")
                    + " – " + Qt.formatTime(new Date(modelData.end), "HH:mm")) + " · " + modelData.calendar
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
            }
            Text {
                width: parent.width
                visible: modelData.location !== ""
                text: modelData.location
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
            }
        }
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.adding
        contentHeight: form.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ColumnLayout {
            id: form
            width: parent.width
            spacing: 6
            enabled: !CalendarService.saving
            Field { id: titleInput; placeholderText: "Event title" }
            Text {
                text: "Calendar"
                color: Theme.textMuted
                font.pixelSize: Theme.fontSizeLabel
            }
            Flow {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: CalendarService.writableCalendars
                    PillButton {
                        required property var modelData
                        text: modelData.name
                        active: root.selectedCalendar === modelData.href
                        onClicked: root.selectedCalendar = modelData.href
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                visible: CalendarService.writableCalendars.length === 0
                text: CalendarService.loading ? "Loading calendars…" : (CalendarService.error || "No writable calendars available")
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                font.pixelSize: Theme.fontSizeLabel
            }
            PillButton {
                id: allDay
                text: "All day"
                onClicked: active = !active
            }
            Text { text: "Starts · YYYY-MM-DD / HH:mm"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeLabel }
            RowLayout {
                Layout.fillWidth: true
                Field { id: startDate; placeholderText: "YYYY-MM-DD" }
                Field { id: startTime; visible: !allDay.active; text: "09:00"; Layout.maximumWidth: 72 }
            }
            Text {
                text: allDay.active ? "Last day · YYYY-MM-DD" : "Ends · YYYY-MM-DD / HH:mm"
                color: Theme.textMuted
                font.pixelSize: Theme.fontSizeLabel
            }
            RowLayout {
                Layout.fillWidth: true
                Field { id: endDate; placeholderText: "YYYY-MM-DD" }
                Field { id: endTime; visible: !allDay.active; text: "10:00"; Layout.maximumWidth: 72 }
            }
            Field { id: locationInput; placeholderText: "Location (optional)" }
            Text {
                Layout.fillWidth: true
                visible: CalendarService.saveError !== ""
                text: CalendarService.saveError
                wrapMode: Text.WordWrap
                color: Theme.red
                font.pixelSize: Theme.fontSizeLabel
            }
            PillButton {
                text: CalendarService.saving ? "Saving…" : "Save event"
                enabled: !CalendarService.saving && titleInput.text.trim() !== "" && root.selectedCalendar !== ""
                onClicked: CalendarService.addEvent({
                    title: titleInput.text.trim(), calendar: root.selectedCalendar,
                    allDay: allDay.active, startDate: startDate.text, endDate: endDate.text,
                    startTime: startTime.text, endTime: endTime.text, location: locationInput.text
                })
            }
        }
    }
    }

    component Field: TextField {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        implicitHeight: 30
        color: Theme.text
        placeholderTextColor: Theme.textMuted
        selectionColor: Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        background: Rectangle { color: Theme.islandSurfaceHover; radius: Theme.radiusSmall }
    }

    Connections {
        target: CalendarService
        function onEventCreated() {
            if (!root.adding)
                return
            root.adding = false
            titleInput.text = ""
            locationInput.text = ""
        }
    }
}
