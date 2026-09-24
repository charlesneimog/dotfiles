// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I D L E   S E R V I C E                                                │
// │   idle actions · lock, screen off and suspend timeouts                   │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Quickshell owns dimming, locking, screen power and idle suspend.
// IdleMonitor follows compositor activity and respects video-player inhibitors.
// Do Not Idle disables these monitors; explicit and low-battery sleep still work.
Singleton {
    id: root

    // Manual "Do Not Idle" state.
    property bool inhibited: false
    Component.onCompleted: { void BrightnessService.available }

    // Serialise dim/restore commands so input during dimming still restores.
    property bool dimWanted: false
    property int savedBrightness: -1
    readonly property Process brightness: Process {
        property bool dimming: false
        onExited: code => {
            if (code !== 0) {
                console.warn("Could not change idle brightness:", code)
                return
            }
            if (!dimming) root.savedBrightness = -1
            if (root.dimWanted !== dimming) root.setDimmed(root.dimWanted)
        }
    }

    function setDimmed(dim: bool): void {
        root.dimWanted = dim
        if (root.brightness.running) return
        if (dim) {
            if (!BrightnessService.available || root.savedBrightness >= 0) return
            root.savedBrightness = BrightnessService.raw
            root.brightness.command = ["brightnessctl", "--quiet", "--device",
                BrightnessService.device, "set", String(Math.min(10, root.savedBrightness))]
        } else {
            if (root.savedBrightness < 0) return
            root.brightness.command = ["brightnessctl", "--quiet", "--device",
                BrightnessService.device, "set", String(root.savedBrightness)]
        }
        root.brightness.dimming = dim
        root.brightness.running = true
    }

    readonly property IdleMonitor dimWatch: IdleMonitor {
        enabled: !root.inhibited && Config.idleDim > 0
        timeout: Config.idleDim
        respectInhibitors: true
        onIsIdleChanged: root.setDimmed(dimWatch.isIdle && !root.inhibited)
    }

    // All timeouts use seconds, matching IdleMonitor.
    readonly property int lockAfter: Config.idleLock
    readonly property int screenAfter: Config.idleScreen
    readonly property int suspendAfter: Config.idleSuspend

    readonly property IdleMonitor lockWatch: IdleMonitor {
        enabled: !root.inhibited && root.lockAfter > 0
        timeout: root.lockAfter
        respectInhibitors: true

        // `lock()` is a no-op when already locked.
        onIsIdleChanged: {
            if (lockWatch.isIdle && !root.inhibited)
                LockService.lock()
        }
    }

    readonly property IdleMonitor screenWatch: IdleMonitor {
        enabled: !root.inhibited && root.screenAfter > 0
        timeout: root.screenAfter
        respectInhibitors: true

        onIsIdleChanged: {
            root.screen(!screenWatch.isIdle || root.inhibited)
        }
    }

    readonly property IdleMonitor sleepWatch: IdleMonitor {
        enabled: !root.inhibited && root.suspendAfter > 0
        timeout: root.suspendAfter
        respectInhibitors: true

        // The session action locks and waits for the compositor to confirm
        // before suspending.
        onIsIdleChanged: {
            if (sleepWatch.isIdle && !root.inhibited)
                SessionService.run("suspend")
        }
    }

    function toggleInhibit(): void {
        root.inhibited = !root.inhibited
        if (root.inhibited) {
            root.setDimmed(false)
            root.screen(true)
        }
    }

    Component.onDestruction: {
        if (root.savedBrightness >= 0)
            Quickshell.execDetached(["brightnessctl", "--quiet", "--device",
                BrightnessService.device, "set", String(root.savedBrightness)])
    }

    function screen(on: bool): void {
        if (NiriService.active)
            NiriService.dispatch(
                on
                    ? { PowerOnMonitors: {} }
                    : { PowerOffMonitors: {} }
            )
    }
}
