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
import Quickshell.Wayland

// Idle lock, screen off and suspend, in place of hypridle.
//
// Quickshell's `IdleMonitor` speaks `ext-idle-notify` directly, so timeouts
// follow the settings live with no daemon to restart. A timeout of zero means
// never. `respectInhibitors` lets video players hold all three off.
//
// `inhibited` provides a manual "Do Not Idle" mode. While enabled, all three
// monitors are disabled, preventing automatic lock, screen off and suspend.
Singleton {
    id: root

    // Manual "Do Not Idle" state.
    property bool inhibited: false

    // Minutes; `IdleMonitor` takes seconds.
    readonly property int lockAfter: Config.idleLock
    readonly property int screenAfter: Config.idleScreen
    readonly property int suspendAfter: Config.idleSuspend

    readonly property IdleMonitor lockWatch: IdleMonitor {
        enabled: !root.inhibited && root.lockAfter > 0
        timeout: root.lockAfter * 60
        respectInhibitors: true

        // `lock()` is a no-op when already locked.
        onIsIdleChanged: {
            if (lockWatch.isIdle)
                LockService.lock()
        }
    }

    readonly property IdleMonitor screenWatch: IdleMonitor {
        enabled: !root.inhibited && root.screenAfter > 0
        timeout: root.screenAfter * 60
        respectInhibitors: true

        onIsIdleChanged: {
            root.screen(!screenWatch.isIdle)
        }
    }

    readonly property IdleMonitor sleepWatch: IdleMonitor {
        enabled: !root.inhibited && root.suspendAfter > 0
        timeout: root.suspendAfter * 60
        respectInhibitors: true

        // The session action locks and waits for the compositor to confirm
        // before suspending.
        onIsIdleChanged: {
            if (sleepWatch.isIdle)
                SessionService.run("suspend")
        }
    }

    function toggleInhibit(): void {
        inhibited = !inhibited

        // If the screen was turned off by the idle monitor, make sure it is
        // turned back on when entering Do Not Idle mode.
        if (inhibited)
            screen(true)
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
