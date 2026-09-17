import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import "../../../theme"
import "../../../services"
import "../../../components"

Rectangle {
    id: root

    // System application theme only; the shell keeps its own palette.
    property bool dark: true
    property bool themeReady: false
    readonly property int updates: Number(UpdatesService.flatpakReport?.alt ?? 0)

    function readTheme(output: string): void {
        try {
            const report = JSON.parse(output)
            if (report.alt !== "dark" && report.alt !== "light")
                throw new Error("Invalid theme")
            root.dark = report.alt === "dark"
            root.themeReady = true
        } catch (error) {
            root.themeReady = false
            console.warn("Could not read system theme:", error)
        }
    }

    Process {
        id: themeQuery
        command: ["bash", "-c", 'exec "$HOME/.functions.sh" get_theme']
        running: true
        stdout: StdioCollector { onStreamFinished: root.readTheme(text) }
        onExited: code => { if (code !== 0) root.themeReady = false }
    }

    Process {
        id: themeChange
        command: ["bash", "-c", 'exec "$HOME/.functions.sh" change_theme']
        onExited: { themeQuery.running = true }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            if (!themeQuery.running && !themeChange.running)
                themeQuery.running = true
        }
    }

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
            Text {
                text: root.dark ? "" : ""
                color: Theme.text
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSmall
            }
            Text {
                Layout.fillWidth: true
                text: root.dark ? "Dark theme" : "Light theme"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
            }
            ToggleSwitch {
                checked: root.dark
                enabled: root.themeReady && !themeQuery.running && !themeChange.running
                onToggled: { themeChange.running = true }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.islandBorder
        }

        Text {
            Layout.fillWidth: true
            text: "Flatpak updates"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.DemiBold
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: details.implicitHeight
            clip: true
            Text {
                id: details
                width: parent.width
                text: UpdatesService.flatpakError || UpdatesService.flatpakReport?.tooltip || "Checking…"
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
                text: UpdatesService.checking ? "Checking…" : "Refresh"
                enabled: !UpdatesService.checking && !UpdatesService.busy
                onClicked: UpdatesService.refresh()
            }
            Item { Layout.fillWidth: true }
            PillButton {
                text: UpdatesService.busy ? "Updating…" : "Update"
                enabled: !UpdatesService.busy && !UpdatesService.checking
                    && !UpdatesService.flatpakError && root.updates > 0
                onClicked: UpdatesService.update("flatpak")
            }
        }
    }
}
