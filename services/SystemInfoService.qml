pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Polls CPU, RAM, swap, temperature, disk usage, IP and network speeds.
// Follows the same Process/SplitParser pattern as AudioService / BrightnessService.
Singleton {
    id: root

    // ── exposed properties ────────────────────────────────────────────────────
    property real   cpuPercent:  0        // 0–100
    property real   ramPercent:  0        // 0–100
    property real   swapPercent: 0        // 0–100
    property real   tempCelsius: 0        // °C
    property real   diskPercent: 0        // 0–100 (root /)
    property string ipAddress:   "—"
    property real   rxKbps:      0        // KB/s download
    property real   txKbps:      0        // KB/s upload

    // ── internal ─────────────────────────────────────────────────────────────
    property real _prevRx: 0
    property real _prevTx: 0
    property bool _firstPoll: true

    // Single sh invocation, one labelled line per metric
    Process {
        id: pollProc
        running: false
        command: [
            "sh", "-c",
            // CPU idle fraction from /proc/stat
            "awk '/^cpu /{idle=$5;tot=0;for(i=2;i<=NF;i++)tot+=$i;printf \"cpu:%.1f\\n\",idle/tot*100}' /proc/stat;" +
            // RAM
            "awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf \"mem:%d:%d\\n\",t-a,t}' /proc/meminfo;" +
            // Swap
            "awk '/SwapTotal/{t=$2}/SwapFree/{f=$2}END{if(t>0)printf \"swap:%d:%d\\n\",t-f,t;else print \"swap:0:1\"}' /proc/meminfo;" +
            // Temperature (thermal_zone — pick highest, convert millidegrees)
            "t=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null|sort -n|tail -1);" +
            "if [ -n \"$t\" ]; then [ \"$t\" -gt 1000 ] && t=$((t/1000)); echo \"temp:$t\"; fi;" +
            // Disk root %
            "df /|awk 'NR==2{gsub(/%/,\"\",$5);print \"disk:\"$5}';" +
            // IP
            "ip4=$(ip -4 addr show scope global 2>/dev/null|awk '/inet/{print $2}'|cut -d/ -f1|head -1);" +
            "echo \"ip:${ip4:--}\";" +
            // Network bytes (sum all non-loopback)
            "rx=0;tx=0;" +
            "for f in /sys/class/net/*/statistics/rx_bytes;" +
            "do i=$(echo $f|cut -d/ -f5);[ \"$i\"=lo ]&&continue;rx=$((rx+$(cat $f 2>/dev/null||echo 0)));done;" +
            "for f in /sys/class/net/*/statistics/tx_bytes;" +
            "do i=$(echo $f|cut -d/ -f5);[ \"$i\"=lo ]&&continue;tx=$((tx+$(cat $f 2>/dev/null||echo 0)));done;" +
            "echo \"net:$rx:$tx\""
        ]
        stdout: SplitParser {
            onRead: line => {
                const sep = line.indexOf(":");
                if (sep < 0) return;
                const key = line.substring(0, sep);
                const val = line.substring(sep + 1);
                if (key === "cpu") {
                    root.cpuPercent = 100 - parseFloat(val);
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
                } else if (key === "ip") {
                    root.ipAddress = val.trim() || "—";
                } else if (key === "net") {
                    const p = val.split(":");
                    const rx = parseFloat(p[0]);
                    const tx = parseFloat(p[1]);
                    if (!root._firstPoll) {
                        root.rxKbps = Math.max(0, (rx - root._prevRx) / 3 / 1024);
                        root.txKbps = Math.max(0, (tx - root._prevTx) / 3 / 1024);
                    }
                    root._prevRx = rx;
                    root._prevTx = tx;
                    root._firstPoll = false;
                }
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }

    // Format KB/s → human-readable string
    function fmtSpeed(kbps) {
        if (kbps >= 1024)
            return (kbps / 1024).toFixed(1) + " MB/s";
        return Math.round(kbps) + " KB/s";
    }
}
