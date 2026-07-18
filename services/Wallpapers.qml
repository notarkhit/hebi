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

    readonly property var list: {
        const result = [];
        const entries = fsModel.entries;
        for (let i = 0; i < entries.length; i++) {
            const e = entries[i];
            const parts = e.relativePath.split("/");
            if (parts.length > 0 && parts[0] === "live")
                continue;
            result.push({
                path: e.path,
                name: e.fileName,
                relativePath: e.relativePath
            });
        }
        return result;
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

    // ── Watch path.txt for external changes ───────────────────────────────
    FileView {
        path: `${root._stateBase}/hebi/wallpaper/path.txt`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.currentPath = text().trim()
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
