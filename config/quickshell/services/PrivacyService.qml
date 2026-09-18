// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P R I V A C Y   S E R V I C E                                        │
// │   temporarily disabled                                                   │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool microphoneActive: false
    readonly property bool cameraActive: false
    readonly property bool active: false
}
