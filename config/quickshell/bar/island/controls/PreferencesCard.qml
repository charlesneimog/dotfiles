// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   U P D A T E S                                                          │
// │   Flatpak system updates                                                 │
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

    readonly property int updates:
        Number(UpdatesService.flatpakReport?.alt ?? 0)

    radius: Theme.radiusMedium
    color: Theme.islandSurface
    border.color: Theme.islandBorder
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

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
                text: "Flatpak updates"
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

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentHeight: details.implicitHeight
            clip: true

            Text {
                id: details

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

        RowLayout {
            Layout.fillWidth: true

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
                text: UpdatesService.busy
                    ? "Updating…"
                    : "Update"

                enabled:
                    !UpdatesService.busy
                    && !UpdatesService.checking
                    && !UpdatesService.flatpakError
                    && root.updates > 0

                onClicked: UpdatesService.update("flatpak")
            }
        }
    }
}
