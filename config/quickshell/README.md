# Quickshell on Niri

The compact 18 px bar, dynamic island, launcher, desktop widgets and useful
system controls remain. Games, the Sprout pet, the settings window/menu,
the built-in lock screen, TODO/task board, notes, unused application dock
and their supporting files have been removed.
Older saved placements for removed widgets are ignored; saved note/task data
is left untouched.

Run from this checkout:

```sh
qs -p /home/neimog/Documents/Git/dotfiles/config/quickshell
```

`arch/link.sh` includes Quickshell. Run one bar at login: use `qs` instead
of Waybar in your startup routine.

## Waybar integrations

- Weather uses Waybar's `ipinfo.io` city lookup and wttr.in provider, with
  Portuguese descriptions and Celsius temperatures. It reads forecast JSON
  directly with `curl` and QML instead of a Python script. An existing
  `weatherPlace` setting overrides automatic location.
- If wttr.in fails, weather falls back to [Open-Meteo](https://open-meteo.com/en/docs).
  The provider appears in the weather detail. Requests have timeouts, keep
  the last good reading, and retry every 15 minutes even after initial failure.
- Arch/AUR and Flathub chips reuse `~/.functions.sh get_aur_waybar_icon` and
  `get_flatpak_waybar_icon`, with Waybar's 15-minute / 12-hour intervals.
  Clicking uses `update_aur_packages` / `update_flatpak_packages` respectively.
  The current AUR helper only checks and notifies; the Flatpak helper updates.
  The package panel shows both reports and offers the same actions.
- The launcher uses Quickshell's native desktop-entry index, including Flatpak
  applications exported through `XDG_DATA_DIRS`; no Python application scanner.
- Planify opens its Flatpak quick-add window. Audio uses PipeWire; right-click
  opens `com.saivert.pwvucontrol`, as configured in Waybar.

Weather needs `curl` and `jq`; update checks need your executable
`~/.functions.sh`, `paru` and `flatpak`. Remaining Python helpers support
network management, capture/recording, clipboard, themes and other retained
features. Weather, package updates/search and application indexing no longer
have Python helpers; unused font and compositor helpers are also removed.

## Locking and media

Quickshell manages idle timeouts directly, using the values in `services/Config.qml`.
Activity restores brightness and screen power. `Do Not Idle` disables these
actions without a helper process. Edit `idleDim`, `idleLock`,
`idleScreen`, and `idleSuspend` in `services/Config.qml`; all use seconds and zero disables
an action. Hypridle is no longer started or required. Idle and battery suspend
use Quickshell's lock-before-sleep path; external sleep requests are not handled
by the removed hypridle before-sleep hook.

Niri forwards lid switch events to Quickshell. Closing the laptop lid calls
`IdleService.lidClosed()` and locks with Hyprlock, even with `Do Not Idle`
enabled or an idle inhibitor active. Opening the lid does not unlock the session.
The system's existing logind lid suspend policy remains in effect.

Lock buttons and `qs ipc call lock toggle` launch Hyprlock with your existing
`config/hypr/hyprlock.conf`. Hyprlock runs independently of shell reloads;
Quickshell no longer provides PAM authentication or a lock surface. Suspend
waits for Niri's logind `LockedHint` confirmation and cancels if no confirmation
arrives within five seconds. Your existing Niri lock shortcut already runs
Hyprlock through `~/.functions.sh`.

Media uses `playerctl --ignore-player=playerctld` to query actual players,
avoiding the empty playerctld proxy's D-Bus errors. `playerctl` is required.
The clipboard watcher shuts down cleanly on reload and retries after failures.

## Layout and IPC

The bar uses separate left, clock and right groups with transparent gaps,
even if older saved settings request a full-width strip. The default left
group contains weather, AUR, Flathub and Niri workspaces.
Saved layouts remain in `$XDG_STATE_HOME/quickshell/settings.json` (normally
`~/.local/state/quickshell/settings.json`). Defaults skip modules already on
the opposite saved side. Internal settings storage remains necessary for
layouts and service preferences; there is no settings window or settings IPC.
Niri input and keybindings stay in `config/niri/config.kdl`. The Monitors panel
applies temporary output changes without editing that file.

```kdl
Mod+S { spawn "qs" "ipc" "call" "controls" "toggle"; }
```

Other panel targets include `launcher`, `session`, `keys`, `packages` and
`monitors`, each with `toggle`. In the launcher, type `>` to find these entries.
Keys opens Niri's native shortcut overlay. Packages shows Arch/AUR and Flatpak
updates; update buttons run `paru -Syu` or `flatpak update` in Ghostty.

Monitors offers notebook only, external only, extended, and duplicate modes.
External only enables all connected external screens. Extend places screens
side by side with the notebook first, preserving their resolution and scale.
Duplicate requires `wl-mirror` and opens a fullscreen mirror of the notebook
on each external screen (Niri has no native output cloning). Choosing another
mode stops those mirrors. Unavailable modes are disabled. Output changes last
until Niri restarts or its output configuration is reloaded; they are not saved.
`qs ipc call shell status` reports Niri, audio, network, weather provider,
application count and pending package updates.
