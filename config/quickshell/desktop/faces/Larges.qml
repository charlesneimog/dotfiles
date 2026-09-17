// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L   A   R   G   E   S                                                  │
// │   4×4 widget faces                                                       │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import "../../theme"
import "../../services"
import "../../components"

// 4×4 faces, for modules with more to show. The same grid: the mark, label and
// reading stay in place and the extra content goes in the middle. Media and the
// calendar are written out, because their content is the widget. The analogue
// clock is `analogue/Dial.qml`.
Item {
    id: root

    property string moduleId: ""

    // Colours resolved by the widget. Faces read this rather than `Theme`.
    property var ink: DesktopService.inkFor(null)

    // The desktop row, for faces that draw what it names (a note).
    property var row: null

    readonly property var components: ({
        calendar: calendarLarge,
        weather: weatherLarge,
        stats: statsLarge,
        media: mediaLarge,
        claude: claudeLarge,
        photo: photoLarge
    })

    Component { id: calendarLarge; MonthView { ink: root.ink.text } }

    Loader {
        anchors.fill: parent
        sourceComponent: root.components[root.moduleId] ?? null
    }

    // ── ON THE GRID ─────────────────────────────────────────────────────────

    Component {
        id: weatherLarge

        WidgetFace {

            ink: root.ink
            id: weather

            readonly property var hoursAhead: {
                const hour = WeatherService.clock.date.getHours()
                return (WeatherService.available ? (WeatherService.hourly ?? []) : [])
                    .filter(block => block.tomorrow || block.hour > hour)
                    .slice(0, 4)
            }

            label: WeatherService.place || "Weather"
            reading: WeatherService.available ? `${WeatherService.temperature}°` : "--°"
            note: !WeatherService.available ? "no forecast"
                : WeatherService.description !== ""
                ? `${WeatherService.description} · feels ${WeatherService.feelsLike}° · ${WeatherService.high}° / ${WeatherService.low}°`
                : `feels ${WeatherService.feelsLike}° · ${WeatherService.high}° / ${WeatherService.low}°`

            Text {
                anchors.centerIn: parent
                text: WeatherService.available ? WeatherService.glyph : "󰅤"
                font.family: Theme.fontMono
                font.pixelSize: 34
                color: root.ink.text
            }

            body: [
                Item {
                    anchors.fill: parent

                    // Divided arithmetically: a Layout sizes from its
                    // children's implicit widths, not from the space it was
                    // given.
                    Row {
                        anchors.fill: parent

                        Repeater {
                            model: weather.hoursAhead

                            Item {
                                id: block

                                required property var modelData

                                width: parent.width / Math.max(1, weather.hoursAhead.length)
                                height: parent.height

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: {
                                            const hour = `${block.modelData.hour}`.padStart(2, "0")
                                            return block.modelData.tomorrow
                                                ? `${hour}:00⁺` : `${hour}:00`
                                        }
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fontSizeLabel
                                        color: root.ink.muted
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: block.modelData.glyph
                                        font.family: Theme.fontMono
                                        font.pixelSize: 26
                                        color: root.ink.text
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: `${block.modelData.temperature}°`
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: root.ink.text
                                    }
                                }
                            }
                        }
                    }
                }
            ]
        }
    }

    Component {
        id: statsLarge

        WidgetFace {

            ink: root.ink
            label: "System"
            reading: `${StatsService.cpu.toFixed(0)}%`
            note: `load ${StatsService.load[0].toFixed(2)} · ${StatsService.window}`

            Text {
                anchors.centerIn: parent
                text: "󰻠"
                font.family: Theme.fontMono
                font.pixelSize: 30
                color: root.ink.text
            }

            // Three traces rather than four cards: at this size the recent
            // history is what is worth showing.
            body: [
                Column {
                    anchors.fill: parent
                    spacing: 10

                    Repeater {
                        model: [
                            { title: "Processor", reading: `${StatsService.cpu.toFixed(0)}%`,
                              series: StatsService.cpuHistory },
                            { title: "Memory",
                              reading: `${StatsService.bytes(StatsService.memoryUsed)}`,
                              series: StatsService.memoryHistory },
                            { title: "Network",
                              reading: StatsService.rate(StatsService.networkDown),
                              series: StatsService.downHistory }
                        ]

                        Item {
                            id: trace

                            required property var modelData

                            width: parent.width
                            height: (parent.height - 20) / 3

                            Text {
                                id: traceTitle

                                anchors.left: parent.left
                                anchors.top: parent.top
                                text: trace.modelData.title
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeLabel
                                color: root.ink.muted
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                text: trace.modelData.reading
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeLabel
                                color: root.ink.text
                            }

                            Sparkline {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: traceTitle.bottom
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 2
                                values: trace.modelData.series
                                stroke: root.ink.accent
                            }
                        }
                    }
                }
            ]
        }
    }

    Component {
        id: claudeLarge

        WidgetFace {

            ink: root.ink
            label: "Claude"
            reading: ClaudeService.available ? ClaudeService.compact(ClaudeService.blockTokens) : "—"
            note: !ClaudeService.available ? "no usage found"
                : `this block · ${ClaudeService.messages(ClaudeService.blockMessages)} · ${ClaudeService.resetsIn}`

            ClaudeMark {
                anchors.centerIn: parent
                width: 34
                height: 34
                color: ClaudeService.tint
            }

            body: [
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 16
                    visible: ClaudeService.available

                    // The percentage comes from the account's response headers,
                    // the same figure as the usage page. Without the account,
                    // the bar shows the block's elapsed time instead.
                    Column {
                        width: parent.width
                        spacing: 7

                        Text {
                            text: ClaudeService.sessionMeasured
                                ? `block · ${ClaudeService.percent(ClaudeService.sessionFraction)}`
                                : "block · against the busiest on record"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: root.ink.muted
                        }

                        UsageBar {

                            trackColor: root.ink.raised
                            width: parent.width
                            progress: ClaudeService.gauge
                            fillColor: ClaudeService.tint
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 7

                        Text {
                            text: ClaudeService.weeklyMeasured
                                ? `week · ${ClaudeService.percent(ClaudeService.weeklyFraction)}`
                                : `week · ${ClaudeService.compact(ClaudeService.weekTokens)}`
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: root.ink.muted
                        }

                        UsageBar {

                            trackColor: root.ink.raised
                            width: parent.width
                            progress: ClaudeService.weeklyMeasured
                                ? ClaudeService.weeklyFraction
                                : (ClaudeService.peakWeekTokens > 0
                                    ? ClaudeService.weekTokens / ClaudeService.peakWeekTokens : 0)
                            fillColor: root.ink.accent
                        }
                    }

                    Text {
                        width: parent.width
                        text: `busiest block · ${ClaudeService.compact(ClaudeService.peakBlockTokens)}`
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.ink.muted
                    }
                }
            ]
        }
    }

    // ── CUSTOM FACES ────────────────────────────────────────────────────────


    // Album art at a useful size, with the transport under it.
    Component {
        id: mediaLarge

        Item {
            // As large as the room left after the text and the transport; sized
            // to the face's width it would push both out of a square face.
            ClippingRectangle {
                id: sleeve

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 22
                width: Math.min(parent.width - 44,
                                parent.height - 22 - 14 - 18 - info.implicitHeight)
                height: width
                radius: width * Theme.pictureCorner
                color: root.ink.raised

                Image {
                    anchors.fill: parent
                    source: MediaService.artUrl
                    visible: source != "" && status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 400
                    sourceSize.height: 400
                }

                Text {
                    anchors.centerIn: parent
                    visible: MediaService.artUrl === ""
                    text: "󰎇"
                    font.family: Theme.fontMono
                    font.pixelSize: 54
                    color: root.ink.muted
                }
            }

            ColumnLayout {
                id: info

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: sleeve.bottom
                anchors.bottom: parent.bottom
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                anchors.topMargin: 14
                anchors.bottomMargin: 18
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: MediaService.title !== "" ? MediaService.title
                        : (MediaService.available ? MediaService.identity : "Nothing playing")
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: root.ink.text
                }

                Text {
                    Layout.fillWidth: true
                    text: MediaService.available ? MediaService.artist : "no player"
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.ink.muted
                }

                Item { Layout.fillHeight: true }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 18
                    enabled: MediaService.available
                    opacity: MediaService.available ? 1 : 0.4

                    IconButton {

                        iconColor: root.ink.text
                        icon: "󰒮"
                        iconSize: 16
                        onClicked: MediaService.previous()
                    }

                    IconButton {

                        iconColor: root.ink.text
                        icon: MediaService.playing ? "󰏤" : "󰐊"
                        iconSize: 18
                        onClicked: MediaService.toggle()
                    }

                    IconButton {

                        iconColor: root.ink.text
                        icon: "󰒭"
                        iconSize: 16
                        onClicked: MediaService.next()
                    }
                }
            }
        }
    }


    // A picture of your own; see `PhotoFace`.
    Component {
        id: photoLarge

        PhotoFace { ink: root.ink; row: root.row; family: "4x4" }
    }

    // The 2×2 with its middle filled in: the next six tasks, soonest first,
    // each with its day and checkbox.
}
