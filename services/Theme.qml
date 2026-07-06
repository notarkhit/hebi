pragma Singleton

import QtQuick
import Quickshell

// Central theme token singleton.
// Change surfaceBg here to update bar, panels, and launcher simultaneously.
Singleton {
    id: root

    // Wait 100ms before querying Hyprland to prevent IPC stalls on the very first frame
    property bool dynamicOpacityReady: false
    Timer {
        interval: 100
        running: true
        onTriggered: root.dynamicOpacityReady = true
    }

    // Short-circuit the Hyprland property checks if we aren't ready yet
    readonly property bool hasActiveWindow: dynamicOpacityReady && Hypr.activeToplevel && Hypr.activeToplevel.workspace === Hypr.focusedWorkspace
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
