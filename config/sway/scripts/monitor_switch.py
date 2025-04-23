#!/usr/bin/env python3

import gi
import subprocess

gi.require_version("Gtk", "4.0")
from gi.repository import Gdk, Gtk


class MonitorModeDialog(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="com.github.ScreenShare")

    def do_activate(self):
        # Janela principal
        self.window = Gtk.ApplicationWindow(application=self)
        self.window.set_title("Modo de exibição")
        self.window.set_default_size(300, 200)
        self.window.set_resizable(False)

        # Layout vertical
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        vbox.set_margin_top(15)
        vbox.set_margin_bottom(15)
        vbox.set_margin_start(15)
        vbox.set_margin_end(15)

        self.window.set_child(vbox)

        # Título
        label = Gtk.Label()
        label.set_markup('<span size="large" weight="bold">Select display mode:</span>')
        label.set_wrap(True)
        label.set_margin_bottom(5)
        vbox.append(label)

        options = [
            ("This monitor only", self.this_monitor),
            ("External monitor only", self.external_monitor),
            ("Duplicate", self.duplicate),
            ("Extend", self.extend),
        ]

        for text, handler in options:
            button = Gtk.Button(label=text)
            button.connect("clicked", handler)
            vbox.append(button)

        self.window.present()

    def get_screen_size(self):
        display = Gdk.Display.get_default()
        monitor = display.get_monitors()[0]
        geometry = monitor.get_geometry()
        return geometry.width, geometry.height

    def this_monitor(self, _):
        self.run_cmds(
            [
                ["swaymsg", "output", "eDP-1", "enable"],
                ["swaymsg", "output", "HDMI-A-1", "disable"],
            ]
        )

    def external_monitor(self, _):
        self.run_cmds(
            [
                ["swaymsg", "output", "eDP-1", "disable"],
                ["swaymsg", "output", "HDMI-A-1", "enable"],
            ]
        )

    def duplicate(self, _):
        self.run_cmds(
            [
                ["swaymsg", "output", "eDP-1", "enable", "position", "0", "0"],
                ["swaymsg", "output", "HDMI-A-1", "enable", "position", "0", "0"],
            ]
        )

    def extend(self, _):
        width = self.get_screen_size()[0]
        self.run_cmds(
            [
                ["swaymsg", "output", "eDP-1", "enable", "position", "0", "0"],
                [
                    "swaymsg",
                    "output",
                    "HDMI-A-1",
                    "enable",
                    "position",
                    str(width),
                    "0",
                ],
            ]
        )

    def run_cmds(self, cmds):
        for cmd in cmds:
            subprocess.run(cmd)
        self.quit()


if __name__ == "__main__":
    app = MonitorModeDialog()
    app.run()
