import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"
import "../../components"

ColumnLayout {
    id: root
    signal closed()
    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Package updates"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMedium
        }
        PillButton {
            text: UpdatesService.checking ? "Checking…" : "Refresh"
            enabled: !UpdatesService.checking
            onClicked: UpdatesService.refresh()
        }
        PillButton { text: "Close"; onClicked: root.closed() }
    }
    Repeater {
        model: ["aur"]
        ColumnLayout {
            id: section
            required property string modelData
            readonly property var report: UpdatesService.aurReport
            readonly property string error: UpdatesService.aurError
            Layout.fillWidth: true
            Layout.fillHeight: true
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Arch / AUR"
                    color: Theme.text
                    font.family: Theme.fontFamily
                }
                PillButton {
                    text: "Check / notify"
                    enabled: !UpdatesService.busy && section.report !== null
                    onClicked: UpdatesService.update(section.modelData)
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
                    text: section.error || section.report?.tooltip || "Checking…"
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Theme.textMuted
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }
    }
}
