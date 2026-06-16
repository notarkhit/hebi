pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real brightness: 0
    property real queuedBrightness: NaN

    readonly property Process initProc: Process {
        command: ["sh", "-c", "echo a b c $(brightnessctl g) $(brightnessctl m)"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const [, , , cur, max] = text.split(" ");
                let parsedCur = parseInt(cur);
                let parsedMax = parseInt(max);
                if (!isNaN(parsedCur) && !isNaN(parsedMax) && parsedMax > 0) {
                    root.brightness = parsedCur / parsedMax;
                }
            }
        }
    }

    readonly property Timer debounceTimer: Timer {
        interval: 100
        onTriggered: {
            if (!isNaN(root.queuedBrightness)) {
                root.setBrightness(root.queuedBrightness);
                root.queuedBrightness = NaN;
            }
        }
    }

    function setBrightness(value: real): void {
        value = Math.max(0, Math.min(1, value));
        const rounded = Math.round(value * 100);
        
        if (Math.round(brightness * 100) === rounded)
            return;

        if (debounceTimer.running) {
            queuedBrightness = value;
            return;
        }

        brightness = value;
        Quickshell.execDetached(["brightnessctl", "s", `${rounded}%`]);
        
        debounceTimer.restart();
    }
    
    // Allows external user scripts to force a refresh if they bypassed Quickshell
    IpcHandler {
        target: "brightness"
        function refresh() {
            initProc.running = true;
        }
        function setBrightness(val: string) {
            let percent = parseFloat(val);
            if (!isNaN(percent)) {
                root.setBrightness(percent / 100);
            }
        }
    }

    // Initialize on startup
    Component.onCompleted: {
        initProc.running = true;
    }

    // Native backlight watcher: triggers an update whenever external tools (like brightnessctl) change the backlight
    readonly property Process watcherProc: Process {
        command: ["sh", "-c", "stdbuf -oL udevadm monitor --subsystem-match=backlight | while read -r line; do qs ipc -p ~/.config/hebi call brightness refresh; done"]
        running: true
    }
}
