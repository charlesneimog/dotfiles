// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   U P D A T E S                                                          │
// │   Arch / AUR and Flatpak updates                                         │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import "../../../theme"
import "../../../services"
import "../../../components"

Rectangle {
    id: root

    readonly property int aurUpdates:
        Number(UpdatesService.aurReport?.alt ?? 0)

    readonly property int flatpakUpdates:
        Number(UpdatesService.flatpakReport?.alt ?? 0)

    readonly property int updates:
        aurUpdates + flatpakUpdates

    radius: Theme.radiusMedium
    color: Theme.islandSurface

    border.color: Theme.islandBorder
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // ── HEADER ──────────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Text {
                text: "󰏖"
                color: Theme.textMuted

                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSmall
            }

            Text {
                Layout.fillWidth: true

                text: "Updates"
                color: Theme.text

                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
            }

            Rectangle {
                visible: root.updates > 0

                implicitWidth: Math.max(
                    18,
                    updateCount.implicitWidth + 10
                )

                implicitHeight: 17
                radius: height / 2
                color: Theme.islandSurfaceHover

                Text {
                    id: updateCount

                    anchors.centerIn: parent

                    text: root.updates
                    color: Theme.textMuted

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLabel
                    font.weight: Font.DemiBold
                }
            }
        }

        // ── PACKAGES ────────────────────────────────────────────────────────

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentHeight: packageList.implicitHeight
            clip: true

            Column {
                id: packageList

                width: parent.width
                spacing: 10

                // ── ARCH / AUR ──────────────────────────────────────────────

                Column {
                    width: parent.width
                    spacing: 3

                    Row {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: ""
                            color: Theme.textMuted

                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeLabel
                        }

                        Text {
                            text: "Arch / AUR"
                            color: Theme.text

                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLabel
                            font.weight: Font.DemiBold
                        }

                        Text {
                            visible: root.aurUpdates > 0

                            text: `${root.aurUpdates}`
                            color: Theme.textMuted

                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLabel
                        }
                    }

                    Text {
                        width: parent.width

                        text:
                            UpdatesService.aurError
                            || UpdatesService.aurReport?.tooltip
                            || "Checking…"

                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap

                        color: Theme.textMuted

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLabel
                    }
                }

                // ── FLATPAK ─────────────────────────────────────────────────

                Column {
                    width: parent.width
                    spacing: 3

                    Row {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: ""
                            color: Theme.textMuted

                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeLabel
                        }

                        Text {
                            text: "Flatpak"
                            color: Theme.text

                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLabel
                            font.weight: Font.DemiBold
                        }

                        Text {
                            visible: root.flatpakUpdates > 0

                            text: `${root.flatpakUpdates}`
                            color: Theme.textMuted

                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLabel
                        }
                    }

                    Text {
                        width: parent.width

                        text:
                            UpdatesService.flatpakError
                            || UpdatesService.flatpakReport?.tooltip
                            || "Checking…"

                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap

                        color: Theme.textMuted

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLabel
                    }
                }
            }
        }

        // ── ACTIONS ─────────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            PillButton {
                text: UpdatesService.checking
                    ? "Checking…"
                    : "Refresh"

                enabled:
                    !UpdatesService.checking
                    && !UpdatesService.busy

                onClicked: UpdatesService.refresh()
            }

            Item {
                Layout.fillWidth: true
            }

            PillButton {
                visible: root.aurUpdates > 0

                text: UpdatesService.busy
                    ? "Updating…"
                    : "Arch / AUR"

                enabled:
                    !UpdatesService.busy
                    && !UpdatesService.checking
                    && !UpdatesService.aurError
                    && root.aurUpdates > 0

                onClicked:
                    UpdatesService.update("aur")
            }

            PillButton {
                visible: root.flatpakUpdates > 0

                text: UpdatesService.busy
                    ? "Updating…"
                    : "Flatpak"

                enabled:
                    !UpdatesService.busy
                    && !UpdatesService.checking
                    && !UpdatesService.flatpakError
                    && root.flatpakUpdates > 0

                onClicked:
                    UpdatesService.update("flatpak")
            }
        }
    }
}
