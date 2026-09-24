"""Monitor safety checks without changing the real compositor."""
import copy
import unittest
from unittest.mock import patch

import niri_displays as displays


def output(name, enabled=True):
    return {"name": name, "current_mode": 0 if enabled else None,
            "logical": {"x": 0, "y": 0, "width": 1920} if enabled else None}


class DisplayTests(unittest.TestCase):
    def setUp(self):
        self.state = [output("eDP-1"), output("HDMI-A-1")]
        self.commands = []
        self.fail_on = None
        self.enterContext(patch.object(displays, "outputs", side_effect=lambda: copy.deepcopy(self.state)))
        self.enterContext(patch.object(displays, "configure", side_effect=self.configure))
        self.enterContext(patch.object(displays.shutil, "which", return_value="/usr/bin/wl-mirror"))

    def configure(self, name, *args):
        self.commands.append((name, *args))
        if self.fail_on == (name, *args):
            self.fail_on = None
            raise RuntimeError("Disconnected")
        monitor = next(o for o in self.state if o["name"] == name)
        if args[0] == "on":
            monitor.update(output(name))
        elif args[0] == "off":
            monitor.update(output(name, False))

    def test_external_enables_destination_before_disabling_notebook(self):
        self.state[1] = output("HDMI-A-1", False)
        displays.apply("external")
        self.assertLess(self.commands.index(("HDMI-A-1", "on")),
                        self.commands.index(("eDP-1", "off")))

    def test_notebook_enables_panel_before_disabling_external(self):
        self.state[0] = output("eDP-1", False)
        displays.apply("notebook")
        self.assertLess(self.commands.index(("eDP-1", "on")),
                        self.commands.index(("HDMI-A-1", "off")))

    def test_extend_positions_outputs_side_by_side(self):
        displays.apply("extend")
        self.assertIn(("eDP-1", "position", "set", "0", "0"), self.commands)
        self.assertIn(("HDMI-A-1", "position", "set", "1920", "0"), self.commands)
        self.assertFalse(any(c[1] == "off" for c in self.commands))

    def test_duplicate_returns_each_external_target(self):
        self.state.append(output("DP-2"))
        result = displays.apply("duplicate")
        self.assertEqual(result, {"source": "eDP-1", "targets": ["DP-2", "HDMI-A-1"]})

    def test_missing_dependency_changes_nothing(self):
        with patch.object(displays.shutil, "which", return_value=None):
            with self.assertRaisesRegex(RuntimeError, "wl-mirror"):
                displays.apply("duplicate")
        self.assertEqual(self.commands, [])

    def test_no_external_changes_nothing(self):
        self.state.pop()
        for mode in ("external", "extend", "duplicate"):
            with self.assertRaisesRegex(RuntimeError, "external"):
                displays.apply(mode)
        self.assertEqual(self.commands, [])

    def test_failed_change_restores_original_enabled_state(self):
        self.state[0] = output("eDP-1", False)
        self.fail_on = ("HDMI-A-1", "off")
        with self.assertRaisesRegex(RuntimeError, "Disconnected"):
            displays.apply("notebook")
        self.assertIsNone(self.state[0]["current_mode"])
        self.assertIsNotNone(self.state[1]["current_mode"])

    def test_unplug_during_recovery_reenables_notebook(self):
        before = [output("eDP-1", False), output("HDMI-A-1")]
        self.state = [output("eDP-1", False)]
        displays.restore(before)
        self.assertEqual(self.commands, [("eDP-1", "on")])


if __name__ == "__main__":
    unittest.main()
