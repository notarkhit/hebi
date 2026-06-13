pragma Singleton

import QtQuick
import Quickshell

// Tokyo Night — Night variant
Singleton {
    // Base colours
    readonly property color base:     "#1a1b26"   // bg
    readonly property color mantle:   "#16161e"   // bg_dark
    readonly property color crust:    "#13131c"   // deeper dark
    readonly property color surface0: "#24283b"   // bg_float
    readonly property color surface1: "#292e42"   // bg_highlight
    readonly property color surface2: "#3b4261"   // fg_gutter
    readonly property color overlay0: "#545c7e"   // dark3
    readonly property color overlay1: "#737aa2"   // dark5
    readonly property color overlay2: "#a9b1d6"   // fg_dark
    readonly property color subtext0: "#a9b1d6"   // fg_dark
    readonly property color subtext1: "#c0caf5"   // fg (light)
    readonly property color text:     "#c0caf5"   // fg

    // Accent colours
    readonly property color rosewater: "#f7768e"  // red
    readonly property color flamingo:  "#ff9e64"  // orange
    readonly property color pink:      "#ff007c"  // magenta2
    readonly property color mauve:     "#bb9af7"  // purple
    readonly property color red:       "#f7768e"
    readonly property color maroon:    "#db4b4b"  // red1
    readonly property color peach:     "#ff9e64"  // orange
    readonly property color yellow:    "#e0af68"
    readonly property color green:     "#9ece6a"
    readonly property color teal:      "#73daca"  // green1
    readonly property color sky:       "#7dcfff"  // cyan
    readonly property color sapphire:  "#2ac3de"  // blue1
    readonly property color blue:      "#7aa2f7"
    readonly property color lavender:  "#bb9af7"  // purple
}
