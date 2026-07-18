pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Hebi.Models

Singleton {
    id: root

    // ── Paths ──────────────────────────────────────────────────────────────
    readonly property string _stateBase: Quickshell.env("XDG_STATE_HOME")
        || (Quickshell.env("HOME") + "/.local/state")
    readonly property string _wallsBase: Quickshell.env("HEBI_WALLPAPERS_DIR")
        || (Quickshell.env("HOME") + "/Pictures/wallpapers")

    // ── Current wallpaper ──────────────────────────────────────────────────
    property string currentPath: ""

    // ── Preview state ──────────────────────────────────────────────────────
    property bool showPreview: false
    property var previewScheme: null
    property bool wantsPreview: false

    // ── Type state (static/live) ───────────────────────────────────────────
    property string wallpaperType: "static"

    function toggleType() {
        const newType = (wallpaperType === "static") ? "live" : "static";
        Quickshell.execDetached(["sh", "-c", `echo '${newType}' > ${root._stateBase}/hebi/wallpaper/type.txt`]);
    }

    readonly property var list: {
        const entries = fsModel.entries;
        const mode = Theme.currentSchemeMode || "dark";
        const type = wallpaperType;

        let filtered = [];
        
        // Strategy: First try matching exact type/mode.
        let hasExact = false;
        let hasType = false;

        for (let i = 0; i < entries.length; i++) {
            const e = entries[i];
            const parts = e.relativePath.split("/");
            if (parts.length >= 2 && parts[0] === type && parts[1] === mode) {
                hasExact = true;
                break;
            } else if (parts.length >= 1 && parts[0] === type) {
                hasType = true;
            }
        }

        for (let i = 0; i < entries.length; i++) {
            const e = entries[i];
            const parts = e.relativePath.split("/");
            
            let include = false;
            if (hasExact) {
                include = (parts.length >= 2 && parts[0] === type && parts[1] === mode);
            } else if (hasType) {
                include = (parts.length >= 1 && parts[0] === type);
            } else {
                include = true; // fallback: include all
            }

            if (include) {
                filtered.push({
                    path: e.path,
                    name: e.fileName,
                    relativePath: e.relativePath
                });
            }
        }
        return filtered;
    }

    // ── Public API ─────────────────────────────────────────────────────────

    function preview(path) {
        wantsPreview = true;
        debounceTimer.pendingPath = path;
        debounceTimer.restart();
    }

    function stopPreview() {
        wantsPreview = false;
        debounceTimer.stop();
        if (previewProc.running)
            previewProc.running = false;
        root.showPreview = false;
        root.previewScheme = null;
    }

    function apply(path) {
        stopPreview();
        Quickshell.execDetached([
            "sh", "-c",
            "$HOME/.local/bin/hebi wallpaper -f \"$1\"",
            "--", path
        ]);
    }

    // ── Watch paths for external changes ───────────────────────────────
    FileView {
        path: `${root._stateBase}/hebi/wallpaper/path.txt`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.currentPath = text().trim()
    }

    FileView {
        path: `${root._stateBase}/hebi/wallpaper/type.txt`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const t = text().trim();
            if (t === "live" || t === "static") {
                root.wallpaperType = t;
            }
        }
    }

    // ── FileSystemModel to scan wallpapers dir ────────────────────────────
    FileSystemModel {
        id: fsModel
        path: root._wallsBase
        recursive: true
        filter: FileSystemModel.Images
    }

    // ── Debounce timer (150ms) before spawning preview process ────────────
    Timer {
        id: debounceTimer
        interval: 150
        property string pendingPath: ""
        onTriggered: {
            if (pendingPath === "")
                return;
            previewProc.command = [
                "sh", "-c",
                "$HOME/.local/bin/hebi wallpaper -p \"$1\"",
                "--", pendingPath
            ];
            previewProc.running = true;
        }
    }

    // ── Preview colour generation process ─────────────────────────────────
    Process {
        id: previewProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.wantsPreview) return;
                try {
                    root.previewScheme = JSON.parse(text);
                    root.showPreview = true;
                } catch (e) {
                    console.error("Wallpapers: failed to parse preview scheme:", e);
                }
            }
        }
    }
}
