// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I S L A N D   R E S T                                                  │
// │   resting island · the clock and running activities                      │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell.Widgets

import "../../theme"
import "../../services"
import "../../components"
import "../modules"

// The island at rest: the clock in the middle, with a countdown or track
// either side while one is running.
//
// Privacy is independent from activities. When microphone or camera is active,
// the island grows to the right without changing the position/layout of the
// clock, media or timer.
Item {
    id: root

    readonly property var activities: ModuleService.activities
    readonly property bool split: root.activities.length === 1

    // A side under the pointer holds the glance off, so a click on the dot
    // never lands on a summary that opened under it.
    readonly property bool busy: leading.hovered || trailing.hovered

    // ── ORIGINAL ISLAND CONTENT ─────────────────────────────────────────────
    //
    // This keeps exactly the original clock/activity geometry. Privacy gets
    // its own space after this item instead of participating in activities.

    Item {
        id: content

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        width: ModuleService.restContentWidth

        ClockModule {
            anchors.centerIn: parent

            width: root.activities.length > 0
                ? ModuleService.clockCore
                : parent.width

            height: Theme.capsuleHeight
        }

        Segment {
            id: leading
            anchors.left: parent.left
            width: ModuleService.activitySide
            height: parent.height
            visible: root.activities.length > 0
            activityId: root.activities[0] ?? ""
            part: root.split ? "mark" : "both"
        }

        Segment {
            id: trailing
            anchors.right: parent.right
            width: ModuleService.activitySide
            height: parent.height
            visible: root.activities.length > 0
            activityId: root.split
                ? (root.activities[0] ?? "")
                : (root.activities[1] ?? "")
            part: root.split ? "figure" : "both"
        }
    }

    // ── PRIVACY ─────────────────────────────────────────────────────────────
    //
    // This is deliberately outside `content`. When privacy becomes active,
    // ModuleService.restWidth grows while restContentWidth stays unchanged.

    Item {
        id: privacy

        anchors.left: content.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        visible: PrivacyService.active

        Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                visible: PrivacyService.microphoneActive
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.indicatorBad
            }

            Text {
                visible: PrivacyService.cameraActive
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.indicatorBad
            }
        }
    }

    // ── ACTIVITY SEGMENT ────────────────────────────────────────────────────

    component Segment: Item {
        id: segment

        property string activityId: ""

        // "mark", "figure", or "both".
        property string part: "both"

        readonly property alias hovered: mouse.containsMouse

        readonly property var marks: ({
            timer: timerMark,
            media: mediaMark
        })

        readonly property var figures: ({
            timer: timerFigure,
            media: mediaFigure
        })

        Row {
            anchors.centerIn: parent
            spacing: 7
            Loader {
                anchors.verticalCenter: parent.verticalCenter
                active:
                    segment.part !== "figure"
                    && segment.activityId !== ""
                visible: active
                sourceComponent:
                    segment.marks[segment.activityId] ?? null
            }

            Loader {
                anchors.verticalCenter: parent.verticalCenter
                active:
                    segment.part !== "mark"
                    && segment.activityId !== ""
                visible: active
                sourceComponent:
                    segment.figures[segment.activityId] ?? null
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                ModuleService.activate(segment.activityId, "island")
            }
        }

        // ── COUNTDOWN ───────────────────────────────────────────────────────

        Component {
            id: timerMark

            RingIndicator {
                width: 16
                height: 16
                thickness: 2

                progress: TimerService.progress
                trackColor: Theme.indicatorDim
                fillColor: TimerService.tint
            }
        }

        Component {
            id: timerFigure

            Text {
                text: TimerService.display

                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold

                color:
                    TimerService.paused
                    ? Theme.textMuted
                    : Theme.text
            }
        }

        // ── TRACK ───────────────────────────────────────────────────────────
        //
        // The artwork, and the real spectrum: bars animated on a timer keep
        // moving through silence.

        Component {
            id: mediaMark

            ClippingRectangle {
                width: 20
                height: 20

                radius: width * Theme.pictureCorner
                color: Theme.islandSurfaceHover

                Component.onCompleted:
                    MediaService.subscribe()

                Component.onDestruction:
                    MediaService.release()

                Image {
                    id: art

                    anchors.fill: parent

                    source: MediaService.artUrl

                    visible:
                        source != ""
                        && status === Image.Ready

                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true

                    sourceSize.width: 40
                    sourceSize.height: 40
                }

                Text {
                    anchors.centerIn: parent

                    visible: !art.visible

                    text: "󰎇"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.indicator
                }
            }
        }

        Component {
            id: mediaFigure

            Spectrum {
                height: 14
                barWidth: 2
                minimum: 2

                active: MediaService.playing
                barColor: Theme.indicator

                Component.onCompleted:
                    CavaService.subscribe()

                Component.onDestruction:
                    CavaService.release()
            }
        }
    }
}
