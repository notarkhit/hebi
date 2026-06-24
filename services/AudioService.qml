pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real volume: 0
    property bool muted: false

    Process {
        running: true
        command: ["/home/notarkhit/.config/hebi/services/volume_monitor.sh"]
    }

    readonly property FileView volumeFile: FileView {
        path: "/tmp/hebi_volume"
        onLoaded: {
            const out = text().trim();
            if (out.length > 0) {
                const parsed = parseInt(out);
                if (!isNaN(parsed)) {
                    root.volume = parsed / 100.0;
                }
            }
        }
    }

    readonly property FileView muteFile: FileView {
        path: "/tmp/hebi_mute"
        onLoaded: {
            const out = text().trim();
            if (out.length > 0) {
                root.muted = (out === "yes");
            }
        }
    }

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            volumeFile.reload();
            muteFile.reload();
        }
    }

    function setVolume(value: real): void {
        const percent = Math.round(Math.max(0, Math.min(1.5, value)) * 100);
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", `${percent}%`]);
    }
}
