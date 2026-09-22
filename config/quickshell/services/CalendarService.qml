pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var events: []
    property var calendars: []
    readonly property var writableCalendars: calendars.filter(calendar => calendar.writable)
    readonly property bool saving: create.running
    property string saveError: ""
    property string eventPayload: ""
    property bool refreshPending: false
    signal eventCreated()
    property string error: ""
    readonly property bool loading: query.running
    property date month: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    property string requestedKey: ""
    readonly property string monthKey: Qt.formatDate(month, "yyyy-MM")

    function showMonth(date): void {
        const nextKey = Qt.formatDate(date, "yyyy-MM")
        if (nextKey !== monthKey)
            events = []
        month = new Date(date.getFullYear(), date.getMonth(), 1)
        if (requestedKey !== monthKey)
            refresh()
    }

    function refresh(): void {
        if (query.running) {
            refreshPending = true
            return
        }
        refreshPending = false
        requestedKey = monthKey
        error = ""
        const start = new Date(month.getFullYear(), month.getMonth(), 1 - month.getDay())
        const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 42)
        query.command = ["python3", Qt.resolvedUrl("../scripts/calendar_events.py").toString().replace("file://", ""),
            TodoService.server, TodoService.username, TodoService.icalTimestamp(start), TodoService.icalTimestamp(end)]
        query.running = true
    }

    function eventsForDay(day): var {
        const start = new Date(day.getFullYear(), day.getMonth(), day.getDate()).getTime()
        const end = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1).getTime()
        return events.filter(event => {
            const from = new Date(event.start).getTime()
            const to = new Date(event.end).getTime()
            return from < end && (to > start || (from === to && from >= start))
        }).sort((a, b) => Number(b.allDay) - Number(a.allDay) || new Date(a.start) - new Date(b.start))
    }

    Process {
        id: query
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.requestedKey !== root.monthKey)
                    return
                try {
                    const result = JSON.parse(text)
                    root.error = result.error || ""
                    if (!result.error) {
                        root.events = result.events
                        root.calendars = result.calendars || []
                    }
                } catch (e) {
                    root.error = "Could not read Nextcloud events"
                }
            }
        }
        onExited: code => {
            if (code !== 0)
                root.error = "Could not load Nextcloud events"
            if (root.requestedKey !== root.monthKey || root.refreshPending)
                Qt.callLater(root.refresh)
        }
    }

    function addEvent(event): void {
        if (saving)
            return
        saveError = ""
        eventPayload = JSON.stringify(event) + "\n"
        create.running = true
    }

    Process {
        id: create
        property bool succeeded: false
        command: ["python3", Qt.resolvedUrl("../scripts/calendar_events.py").toString().replace("file://", ""),
            TodoService.server, TodoService.username, "create"]
        stdinEnabled: true
        onStarted: {
            succeeded = false
            write(root.eventPayload)
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text)
                    create.succeeded = result.created === true
                    root.saveError = result.error || (create.succeeded ? "" : "Could not save event")
                } catch (e) {
                    root.saveError = "Could not save event"
                }
            }
        }
        onExited: code => {
            root.eventPayload = ""
            if (code === 0 && succeeded) {
                root.eventCreated()
                root.refresh()
            } else if (!root.saveError) {
                root.saveError = "Could not save event"
            }
        }
    }

    Timer {
        interval: 300000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
}
