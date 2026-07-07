pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../../../services" as Services

// System status pill: battery · network · volume
// Sits on the right side of the bar, before the clock.
// Click to open the settings panel.
Item {
    id: root

    signal clicked()

    implicitWidth:  row.implicitWidth + 20
    implicitHeight: row.implicitHeight

    // ── network polling via nmcli ─────────────────────────────────────────
    // Reads wifi SSID + signal strength every 10s
    property int   wifiSignal: -1   // -1 = unknown, 0–100 = percent
    property bool  wifiUp: false
    property string wifiSsid: ""
    property bool  ethUp: false

    Process {
        id: netProc
        command: ["sh", "-c",
            "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no 2>/dev/null | grep '^yes' | head -1; " +
            "nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep ':ethernet:connected' | head -1"
        ]
        running: false
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("yes:")) {
                    const parts = line.split(":")
                    root.wifiSignal = parseInt(parts[1]) || 0
                    root.wifiSsid   = parts.slice(2).join(":") || ""
                    root.wifiUp     = true
                } else if (line.includes(":ethernet:connected")) {
                    root.ethUp = true
                }
            }
        }
    }

    Timer {
        interval: 10000
        repeat:   true
        running:  true
        triggeredOnStart: true
        onTriggered: {
            root.wifiUp     = false
            root.ethUp      = false
            root.wifiSignal = -1
            netProc.running = true
        }
    }


    // ── battery (UPower) ─────────────────────────────────────────────────
    readonly property real  batPct:      UPower.displayDevice.percentage ?? 0
    readonly property bool  batCharging: [
        UPowerDeviceState.Charging,
        UPowerDeviceState.FullyCharged,
        UPowerDeviceState.PendingCharge
    ].includes(UPower.displayDevice.state)
    readonly property bool  hasBat:      UPower.displayDevice.isLaptopBattery
    readonly property bool  batLow:      hasBat && !batCharging && batPct < 0.2

    // ── reactive icon properties ───────────────────────────────────────────
    readonly property string wifiIconName: {
        if (ethUp) return "network-wired-symbolic"
        if (!wifiUp) return "network-wireless-signal-none-symbolic"
        if (wifiSignal >= 75) return "network-wireless-signal-excellent-symbolic"
        if (wifiSignal >= 50) return "network-wireless-signal-good-symbolic"
        if (wifiSignal >= 25) return "network-wireless-signal-ok-symbolic"
        return "network-wireless-signal-weak-symbolic"
    }

    readonly property string volIconName: {
        if (Services.AudioService.muted || Services.AudioService.volume <= 0)
            return "audio-volume-muted-symbolic"
        if (Services.AudioService.volume <= 0.33) return "audio-volume-low-symbolic"
        if (Services.AudioService.volume <= 0.66) return "audio-volume-medium-symbolic"
        return "audio-volume-high-symbolic"
    }

    readonly property string batIconName: {
        if (batCharging) {
            if (batPct >= 0.9) return "battery-full-charged-symbolic"
            return "battery-good-charging-symbolic"
        }
        if (batPct >= 0.9) return "battery-full-symbolic"
        if (batPct >= 0.6) return "battery-good-symbolic"
        if (batPct >= 0.4) return "battery-medium-symbolic"
        if (batPct >= 0.2) return "battery-low-symbolic"
        return "battery-caution-symbolic"
    }

    // ── UI ────────────────────────────────────────────────────────────────
    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // Network
        Image {
            sourceSize: Qt.size(14, 14)
            source:     Quickshell.iconPath(root.wifiIconName)
            fillMode:   Image.PreserveAspectFit
            asynchronous: true
            Layout.alignment: Qt.AlignVCenter
            opacity: root.wifiUp || root.ethUp ? 1 : 0.4
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // Volume
        Image {
            sourceSize: Qt.size(14, 14)
            source:     Quickshell.iconPath(root.volIconName)
            fillMode:   Image.PreserveAspectFit
            asynchronous: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Battery (only shown if device has one)
        Item {
            visible: root.hasBat
            Layout.preferredWidth: 38
            implicitHeight: 14
            Row {
                anchors.centerIn: parent
                spacing: 3

                Image {
                    sourceSize: Qt.size(14, 14)
                    source:     Quickshell.iconPath(root.batIconName)
                    fillMode:   Image.PreserveAspectFit
                    asynchronous: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text:  `${Math.round(root.batPct * 100)}%`
                    color: root.batLow ? "#f7768e" : "#565f89"
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Notification Manager Bell
        Text {
            text: "\u{f0f3}" // Bell icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: "#c0caf5"
            Layout.alignment: Qt.AlignVCenter
            
            MouseArea {
                anchors.fill: parent
                // Increase click area slightly
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["qs", "ipc", "-p", "/home/notarkhit/.config/hebi", "call", "notifmanager", "toggle"]);
                }
            }
        }
    }

    // Click anywhere on the pill to toggle settings
    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
