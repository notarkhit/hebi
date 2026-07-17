pragma Singleton

import QtQuick
import Quickshell
import "../../services"

// Tokyo Night — Night variant
Singleton {
    // Base colours
    readonly property color base:     Theme.surfaceHex   // bg
    readonly property color mantle:   Theme.surfaceHex   // bg_dark
    readonly property color crust:    "#13131c"   // deeper dark
    readonly property color surface0: Theme.surfaceHex   // bg_float
    readonly property color surface1: Theme.surfaceVariant   // bg_highlight
    readonly property color surface2: Theme.surfaceVariant   // fg_gutter
    readonly property color overlay0: Theme.subtext   // dark3
    readonly property color overlay1: "#737aa2"   // dark5
    readonly property color overlay2: Theme.secondary   // fg_dark
    readonly property color subtext0: Theme.secondary   // fg_dark
    readonly property color subtext1: Theme.text   // fg (light)
    readonly property color text:     Theme.text   // fg

    // Accent colours
    readonly property color rosewater: Theme.error  // red
    readonly property color flamingo:  Theme.warning  // orange
    readonly property color pink:      "#ff007c"  // magenta2
    readonly property color mauve:     Theme.warning  // purple
    readonly property color red:       Theme.error
    readonly property color maroon:    "#db4b4b"  // red1
    readonly property color peach:     Theme.warning  // orange
    readonly property color yellow:    Theme.warning
    readonly property color green:     Theme.success
    readonly property color teal:      "#73daca"  // green1
    readonly property color sky:       Theme.secondary  // cyan
    readonly property color sapphire:  "#2ac3de"  // blue1
    readonly property color blue:      Theme.accent
    readonly property color lavender:  Theme.warning  // purple
}
