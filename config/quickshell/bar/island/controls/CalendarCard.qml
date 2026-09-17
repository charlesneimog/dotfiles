import QtQuick
import "../../../components"

Card {
    signal panelRequested(string panel)
    MonthView { anchors.fill: parent }
}
