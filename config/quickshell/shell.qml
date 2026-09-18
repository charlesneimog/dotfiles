//@ pragma UseQApplication
//@ pragma IconTheme Tela-circle
// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S H E L L                                                              │
// │   quickshell entry point · windows and top-level wiring                  │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Io

import "./bar"
import "./services"

// Entry point: the windows, the services that must start at boot, and the
// wiring between services that may not reference each other.
ShellRoot {
    id: root

    // Singletons are built on first use. Each of these has to be running from
    // boot, not from the moment a panel first reads it.
    Component.onCompleted: {

        // Restores the saved palette.
        void ThemeService.activeId
        // Builds the launcher index ahead of the first open.
        void LauncherService.applications
        // Starts the Niri event stream.
        void NiriService.workspaces
        // Re-applies the monitor arrangement kept for this set of screens.
        void MonitorService.loaded
        // Niri key bindings remain in config.kdl.
        // Reads the user name for the system information block.
        void AccountService.user
        // Starts the clipboard watcher.
        void ClipboardService.count
        // Restores the night light.
        void SunsetService.available
        // Arms the idle monitors.
        void IdleService.lockAfter

    console.log("PrivacyService loaded:", PrivacyService.active)
    }

    // ── SCREENS ─────────────────────────────────────────────────────────────
    //
    // Single-screen surfaces are Variants over a list of one. A PanelWindow
    // whose ShellScreen is destroyed (output unplugged) does not recover when
    // handed a new one; Variants destroys and rebuilds the window with the
    // list, which does.
    readonly property var primaryScreens: {
        const chosen = MonitorService.primaryScreen
        return chosen ? [chosen] : []
    }

    // Built rather than filtered: `Quickshell.screens` is a QML list and has
    // no `filter`.
    readonly property var secondaryScreens: {
        const rest = []
        for (const screen of Quickshell.screens)
            if (!MonitorService.isPrimary(screen))
                rest.push(screen)
        return rest
    }

    // Follows the bar when it is rebuilt on another screen.
    readonly property var island: islandBars.instances[0]?.island ?? null

    // ── BARS ────────────────────────────────────────────────────────────────
    //
    // One island, on the primary screen; every other screen gets a bar
    // without it. Two islands would draw the same state twice.
    Variants {
        id: islandBars
        model: root.primaryScreens
        Bar {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: root.secondaryScreens

        SecondBar {
            required property var modelData

            screen: modelData
        }
    }

    // ERROR:
    // Variants {
    //     model: root.primaryScreens
    //
    //     Desktop {
    //         required property var modelData
    //
    //         screen: modelData
    //     }
    // }

    // Optional clipboard wipe on lock. Joined here so neither service depends
    // on the other. Password-manager copies are never stored in the first
    // place; this covers everything else.
    Connections {
        target: LockService
        function onLockedChanged(): void {
            if (LockService.locked && Config.clipboardWipeOnLock)
                ClipboardService.wipe()
        }
    }

    // Niri shortcuts: config.kdl can invoke these IPC targets; the action
    // lives here, so a new panel needs no compositor config.
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.island?.toggle("launcher")
        }
    }

    // ── LID ─────────────────────────────────────────────────────────────────
    //
    // Handled here rather than with `switch:` binds in Lua. MonitorService's
    // display profile is the one owner of whether the panel is lit, and it is
    // re-applied on hotplug and after config reloads. A `switch:` bind in the
    // same file as `hl.monitor()` calls is also silently not registered, and
    // a runtime monitor rule does not survive a reload.
    IpcHandler {
        target: "lidClosed"
        function toggle(): void {
            MonitorService.lid(true)
        }
    }

    IpcHandler {
        target: "lidOpened"
        function toggle(): void {
            MonitorService.lid(false)
        }
    }

    IpcHandler {
        target: "controls"
        function toggle(): void {
            root.island?.toggle("controls")
        }
    }


    IpcHandler {
        target: "session"
        function toggle(): void {
            root.island?.toggle("session")
        }
    }

    IpcHandler {
        target: "lock"
        function toggle(): void {
            LockService.lock()
        }
    }



    // Same panel, on the palette strip. Each name only closes from its own
    // strip.
    IpcHandler {
        target: "palette"
        function toggle(): void {
            root.island?.toggle("palette")
        }
    }

    // The clipboard is a launcher mode: pressed again on that mode it closes,
    // pressed on another mode it switches. The query is set before opening
    // because with `launcherFits` the panel's height depends on it, and the
    // island is sized before the panel exists.
    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            const sigil = Config.launcherPrefix("clipboard")
            const showing = root.island?.state.openPanel === "launcher"
            if (showing && LauncherService.query.startsWith(sigil)) {
                root.island?.close()
                return
            }
            LauncherService.query = sigil
            root.island?.open("launcher")
        }
    }

    IpcHandler {
        target: "theme"
        function select(id: string): string {
            if (id !== "adaptive" && !ThemeService.availableThemes.some(theme => theme.id === id))
                return "Unknown theme: " + id
            ThemeService.setTheme(id)
            return id
        }
        function current(): string { return ThemeService.activeId }
    }

    IpcHandler {
        target: "bar"
        function openModule(module: string): void {
            if (["network", "volume", "brightness"].indexOf(module) >= 0)
                islandBars.instances[0]?.activate(module, "ipc")
        }
        function close(): void { islandBars.instances[0]?.dismiss() }
    }

    // `./setup sync` calls this once every file has landed. The reload the
    // shell starts on its own when a file changes can begin before the last
    // one is written, and then never sees it:
    //   qs ipc call shell reload
    IpcHandler {
        target: "shell"

        function status(): string {
            return JSON.stringify({
                workspaces: NiriService.workspaces.length,
                activeWorkspace: NiriService.activeId,
                audioReady: AudioService.ready, volume: AudioService.volume,
                wifiEnabled: NetworkService.wifiEnabled,
                wifiConnected: NetworkService.wifiConnected,
                network: NetworkService.connectionName,
                font: Config.fontMono,
                weatherAvailable: WeatherService.available,
                weatherPlace: WeatherService.place,
                weatherProvider: WeatherService.provider,
                weatherError: WeatherService.error,
                applications: LauncherService.applications.length,
                packageUpdates: UpdatesService.count,
                lockBackend: "hyprlock",
                barStyle: Config.barStyle,
                clipboardWatcher: ClipboardService.watcher.running,
                mediaPlayer: MediaService.identity
            })
        }

        function reload(): void {
            Quickshell.reload(false)
        }
    }


    // Privacy module

}
