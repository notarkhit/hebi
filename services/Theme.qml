pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Hebi

// Central theme token singleton.
// Change surfaceBg here to update bar, panels, and launcher simultaneously.
Singleton {
    id: root

    // ── Preview support ────────────────────────────────────────────────────
    property bool isWallpaperPreview: false
    property bool isSchemePreview: false
    readonly property bool showPreview: isWallpaperPreview || isSchemePreview

    // Current (persisted) colour backing
    property string currentSchemeName: ""
    property string currentSchemeMode: "dark"
    property string _curSurfaceHex:    "#000000"
    property color  _curBorder:        "#2a2d3e"
    property color  _curAccent:        "#7aa2f7"
    property color  _curText:          "#e3e2e7"
    property color  _curSubtext:       "#c3c6d0"
    property color  _curSurfaceVariant:"#43474f"
    property color  _curSurfaceContainer:"#1e2023"
    property color  _curSecondary:     "#bbc7df"
    property color  _curError:         "#ffb4ab"
    property color  _curSuccess:       "#b5ccba"
    property color  _curWarning:       "#ebb5ec"

    // Preview colour backing
    property string _prevSurfaceHex:     _curSurfaceHex
    property color  _prevBorder:         _curBorder
    property color  _prevAccent:         _curAccent
    property color  _prevText:           _curText
    property color  _prevSubtext:        _curSubtext
    property color  _prevSurfaceVariant: _curSurfaceVariant
    property color  _prevSurfaceContainer: _curSurfaceContainer
    property color  _prevSecondary:      _curSecondary
    property color  _prevError:          _curError
    property color  _prevSuccess:        _curSuccess
    property color  _prevWarning:        _curWarning

    // ── Public color API (switches between current / preview) ──────────────
    property string surfaceHex:        showPreview ? _prevSurfaceHex        : _curSurfaceHex
    property color  border:            showPreview ? _prevBorder            : _curBorder
    property color  accent:            showPreview ? _prevAccent            : _curAccent
    property color  text:              showPreview ? _prevText              : _curText
    property color  subtext:           showPreview ? _prevSubtext           : _curSubtext
    property color  surfaceVariant:    showPreview ? _prevSurfaceVariant    : _curSurfaceVariant
    property color  surfaceContainer:  showPreview ? _prevSurfaceContainer  : _curSurfaceContainer
    property color  secondary:         showPreview ? _prevSecondary         : _curSecondary
    property color  error:             showPreview ? _prevError             : _curError
    property color  success:           showPreview ? _prevSuccess           : _curSuccess
    property color  warning:           showPreview ? _prevWarning           : _curWarning

    // ── Load preview colours from hebi wallpaper -p JSON output ───────────
    function loadPreview(colours) {
        if (!colours) return;
        _prevSurfaceHex      = "#" + (colours.surface           || _curSurfaceHex.slice(1));
        _prevBorder          = "#" + (colours.outlineVariant    || _curBorder.toString().slice(1));
        _prevAccent          = "#" + (colours.primary           || _curAccent.toString().slice(1));
        _prevText            = "#" + (colours.onSurface         || _curText.toString().slice(1));
        _prevSubtext         = "#" + (colours.onSurfaceVariant  || _curSubtext.toString().slice(1));
        _prevSurfaceVariant  = "#" + (colours.surfaceVariant    || _curSurfaceVariant.toString().slice(1));
        _prevSurfaceContainer= "#" + (colours.surfaceContainer  || _curSurfaceContainer.toString().slice(1));
        _prevSecondary       = "#" + (colours.secondary         || _curSecondary.toString().slice(1));
        _prevError           = "#" + (colours.error             || _curError.toString().slice(1));
        _prevSuccess         = colours.success ? "#" + colours.success : _curSuccess;
        _prevWarning         = colours.tertiary ? "#" + colours.tertiary : _curWarning;
    }

    // ── React to Wallpapers preview state ─────────────────────────────────
    Connections {
        target: Wallpapers
        function onPreviewSchemeChanged() {
            if (Wallpapers.showPreview && Wallpapers.previewScheme && root.currentSchemeName === "dynamic") {
                root.loadPreview(Wallpapers.previewScheme.colours);
                root.isWallpaperPreview = true;
            }
        }
        function onShowPreviewChanged() {
            if (Wallpapers.showPreview && Wallpapers.previewScheme && root.currentSchemeName === "dynamic") {
                root.loadPreview(Wallpapers.previewScheme.colours);
                root.isWallpaperPreview = true;
            } else {
                root.isWallpaperPreview = false;
            }
        }
    }

    // ── Support for Scheme previews ───────────────────────────────────────
    function setSchemePreview(colours) {
        if (colours) {
            root.loadPreview(colours);
            root.isSchemePreview = true;
        } else {
            root.isSchemePreview = false;
        }
    }

    FileView {
        path: Quickshell.env("XDG_STATE_HOME") ? `${Quickshell.env("XDG_STATE_HOME")}/hebi/scheme.json` : `${Quickshell.env("HOME")}/.local/state/hebi/scheme.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const scheme = JSON.parse(text());
                root.currentSchemeName = scheme.name;
                root.currentSchemeMode = scheme.mode;
                root._curSurfaceHex      = "#" + scheme.colours.surface;
                root._curBorder          = "#" + scheme.colours.outlineVariant;
                root._curAccent          = "#" + scheme.colours.primary;
                root._curText            = "#" + scheme.colours.onSurface;
                root._curSubtext         = "#" + scheme.colours.onSurfaceVariant;
                root._curSurfaceVariant  = "#" + scheme.colours.surfaceVariant;
                root._curSurfaceContainer= "#" + scheme.colours.surfaceContainer;
                root._curSecondary       = "#" + scheme.colours.secondary;
                root._curError           = "#" + scheme.colours.error;
                root._curSuccess  = scheme.colours.success  ? "#" + scheme.colours.success  : "#b5ccba";
                root._curWarning  = scheme.colours.tertiary ? "#" + scheme.colours.tertiary : "#ebb5ec";

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
