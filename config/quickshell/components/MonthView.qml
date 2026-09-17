import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"

// Shared calendar, without task storage or task-board actions.
ColumnLayout {
    id: root
    property color ink: Theme.text
    property int offsetMonths: 0
    readonly property date month: new Date(clock.date.getFullYear(), clock.date.getMonth() + offsetMonths, 1)
    readonly property int leading: (month.getDay() + 6) % 7
    spacing: 4

    SystemClock { id: clock; precision: SystemClock.Minutes }
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "‹"
            color: root.ink
            font.pixelSize: 18
            TapHandler { onTapped: root.offsetMonths-- }
        }
        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(root.month, "MMMM yyyy")
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: root.ink
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            TapHandler { onTapped: root.offsetMonths = 0 }
        }
        Text {
            text: "›"
            color: root.ink
            font.pixelSize: 18
            TapHandler { onTapped: root.offsetMonths++ }
        }
    }
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 2
        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Text {
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                horizontalAlignment: Text.AlignHCenter
                color: root.ink
                opacity: 0.6
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeLabel
            }
        }
        Repeater {
            model: 42
            Rectangle {
                id: cell
                required property int index
                readonly property date day: new Date(root.month.getFullYear(), root.month.getMonth(), index - root.leading + 1)
                readonly property bool today: Qt.formatDate(day, "yyyy-MM-dd") === Qt.formatDate(clock.date, "yyyy-MM-dd")
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 24
                Layout.preferredHeight: 20
                radius: 4
                color: today ? Theme.accent : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: cell.day.getDate()
                    color: cell.today ? Theme.island : root.ink
                    opacity: cell.day.getMonth() === root.month.getMonth() ? 1 : 0.3
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLabel
                }
            }
        }
    }
}
