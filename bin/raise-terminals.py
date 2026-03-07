#!/usr/bin/env python3

import gi

gi.require_version("Wnck", "3.0")
from gi.repository import Wnck


TERMINAL_CLASSES = {
    "com.mitchellh.ghostty",
    "Gnome-terminal",
    "org.gnome.Console",
    "kitty",
    "Alacritty",
    "org.wezfurlong.wezterm",
    "Tilix",
    "terminator",
    "XTerm",
    "Konsole",
}


def is_terminal(window: Wnck.Window) -> bool:
    class_group = window.get_class_group_name()
    return bool(class_group and class_group in TERMINAL_CLASSES)


screen = Wnck.Screen.get_default()
screen.force_update()

workspace = screen.get_active_workspace()

terminal_windows = [window for window in screen.get_windows() if is_terminal(window)]

for window in terminal_windows:
    if window.is_minimized():
        window.unminimize(0)
    if workspace is not None and window.get_workspace() != workspace:
        window.move_to_workspace(workspace)
    window.activate(0)
