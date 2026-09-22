pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Configuration 
    readonly property string server: "https://nextcloud.charlesneimog.duckdns.org"
    readonly property string username: "neimog"
    readonly property string calendarRoot:
        server
        + "/remote.php/dav/calendars/"
        + username
        + "/"

    property string password: ""

    Process {
        id: passwordLookup

        command: [
            "timeout", "20s",
            "secret-tool",
            "lookup",
            "service", "impasto-nextcloud",
            "username", root.username
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const secret = text.trim()

                if (!secret) {
                    console.warn(
                        "[TodoService] Nextcloud password not found in Secret Service"
                    )
                    root.error = "Nextcloud password not found"
                    return
                }

                root.password = secret
                credentialRetry.stop()
                credentialRetry.interval = 15000

                console.log(
                    "[TodoService] Nextcloud credentials loaded"
                )

                // Only refresh AFTER secret-tool has returned the password.
                root.refresh()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    console.warn(
                        "[TodoService] secret-tool:",
                        text.trim()
                    )
                }
            }
        }

        onExited: code => {
            if (code !== 0) {
                console.warn(
                    "[TodoService] secret-tool failed:",
                    code
                )

                root.error =
                    "Could not load Nextcloud credentials"
            }
            if (!root.password)
                credentialRetry.restart()
        }
    }

    Timer {
        id: credentialRetry
        interval: 15000
        onTriggered: {
            interval = Math.min(interval * 2, 300000)
            root.refresh()
        }
    }

    Component.onCompleted: {
        passwordLookup.running = true
    }



    // Published tasks. The UI only sees this list.
    property var tasks: []

    // New tasks are collected here while refreshing.
    property var pendingTasks: []

    property var lists: []

    property bool loading: false
    property string error: ""

    property int pendingQueries: 0

    // ── Public API ──────────────────────────────────────────────────────────
    function refresh(): void {
        if (!password) {
            if (!passwordLookup.running)
                passwordLookup.running = true
            return
        }

        if (loading || discover.running)
            return

        console.log("[TodoService] refreshing")
        loading = true
        error = ""
        pendingTasks = []
        pendingQueries = 0

        discover.running = true
    }

    function completeTask(task): void {
        if (!task || !task.href || !task.raw)
            return

        if (complete.running)
            return

        let data = task.raw

        // ── STATUS ─────────────────────────────────────────────────────────

        if (/^STATUS:/m.test(data)) {
            data = data.replace(
                /^STATUS:[^\r\n]*$/m,
                "STATUS:COMPLETED"
            )
        } else {
            data = data.replace(
                /END:VTODO/,
                "STATUS:COMPLETED\r\nEND:VTODO"
            )
        }

        // ── PERCENT-COMPLETE ───────────────────────────────────────────────

        if (/^PERCENT-COMPLETE:/m.test(data)) {
            data = data.replace(
                /^PERCENT-COMPLETE:[^\r\n]*$/m,
                "PERCENT-COMPLETE:100"
            )
        } else {
            data = data.replace(
                /END:VTODO/,
                "PERCENT-COMPLETE:100\r\nEND:VTODO"
            )
        }

        // ── COMPLETED ──────────────────────────────────────────────────────

        const now = icalTimestamp(new Date())

        if (/^COMPLETED:/m.test(data)) {
            data = data.replace(
                /^COMPLETED:[^\r\n]*$/m,
                "COMPLETED:" + now
            )
        } else {
            data = data.replace(
                /END:VTODO/,
                "COMPLETED:" + now + "\r\nEND:VTODO"
            )
        }

        completeTaskData = data
        completeTaskHref = task.href
        completeTaskEtag = task.etag || ""

        complete.command = curlPutCommand(
            task.href,
            data,
            completeTaskEtag
        )

        complete.running = true
    }

    readonly property Process create: Process {
        stdout: StdioCollector {}

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    console.warn(
                        "[TodoService] create:",
                        text.trim()
                    )
                }
            }
        }

    onExited: code => {
        if (code === 0) {
            console.log(
                "[TodoService] task created"
            )

            root.refresh()
        } else {
            root.error =
                "Could not create Nextcloud task"

            console.warn(
                "[TodoService] create failed:",
                code
                )
            }
        }
    }

    // ── Discovery ───────────────────────────────────────────────────────────
    readonly property Process discover: Process {
        command: root.curlCommand([
            "-X", "PROPFIND",
            "-H", "Depth: 1",
            "-H", "Content-Type: application/xml",
            "--data", root.discoveryRequest(),
            root.calendarRoot
        ])

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseDiscovery(text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    console.warn(
                        "[TodoService] discovery:",
                        text.trim()
                    )
                }
            }
        }

        onExited: code => {
            if (code !== 0) {
                root.error =
                    "Could not discover Nextcloud task lists"

                root.loading = false

                console.warn(
                    "[TodoService] discovery failed:",
                    code
                )
            }
        }
    }

    function discoveryRequest(): string {
        return '<?xml version="1.0"?>'
            + '<d:propfind '
            + 'xmlns:d="DAV:" '
            + 'xmlns:c="urn:ietf:params:xml:ns:caldav" '
            + 'xmlns:nc="http://nextcloud.org/ns">'
            + '<d:prop>'
            + '<d:displayname/>'
            + '<d:resourcetype/>'
            + '<c:supported-calendar-component-set/>'
            + '</d:prop>'
            + '</d:propfind>'
    }

    function parseDiscovery(xml): void {
        const responses = xml.match(
            /<d:response>[\s\S]*?<\/d:response>/g
        ) || []

        const found = []

        for (const response of responses) {
            // Must support VTODO.
            if (
                !/<cal:comp\s+name="VTODO"\s*\/?>/.test(response)
                && !/<c:comp\s+name="VTODO"\s*\/?>/.test(response)
            ) {
                continue
            }

            // Ignore deleted calendars.
            if (/<[^>]*deleted-calendar/.test(response))
                continue

            // Must be an active calendar.
            if (
                !/<cal:calendar\s*\/>/.test(response)
                && !/<c:calendar\s*\/>/.test(response)
            ) {
                continue
            }

            const hrefMatch = response.match(
                /<d:href>([\s\S]*?)<\/d:href>/
            )

            const nameMatch = response.match(
                /<d:displayname>([\s\S]*?)<\/d:displayname>/
            )

            if (!hrefMatch)
                continue

            const href =
                decodeXml(hrefMatch[1].trim())

            const name = nameMatch
                ? decodeXml(nameMatch[1].trim())
                : href

            found.push({
                name: name,
                href: href
            })
        }

        lists = found

        console.log(
            "[TodoService] found",
            found.length,
            "task lists"
        )

        if (found.length === 0) {
            // Discovery succeeded, but there are no task lists.
            // Publish an empty result only now that the request is done.
            tasks = []
            pendingTasks = []
            loading = false
            return
        }

        queryLists(found)
    }

    // ── Task queries ────────────────────────────────────────────────────────

    function queryLists(found): void {
        pendingQueries = found.length

        for (const list of found) {
            const process =
                taskQueryComponent.createObject(root, {
                    listName: list.name,
                    listHref: list.href
                })

            process.running = true
        }
    }

    Component {
        id: taskQueryComponent

        Process {
            id: query

            property string listName: ""
            property string listHref: ""

            command: root.curlCommand([
                "-X", "REPORT",
                "-H", "Depth: 1",
                "-H",
                "Content-Type: application/xml; charset=utf-8",
                "--data",
                root.taskRequest(),
                root.absoluteUrl(listHref)
            ])

            stdout: StdioCollector {
                onStreamFinished: {
                    root.parseTasks(
                        text,
                        query.listName,
                        query.listHref
                    )
                }
            }

            stderr: StdioCollector {
                onStreamFinished: {
                    if (text.trim()) {
                        console.warn(
                            "[TodoService]",
                            query.listName + ":",
                            text.trim()
                        )
                    }
                }
            }

            onExited: code => {
                if (code !== 0) {
                    console.warn(
                        "[TodoService] query failed:",
                        listName,
                        code
                    )
                }

                root.pendingQueries--

                // Publish only after every calendar has finished.
                if (root.pendingQueries <= 0) {
                    root.publishTasks()
                    root.loading = false
                }

                query.destroy()
            }
        }
    }

    function taskRequest(): string {
        return '<?xml version="1.0" encoding="utf-8"?>'
            + '<c:calendar-query '
            + 'xmlns:d="DAV:" '
            + 'xmlns:c="urn:ietf:params:xml:ns:caldav">'
            + '<d:prop>'
            + '<d:getetag/>'
            + '<c:calendar-data/>'
            + '</d:prop>'
            + '<c:filter>'
            + '<c:comp-filter name="VCALENDAR">'
            + '<c:comp-filter name="VTODO"/>'
            + '</c:comp-filter>'
            + '</c:filter>'
            + '</c:calendar-query>'
    }

    // ── Parsing ─────────────────────────────────────────────────────────────

    function parseTasks(xml, listName, listHref): void {
        const responses = xml.match(
            /<d:response>[\s\S]*?<\/d:response>/g
        ) || []

        const added = []

        for (const response of responses) {
            const hrefMatch = response.match(
                /<d:href>([\s\S]*?)<\/d:href>/
            )

            const etagMatch = response.match(
                /<d:getetag>([\s\S]*?)<\/d:getetag>/
            )

            const dataMatch = response.match(
                /<(?:cal|c):calendar-data>([\s\S]*?)<\/(?:cal|c):calendar-data>/
            )

            if (!hrefMatch || !dataMatch)
                continue

            const href =
                decodeXml(hrefMatch[1].trim())

            const etag = etagMatch
                ? decodeXml(etagMatch[1].trim())
                : ""

            let raw =
                decodeXml(dataMatch[1])

            // iCalendar folded lines:
            //
            // CRLF followed by a space/tab continues the
            // previous logical line.
            raw = raw.replace(
                /\r?\n[ \t]/g,
                ""
            )

            const todoMatch = raw.match(
                /BEGIN:VTODO[\s\S]*?END:VTODO/
            )

            if (!todoMatch)
                continue

            const todo =
                todoMatch[0]

            const status =
                field(todo, "STATUS").toUpperCase()

            const percent =
                Number(
                    field(
                        todo,
                        "PERCENT-COMPLETE"
                    ) || 0
                )

            const completed =
                status === "COMPLETED"
                || percent >= 100

            // Only active tasks are shown.
            if (completed)
                continue

            const title =
                unescapeIcal(
                    field(todo, "SUMMARY")
                )

            if (!title)
                continue

            added.push({
                uid:
                    field(todo, "UID"),

                title:
                    title,

                description:
                    unescapeIcal(
                        field(todo, "DESCRIPTION")
                    ),

                status:
                    status || "NEEDS-ACTION",

                completed:
                    false,

                percent:
                    percent,

                priority:
                    Number(
                        field(todo, "PRIORITY") || 0
                    ),

                due:
                    fieldWithParameters(
                        todo,
                        "DUE"
                    ),

                list:
                    listName,

                listHref:
                    listHref,

                href:
                    href,

                etag:
                    etag,

                raw:
                    raw
            })
        }

        // IMPORTANT:
        // Don't touch root.tasks here.
        //
        // Each REPORT contributes to pendingTasks.
        pendingTasks =
            pendingTasks.concat(added)
    }

    // ── Publish ─────────────────────────────────────────────────────────────

    function publishTasks(): void {
        const sorted =
            pendingTasks.slice()

        sorted.sort((a, b) => {
            // Tasks with due dates first.
            if (a.due && !b.due)
                return -1

            if (!a.due && b.due)
                return 1

            if (a.due && b.due)
                return a.due.localeCompare(b.due)

            return a.title.localeCompare(
                b.title
            )
        })

        // This is the ONLY point where the visible model
        // is replaced after a refresh.
        tasks = sorted

        console.log(
            "[TodoService] published",
            tasks.length,
            "tasks"
        )
    }

    // ── iCalendar helpers ───────────────────────────────────────────────────

    function field(data, name): string {
        const expression =
            new RegExp(
                "^"
                + name
                + "(?:;[^:]*)?:(.*)$",
                "mi"
            )

        const match =
            data.match(expression)

        return match
            ? match[1].replace(/\r$/, "")
            : ""
    }

    function fieldWithParameters(data, name): string {
        return field(data, name)
    }

    function unescapeIcal(value): string {
        return String(value || "")
            .replace(/\\\\n/gi, "\n")
            .replace(/\\,/g, ",")
            .replace(/\\;/g, ";")
            .replace(/\\\\/g, "\\")
    }

    // ── Complete task ───────────────────────────────────────────────────────

    property string completeTaskData: ""
    property string completeTaskHref: ""
    property string completeTaskEtag: ""

    readonly property Process complete: Process {
        stdout: StdioCollector {}

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    console.warn(
                        "[TodoService] update:",
                        text.trim()
                    )
                }
            }
        }

        onExited: code => {
            if (code === 0) {
                console.log(
                    "[TodoService] task completed"
                )

                // Refresh in the background.
                //
                // Existing tasks remain visible until all
                // REPORT requests have completed.
                root.refresh()
            } else {
                root.error =
                    "Could not update Nextcloud task"

                console.warn(
                    "[TodoService] PUT failed:",
                    code
                )
            }
        }
    }

