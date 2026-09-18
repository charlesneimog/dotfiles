// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P R I V A C Y   S E R V I C E                                          │
// │   microphone and camera activity                                         │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property bool microphoneActive: false
    property bool cameraActive: false

    readonly property bool active:
        microphoneActive || cameraActive

    // ── MICROPHONE ──────────────────────────────────────────────────────────

    function isMicrophone(node): bool {
        if (!node)
            return false

        return node.audio !== null
            && !node.isStream
            && !node.isSink
    }

    function updateMicrophone(): void {
        let active = false

        for (let i = 0; i < links.count; ++i) {
            const object = links.objectAt(i)

            if (!object)
                continue

            const link = object.modelData

            if (!link || !link.source || !link.target)
                continue

            if (root.isMicrophone(link.source)
                    && link.target.isStream) {
                active = true
                break
            }
        }

        root.microphoneActive = active
    }

    Instantiator {
        id: links

        model: Pipewire.linkGroups

        delegate: QtObject {
            required property var modelData
        }

        onObjectAdded: (index, object) => {
            Qt.callLater(root.updateMicrophone)
        }

        onObjectRemoved: (index, object) => {
            Qt.callLater(root.updateMicrophone)
        }
    }

    // ── CAMERA ──────────────────────────────────────────────────────────────
    //
    // Video capture does not appear in Pipewire.linkGroups on this system.
    // Detect whether one of the V4L2 devices is currently opened instead.

    Process {
        id: cameraCheck

        command: [
            "sh",
            "-c",
            "fuser /dev/video* >/dev/null 2>&1"
        ]

        onExited: exitCode => {
            root.cameraActive = exitCode === 0
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: {
            if (!cameraCheck.running)
                cameraCheck.running = true
        }
    }

    // ── DEBUG ───────────────────────────────────────────────────────────────

    onMicrophoneActiveChanged: {
        console.log(
            "Privacy: microphone",
            microphoneActive ? "ACTIVE" : "inactive"
        )
    }

    onCameraActiveChanged: {
        console.log(
            "Privacy: camera",
            cameraActive ? "ACTIVE" : "inactive"
        )
    }

    Component.onCompleted: {
        Qt.callLater(root.updateMicrophone)
        cameraCheck.running = true
    }
}
