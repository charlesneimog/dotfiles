import QtQuick
import QtQuick.Layouts

import "../../theme"
import "../../services"
import "../../components"

ColumnLayout {
    id: root
    spacing: 10
    Component.onCompleted: DisplayModeService.refresh()

    Text {
        text: "Monitors"
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
    }

    Text {
        Layout.fillWidth: true
        text: DisplayModeService.outputs.map(o => o.name + (o.current_mode === null ? " (off)" : "")).join(" · ") || "Reading monitors…"
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
    }

    Repeater {
        model: [
            {mode: "notebook", label: "Notebook only", available: DisplayModeService.hasNotebook},
            {mode: "external", label: "External only", available: DisplayModeService.hasExternal},
            {mode: "extend", label: "Extend monitors", available: DisplayModeService.hasExternal},
            {mode: "duplicate", label: "Duplicate monitors", available: DisplayModeService.hasNotebook && DisplayModeService.hasExternal && DisplayModeService.canMirror}
        ]
        PillButton {
            required property var modelData
            Layout.fillWidth: true
            text: modelData.label
            enabled: modelData.available && !DisplayModeService.busy
            active: modelData.mode === "duplicate" && DisplayModeService.duplicating
            onClicked: DisplayModeService.apply(modelData.mode)
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.fillHeight: true
        text: DisplayModeService.error || (DisplayModeService.busy ? "Applying…"
            : !DisplayModeService.canMirror ? "Install wl-mirror to enable duplication. Changes last for this session."
            : "Changes last for this session. Duplicate mirrors the notebook to the external screens.")
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: DisplayModeService.refresh()
    }
}