function addTask(title, list): void {
    const cleanTitle = String(title || "").trim()

    if (!cleanTitle || create.running)
        return

    let target = list

    if (!target) {
        for (const candidate of lists) {
            if (candidate.name === "Personal") {
                target = candidate
                break
            }
        }
    }

    if (!target && lists.length > 0)
        target = lists[0]

    if (!target) {
        error = "No Nextcloud task list available"
        return
    }

    const uid = generateUid()
    const now = icalTimestamp(new Date())

    const data =
        "BEGIN:VCALENDAR\r\n"
        + "VERSION:2.0\r\n"
        + "PRODID:-//Impasto//TodoService//EN\r\n"
        + "BEGIN:VTODO\r\n"
        + "UID:" + uid + "\r\n"
        + "DTSTAMP:" + now + "\r\n"
        + "CREATED:" + now + "\r\n"
        + "LAST-MODIFIED:" + now + "\r\n"
        + "SUMMARY:" + escapeIcal(cleanTitle) + "\r\n"
        + "STATUS:NEEDS-ACTION\r\n"
        + "PERCENT-COMPLETE:0\r\n"
        + "PRIORITY:0\r\n"
        + "END:VTODO\r\n"
        + "END:VCALENDAR\r\n"

    const href =
        target.href
        + uid
        + ".ics"

    create.command = curlCommand([
        "-X", "PUT",
        "-H", "Content-Type: text/calendar; charset=utf-8",
        "-H", "If-None-Match: *",
        "--data-binary", data,
        absoluteUrl(href)
    ])

    create.running = true
}

    // ── Curl ────────────────────────────────────────────────────────────────

    function curlCommand(args): var {
        return [
            "curl",
            "--silent",
            "--show-error",
            "--fail-with-body",
            "--user",
            username + ":" + password
        ].concat(args)
    }

    function curlPutCommand(
        href,
        data,
        etag
    ): var {
        const args = [
            "-X",
            "PUT",
            "-H",
            "Content-Type: text/calendar; charset=utf-8"
        ]

        if (etag) {
            args.push(
                "-H",
                "If-Match: " + etag
            )
        }

        args.push(
            "--data-binary",
            data,
            absoluteUrl(href)
        )

        return curlCommand(args)
    }

    function absoluteUrl(href): string {
        if (
            href.startsWith("http://")
            || href.startsWith("https://")
        ) {
            return href
        }

        return server + href
    }

