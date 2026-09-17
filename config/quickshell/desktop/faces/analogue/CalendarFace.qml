import QtQuick
import "../../../components"
import "../../../services"

Item {
    property string family: "2x2"
    property var ink: DesktopService.inkFor(null)
    MonthView {
        anchors.fill: parent
        anchors.margins: 10
        ink: parent.ink.text
    }
}
