pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "components"
import "../../services"

// Settings panel as a plain Item — lives inside MainWindow's shared BlobGroup context
Item {
    id: root

    required property bool panelVisible

    signal closeRequested

    readonly property real currentHeight: col.implicitHeight + 52
    readonly property real panelWidth: 400

    implicitWidth: panelWidth
    implicitHeight: col.implicitHeight + 52

    // ── network state ─────────────────────────────────────────────────────────
    property bool wifiEnabled: true
    property bool wifiUp: false
    property string wifiSsid: ""
    property int wifiSignal: -1
    property bool ethUp: false
    property bool bluetoothEnabled: false
    property bool airplaneMode: false

    Process {
        id: netProc
        command: ["sh", "-c",
            "nmcli radio wifi; " +
            "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no 2>/dev/null | grep '^yes' | head -1; " +
            "nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep ':ethernet:connected' | head -1; " +
            "rfkill list bluetooth 2>/dev/null | grep -i 'soft blocked: no' | head -1"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                if (line === "enabled")  root.wifiEnabled = true
                if (line === "disabled") root.wifiEnabled = false
                if (line.startsWith("yes:")) {
                    const p = line.split(":")
                    root.wifiSignal = parseInt(p[1]) || 0
                    root.wifiSsid   = p.slice(2).join(":") || ""
                    root.wifiUp     = true
                }
                if (line.includes(":ethernet:connected")) root.ethUp = true
                if (line.includes("Soft blocked: no"))   root.bluetoothEnabled = true
            }
        }
    }

    Timer {
        interval: 5000; repeat: true
        running: root.panelVisible; triggeredOnStart: true
        onTriggered: {
            root.wifiUp = false; root.ethUp = false; root.bluetoothEnabled = false
            netProc.running = true
        }
    }

    readonly property real batPct: UPower.displayDevice.percentage ?? 0
    readonly property bool batCharging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)
    readonly property bool hasBat: UPower.displayDevice.isLaptopBattery

    property bool idleInhibited: false
    Process {
        id: inhibitProc
        command: ["systemd-inhibit", "--what=idle", "--who=Hebi", "--why=User requested", "--mode=block", "sleep", "infinity"]
        running: false
    }

    // ── animation ─────────────────────────────────────────────────────────────
    property real offsetScale: root.panelVisible ? 0 : 1
    Behavior on offsetScale {
        NumberAnimation { duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1] }
    }
    // blobY: visual y-position used by MainWindow's shared BlobRect to track this panel
    readonly property real blobY: y + (-implicitHeight - 5) * offsetScale

    transform: Translate { y: (-root.implicitHeight - 5) * root.offsetScale }

    // ── content ───────────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.topMargin: 20; anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.bottomMargin: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text {
                text: {
                    if (!root.hasBat)        return "\u{f109}"
                    if (root.batCharging)    return "\u{f0e7}"
                    const p = root.batPct
                    if (p >= 0.90) return "\u{f240}"; if (p >= 0.75) return "\u{f241}"
                    if (p >= 0.50) return "\u{f242}"; if (p >= 0.25) return "\u{f243}"
                    return "\u{f244}"
                }
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; Layout.alignment: Qt.AlignVCenter
                color: root.hasBat && root.batPct < 0.20 && !root.batCharging ? "#f7768e" : "#ffffff"
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            Text {
                text: root.hasBat ? `${Math.round(root.batPct * 100)}%${root.batCharging ? " ⚡" : ""}` : "Desktop"
                color: "#ffffff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true
            }
            Rectangle {
                implicitWidth: 32; implicitHeight: 32; radius: 16; color: lockHov.containsMouse ? "#292e42" : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: ""; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; color: "#ffffff" }
                MouseArea { id: lockHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.closeRequested(); Quickshell.execDetached(["hyprlock"]) } }
            }
            Rectangle {
                implicitWidth: 32; implicitHeight: 32; radius: 16; color: powerHov.containsMouse ? "#2a1020" : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: ""; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; color: "#ffffff" }
                MouseArea { id: powerHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["wlogout"]) }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: "#24283b" }

        SliderRow { Layout.fillWidth: true; iconText: AudioService.muted || AudioService.volume <= 0 ? "" : AudioService.volume <= 0.33 ? "" : AudioService.volume <= 0.66 ? "墳" : ""; value: AudioService.volume; maxValue: 1.5; onChanged: v => AudioService.setVolume(v) }
        SliderRow { Layout.fillWidth: true; iconText: ""; value: 0.8; maxValue: 1.0; showArrow: true; onArrowClicked: Quickshell.execDetached(["pavucontrol"]) }
        SliderRow { Layout.fillWidth: true; iconText: ""; value: BrightnessService.brightness; maxValue: 1.0; onChanged: v => BrightnessService.setBrightness(v) }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: "#1e2235"; opacity: 0.8 }

        GridLayout {
            Layout.fillWidth: true; columns: 2; columnSpacing: 8; rowSpacing: 8

            TogglePill {
                Layout.fillWidth: true
                iconText: root.ethUp ? "" : root.wifiUp ? "" : "睊"
                label: "Wi-Fi"; sublabel: root.wifiSsid; active: root.wifiEnabled; showChevron: true
                onClicked: { root.wifiEnabled = !root.wifiEnabled; Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiEnabled ? "on" : "off"]) }
                onChevronClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
            TogglePill {
                Layout.fillWidth: true
                iconText: ""; label: "Bluetooth"; active: root.bluetoothEnabled; showChevron: true
                onClicked: { root.bluetoothEnabled = !root.bluetoothEnabled; Quickshell.execDetached(["rfkill", root.bluetoothEnabled ? "unblock" : "block", "bluetooth"]) }
                onChevronClicked: Quickshell.execDetached(["blueman-manager"])
            }
            TogglePill {
                Layout.fillWidth: true
                iconText: ""; label: "Airplane Mode"; active: root.airplaneMode
                onClicked: { root.airplaneMode = !root.airplaneMode; Quickshell.execDetached(["nmcli", "radio", "all", root.airplaneMode ? "off" : "on"]) }
            }
            TogglePill {
                Layout.fillWidth: true
                iconText: ""; label: "Do Not Disturb"; active: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            TogglePill {
                Layout.fillWidth: true
                iconText: ""; label: "Idle Inhibitor"; active: root.idleInhibited
                onClicked: { root.idleInhibited = !root.idleInhibited; inhibitProc.running = root.idleInhibited }
            }
            TogglePill {
                Layout.fillWidth: true
                iconText: ""; label: "Night Light"; active: false
                onClicked: Quickshell.execDetached(["hyprshade", "toggle", "blue-light-filter"])
            }
        }

        Item { implicitHeight: 4 }
    }
}
