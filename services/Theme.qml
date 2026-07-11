pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Hebi

// Central theme token singleton.
// Change surfaceBg here to update bar, panels, and launcher simultaneously.
Singleton {
    id: root

    property string surfaceHex: "#000000"
    property color border: "#2a2d3e"
    property color accent: "#7aa2f7"

    FileView {
        path: Quickshell.env("XDG_STATE_HOME") ? `${Quickshell.env("XDG_STATE_HOME")}/hebi/scheme.json` : `${Quickshell.env("HOME")}/.local/state/hebi/scheme.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const scheme = JSON.parse(text());
                root.surfaceHex = "#" + scheme.colours.surface;
                root.border = "#" + scheme.colours.outlineVariant;
                root.accent = "#" + scheme.colours.primary;
                
                // Force Qt to load the Papirus icon theme matching the scheme mode,
                // bypassing any QT_QPA_PLATFORMTHEME or XDG_CURRENT_DESKTOP env var issues on Wayland/Hyprland.
                if (scheme.mode === "light") {
                    CUtils.setIconTheme("Papirus-Light");
                } else {
                    CUtils.setIconTheme("Papirus-Dark");
                }
            } catch (e) {
                console.error("Failed to parse scheme.json: " + e);
            }
        }
    }

    // Wait 1 frame before querying Hyprland to prevent IPC stalls
    property bool dynamicOpacityReady: false
    Timer {
        interval: 0
        running: true
        onTriggered: root.dynamicOpacityReady = true
    }

    // Short-circuit the Hyprland property checks if we aren't ready yet
    readonly property bool hasActiveWindow: dynamicOpacityReady && Hypr.activeToplevel && Hypr.activeToplevel.workspace === Hypr.focusedWorkspace
    property color surface: {
        let baseColor = Qt.color(surfaceHex);
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, hasActiveWindow ? 0.98 : 0.80);
    }

    Behavior on surface {
        enabled: root.dynamicOpacityReady
        ColorAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
}
