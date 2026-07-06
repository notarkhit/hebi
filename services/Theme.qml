pragma Singleton

import QtQuick
import Quickshell

// Central theme token singleton.
// Change surfaceBg here to update bar, panels, and launcher simultaneously.
Singleton {
    id: root

    // ── Surface background ────────────────────────────────────────────────────
    readonly property bool hasActiveWindow: Hypr.activeToplevel && Hypr.activeToplevel.workspace === Hypr.focusedWorkspace
    property color surface: Qt.rgba(0, 0, 0, hasActiveWindow ? 0.98 : 0.80)

    Behavior on surface {
        ColorAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    // Opaque hex variant for components that don't support alpha directly
    readonly property string surfaceHex: "#000000"

    // Panel border
    readonly property color border: "#2a2d3e"

    // Accent
    readonly property color accent: "#7aa2f7"
}
