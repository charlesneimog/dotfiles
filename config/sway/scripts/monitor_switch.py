#!/usr/bin/env python3

import gi
import subprocess
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk

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
        self.window.set_child(vbox)

        # Título
        label = Gtk.Label(label="Selecione o modo de exibição:")
        label = Gtk.Label(label="Select display mode:")
        label.set_wrap(True)
        label.set_margin_bottom(6)
        vbox.append(label)

        options = [
            ("This monitor only", self.this_monitor),
            ("External monitor only", self.external_monitor),
            ("Duplicate", self.duplicate),
            ("Extend", self.extend)
        ]

        for text, handler in options:
            button = Gtk.Button(label=text)
            button.connect("clicked", handler)
            vbox.append(button)

        self.window.present()

    def this_monitor(self, _):
        self.run_cmds([
            ["swaymsg", "output", "eDP-1", "enable"],
            ["swaymsg", "output", "HDMI-A-1", "disable"]
        ])

    def external_monitor(self, _):
        self.run_cmds([
            ["swaymsg", "output", "eDP-1", "disable"],
            ["swaymsg", "output", "HDMI-A-1", "enable"]
        ])

    def duplicate(self, _):
        self.run_cmds([
            ["swaymsg", "output", "eDP-1", "enable", "position", "0", "0"],
            ["swaymsg", "output", "HDMI-A-1", "enable", "position", "0", "0"]
        ])

    def extend(self, _):
        self.run_cmds([
            ["swaymsg", "output", "eDP-1", "enable", "position", "0", "0"],
            ["swaymsg", "output", "HDMI-A-1", "enable", "position", "1920", "0"]
        ])

    def run_cmds(self, cmds):
        for cmd in cmds:
            subprocess.run(cmd)
        self.quit()

if __name__ == "__main__":
    app = MonitorModeDialog()
    app.run()

