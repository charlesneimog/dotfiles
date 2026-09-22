// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P R I V A C Y   S E R V I C E                                        │
// │   live capture indicators from PipeWire and camera device users          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Bind links as well as nodes: link state and node properties are only
    // updated while tracked. Merely having a microphone plugged in is idle.
    PwObjectTracker {
        objects: [...Pipewire.nodes.values, ...Pipewire.links.values]
    }

    function captures(link, kind): bool {
        if (link.state !== PwLinkState.Active || !link.source || !link.target)
            return false

        const source = link.source
        const props = source.properties
        if (kind === "microphone") {
            // Speaker monitor streams (including Cava) are not microphone use.
            return source.audio !== null && !source.isSink && !source.isStream
                && props["device.class"] !== "monitor"
                && !source.name.endsWith(".monitor")
        }

        // Only camera sources, not the compositor's screen-sharing streams.
        return props["media.class"] === "Video/Source"
            && (props["media.role"] === "Camera"
                || props["device.api"] === "v4l2"
                || props["device.api"] === "libcamera"
                || !!props["api.v4l2.path"])
    }

    readonly property bool microphoneActive: Pipewire.ready
        && Pipewire.links.values.some(link => root.captures(link, "microphone"))
    readonly property bool cameraActive: root.directCameraActive
        || (Pipewire.ready
            && Pipewire.links.values.some(link => root.captures(link, "camera")))
    readonly property bool active: root.microphoneActive || root.cameraActive

    // Browsers can open V4L2 devices directly, without a PipeWire link.
    // fuser only inspects device users; it never opens or captures the camera.
    // Treat an open camera as in use even if its app has paused the preview.
    property bool directCameraActive: false

    Process {
        id: cameraProbe
        command: ["sh", "-c", "fuser -s /dev/video[0-9]* 2>/dev/null"]
        running: true
        onExited: (code, status) => root.directCameraActive = code === 0 && status === 0
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!cameraProbe.running)
                cameraProbe.running = true
        }
    }
}
