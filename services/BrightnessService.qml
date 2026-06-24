pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real brightness: 0

    readonly property FileView brightnessFile: FileView {
        path: "/sys/class/backlight/amdgpu_bl2/brightness"
        onLoaded: {
            const cur = parseInt(text().trim());
            if (!isNaN(cur) && maxFile.max > 0) {
                root.brightness = cur / maxFile.max;
            }
        }
    }

    readonly property FileView maxFile: FileView {
        path: "/sys/class/backlight/amdgpu_bl2/max_brightness"
        property real max: 255
        onLoaded: {
            const val = parseInt(text().trim());
            if (!isNaN(val) && val > 0) {
                max = val;
            }
        }
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            maxFile.reload();
            brightnessFile.reload();
        }
    }

    function setBrightness(value: real): void {
        const percent = Math.round(Math.max(0, Math.min(1, value)) * 100);
        Quickshell.execDetached(["brightnessctl", "s", `${percent}%`]);
    }
}