function generateUid(): string {
    if (typeof crypto !== "undefined" && crypto.randomUUID)
        return crypto.randomUUID()

    return Date.now().toString(16)
        + "-"
        + Math.random().toString(16).slice(2)
        + "@impasto"
}

function escapeIcal(value): string {
    return String(value || "")
        .replace(/\\/g, "\\\\")
        .replace(/\n/g, "\\n")
        .replace(/;/g, "\\;")
        .replace(/,/g, "\\,")
}

    // ── XML helpers ─────────────────────────────────────────────────────────

    function decodeXml(value): string {
        return String(value || "")
            .replace(/&quot;/g, "\"")
            .replace(/&apos;/g, "'")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&amp;/g, "&")
    }

    // ── Date helpers ────────────────────────────────────────────────────────

    function icalTimestamp(date): string {
        function pad(value) {
            return String(value).padStart(
                2,
                "0"
            )
        }

        return date.getUTCFullYear()
            + pad(
                date.getUTCMonth() + 1
            )
            + pad(
                date.getUTCDate()
            )
            + "T"
            + pad(
                date.getUTCHours()
            )
            + pad(
                date.getUTCMinutes()
            )
            + pad(
                date.getUTCSeconds()
            )
            + "Z"
    }

    // ── Startup ─────────────────────────────────────────────────────────────


    readonly property Timer refreshTimer: Timer {
        interval: 600000
        repeat: true
        running: true

        onTriggered: {
            root.refresh()
        }
    }
}
