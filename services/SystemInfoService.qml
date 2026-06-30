pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Polls CPU, RAM, swap, temperature, disk and network speeds.
// Uses an external script run via `sh` (no chmod needed).
Singleton {
    id: root

    // ── exposed properties ────────────────────────────────────────────────────
    property real   cpuPercent:  0        // 0–100
    property real   ramPercent:  0        // 0–100
    property real   swapPercent: 0        // 0–100
    property real   tempCelsius: 0        // °C
    property real   diskPercent: 0        // 0–100 (root /)
    property real   rxKbps:      0        // KB/s download
    property real   txKbps:      0        // KB/s upload

    // ── internal ─────────────────────────────────────────────────────────────
    property real _prevRx:    0
    property real _prevTx:    0
    property bool _firstPoll: true
    property bool _busy:      false   // prevent overlapping runs

    // Run the poll script via sh so chmod is not required
    Process {
        id: pollProc
        running: false
        command: ["sh", Qt.resolvedUrl("sysinfo_poll.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: line => {
                const sep = line.indexOf(":");
                if (sep < 0) return;
                const key = line.substring(0, sep);
                const val = line.substring(sep + 1);

                if (key === "cpu") {
                    root.cpuPercent = parseFloat(val);
                } else if (key === "mem") {
                    const p = val.split(":");
                    root.ramPercent = p[1] > 0 ? (p[0] / p[1]) * 100 : 0;
                } else if (key === "swap") {
                    const p = val.split(":");
                    root.swapPercent = p[1] > 0 ? (p[0] / p[1]) * 100 : 0;
                } else if (key === "temp") {
                    root.tempCelsius = parseFloat(val);
                } else if (key === "disk") {
                    root.diskPercent = parseFloat(val);
                } else if (key === "net") {
                    const p = val.split(":");
                    const rx = parseFloat(p[0]);
                    const tx = parseFloat(p[1]);
                    if (!root._firstPoll) {
                        // script has a 0.5s sleep; interval is ~3s so delta period ≈ 3s
                        root.rxKbps = Math.max(0, (rx - root._prevRx) / 3 / 1024);
                        root.txKbps = Math.max(0, (tx - root._prevTx) / 3 / 1024);
                    }
                    root._prevRx = rx;
                    root._prevTx = tx;
                    root._firstPoll = false;
                }
            }
        }
        // Clear busy flag when process finishes
        onRunningChanged: {
            if (!running) root._busy = false;
        }
    }

    // Poll every 3 s; guard against overlapping runs
    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (root._busy) return;
            root._busy = true;
            // Toggle false→true to ensure Quickshell restarts the process
            pollProc.running = false;
            pollProc.running = true;
        }
    }

    // Format KB/s → human-readable string
    function fmtSpeed(kbps) {
        if (kbps >= 1024)
            return (kbps / 1024).toFixed(1) + " MB/s";
        return Math.round(kbps) + " KB/s";
    }
}
