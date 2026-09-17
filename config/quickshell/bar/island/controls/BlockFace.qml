// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B L O C K   F A C E                                                    │
// │   maps a block id and size to its card                                   │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import "../../../theme"
import "../../../services"
import "../../../components"

// Registry of control centre blocks: an id in, a card out. The card is told
// its cell count so blocks with several faces can pick one. A new block needs
// a row in `ControlsService.catalogue` and one here.
Item {
    id: root

    property string blockId: ""
    property string size: "2x2"

    // The grid row this face draws; only the toggles block needs it.
    property string blockKey: ""

    // Nothing is built for a block that is not on the grid.
    property bool active: true

    signal panelRequested(string panel)
    signal dismissed()

    readonly property var shape: ControlsService.parse(root.size)

    readonly property var components: ({
        toggles: togglesBlock,
        volume: volumeBlock,
        brightness: brightnessBlock,
        preferences: preferencesBlock,
        media: mediaBlock,
        weather: weatherBlock,
        calendar: calendarBlock,
        notifications: notificationsBlock,
        impasto: impastoBlock,
        clock: clockBlock,
    })

    Loader {
        anchors.fill: parent
        active: root.active
        sourceComponent: root.components[root.blockId] ?? null
    }

    Component {
        id: togglesBlock
        TogglesBlock {
            blockKey: root.blockKey
            cols: root.shape.cols
            rows: root.shape.rows
            onPanelRequested: panel => root.panelRequested(panel)
            onDismissed: root.dismissed()
        }
    }

    // Sliders are shorter than a cell and centred in it.
    Component {
        id: volumeBlock
        Item {
            SliderRow {
                anchors.centerIn: parent
                width: parent.width
                height: Math.min(parent.height, 48)
                icon: AudioService.icon
                value: AudioService.volume
                available: AudioService.ready
                dimmed: AudioService.muted
                onMoved: value => AudioService.setVolume(value)
                onIconClicked: AudioService.toggleMute()
            }
        }
    }

    Component {
        id: brightnessBlock
        Item {
            SliderRow {
                anchors.centerIn: parent
                width: parent.width
                height: Math.min(parent.height, 48)
                icon: BrightnessService.icon
                value: BrightnessService.percent
                from: 1
                available: BrightnessService.available
                onMoved: value => BrightnessService.setPercent(value)
            }
        }
    }

    Component {
        id: preferencesBlock
        PreferencesCard {}
    }

    Component {
        id: mediaBlock
        MediaCard {}
    }

    Component {
        id: weatherBlock
        WeatherCard {
            cols: root.shape.cols
            rows: root.shape.rows
        }
    }

    Component {
        id: calendarBlock
        CalendarCard { onPanelRequested: panel => root.panelRequested(panel) }
    }

    Component {
        id: notificationsBlock
        NotificationList {}
    }

    Component {
        id: impastoBlock
        ImpastoBlock {
            cols: root.shape.cols
            rows: root.shape.rows
        }
    }



    Component {
        id: clockBlock
        ClockBlock {
            cols: root.shape.cols
            rows: root.shape.rows
        }
    }

    // A note with no card around it. Clicking opens it for editing.

}
