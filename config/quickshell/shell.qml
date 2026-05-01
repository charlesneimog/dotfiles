import Quickshell
import Quickshell.Wayland
import QtQuick


PanelWindow {
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 20
    color: "#1a1b26"

    Text {
        anchors.centerIn: parent
        text: "My Bar"
        color: "#a9b1d6"
    }
}
