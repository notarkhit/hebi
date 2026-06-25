pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Hebi.Blobs
import "components"
import "../../services"

// Settings panel — slides up from the bar on the right side.
// Opened by clicking SysInfo in the bar.
PanelWindow {
    id: root

    property bool panelVisible: false

    IpcHandler {
        target: "settings"
        function toggle(): void {
            root.panelVisible = !root.panelVisible;
        }
        function open(): void {
            root.panelVisible = true;
        }
        function close(): void {
            root.panelVisible = false;
        }
    }

    // ── window setup ──────────────────────────────────────────────────────────
    anchors.right: true
    anchors.bottom: false
    anchors.top: true
    anchors.left: false

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 80
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    
    // Only grab input over the actual panel when visible
    mask: panelVisible ? activeRegion : emptyRegion

    Region { id: emptyRegion }
    Region {
        id: activeRegion
        x: content.x
        y: content.y
        width: content.width
        height: content.height
    }

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
        command: ["sh", "-c", "nmcli radio wifi; " + "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no 2>/dev/null | grep '^yes' | head -1; " + "nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep ':ethernet:connected' | head -1; " + "rfkill list bluetooth 2>/dev/null | grep -i 'soft blocked: no' | head -1"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                if (line === "enabled")
                    root.wifiEnabled = true;
                if (line === "disabled")
                    root.wifiEnabled = false;
                if (line.startsWith("yes:")) {
                    const p = line.split(":");
                    root.wifiSignal = parseInt(p[1]) || 0;
                    root.wifiSsid = p.slice(2).join(":") || "";
                    root.wifiUp = true;
                }
                if (line.includes(":ethernet:connected"))
                    root.ethUp = true;
                if (line.includes("Soft blocked: no"))
                    root.bluetoothEnabled = true;
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.panelVisible
        triggeredOnStart: true
        onTriggered: {
            root.wifiUp = false;
            root.ethUp = false;
            root.bluetoothEnabled = false;
            netProc.running = true;
        }
    }

    // ── battery ───────────────────────────────────────────────────────────────
    readonly property real batPct: UPower.displayDevice.percentage ?? 0
    readonly property bool batCharging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)
    readonly property bool hasBat: UPower.displayDevice.isLaptopBattery

    // ── idle inhibitor state ──────────────────────────────────────────────────
    property bool idleInhibited: false

    Process {
        id: inhibitProc
        command: ["systemd-inhibit", "--what=idle", "--who=Hebi", "--why=User requested", "--mode=block", "sleep", "infinity"]
        running: false
    }

    // ── panel card ────────────────────────────────────────────────────────────
    BlobGroup {
        id: bgGroup
        color: Qt.rgba(0x1a / 255, 0x1b / 255, 0x26 / 255, 0.92)
    }

    Item {
        id: container
        anchors.fill: parent

        BlobRect {
            id: panelBg
            group: bgGroup
            
            // Closed state: rough position/size of the SysInfo pill in the bar
            property real closedX: root.width - 12 - 140
            property real closedY: 0
            property real closedW: 140
            property real closedH: 20
            
            // Open state: full settings panel sticking to the edges (pushed slightly out of bounds to hide radius)
            property real openX: root.width - 336
            property real openY: -20
            property real openW: 356
            property real openH: col.implicitHeight + 52

            x: root.panelVisible ? openX : closedX
            y: root.panelVisible ? openY : closedY
            width: root.panelVisible ? openW : closedW
            height: root.panelVisible ? openH : closedH
            radius: root.panelVisible ? 20 : 10
            
            // Physics: expansion will cause wild organic deformations
            stiffness: 160
            damping: 12
            deformScale: 0.005

            Behavior on x { NumberAnimation { duration: 250; easing.type: root.panelVisible ? Easing.OutBack : Easing.InCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: root.panelVisible ? Easing.OutBack : Easing.InCubic } }
            Behavior on width { NumberAnimation { duration: 250; easing.type: root.panelVisible ? Easing.OutBack : Easing.InCubic } }
            Behavior on height { NumberAnimation { duration: 250; easing.type: root.panelVisible ? Easing.OutBack : Easing.InCubic } }
            Behavior on radius { NumberAnimation { duration: 250; easing.type: root.panelVisible ? Easing.OutBack : Easing.InCubic } }

            opacity: root.panelVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: root.panelVisible ? 100 : 250 } }
        }

        // Overlay border matching the expanding BlobRect
        Rectangle {
            x: panelBg.x; y: panelBg.y
            width: panelBg.width; height: panelBg.height
            radius: panelBg.radius
            color: "transparent"
            border.color: "#2a2d3e"
            border.width: 1
            opacity: panelBg.opacity
        }

        // Clip wrapper that bounds the content exactly to the expanding box
        Item {
            x: panelBg.x; y: panelBg.y
            width: panelBg.width; height: panelBg.height
            clip: true

            Item {
                id: content
                anchors.right: parent.right
                anchors.top: parent.top
                width: panelBg.openW
                height: panelBg.openH
                
                opacity: panelBg.opacity
                
                implicitWidth: 356
                implicitHeight: col.implicitHeight + 52
                
                layer.enabled: true
                // Do NOT clip the inner content, the wrapper handles it!

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 36 // 16px padding + 20px pushed off screen
            anchors.rightMargin: 36 // 16px padding + 20px pushed off screen
            anchors.leftMargin: 16
            anchors.bottomMargin: 16
            spacing: 14

            // ── Header: battery + actions ─────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Battery icon + label
                Image {
                    sourceSize: Qt.size(18, 18)
                    source: Quickshell.iconPath(root.hasBat ? (root.batCharging ? "battery-good-charging-symbolic" : "battery-full-symbolic") : "computer-symbolic")
                    fillMode: Image.PreserveAspectFit
                    Layout.alignment: Qt.AlignVCenter
                    opacity: 0.8
                }
                Text {
                    text: root.hasBat ? `${Math.round(root.batPct * 100)}%${root.batCharging ? " ⚡" : ""}` : "Desktop"
                    color: "#c0caf5"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }

                // Lock button
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: lockHov.containsMouse ? "#292e42" : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                    Image {
                        anchors.centerIn: parent
                        sourceSize: Qt.size(16, 16)
                        source: Quickshell.iconPath("system-lock-screen-symbolic")
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.7
                    }
                    MouseArea {
                        id: lockHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.panelVisible = false;
                            Quickshell.execDetached(["hyprlock"]);
                        }
                    }
                }

                // Power button
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: powerHov.containsMouse ? "#2a1020" : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                    Image {
                        anchors.centerIn: parent
                        sourceSize: Qt.size(16, 16)
                        source: Quickshell.iconPath("system-shutdown-symbolic")
                        fillMode: Image.PreserveAspectFit
                        opacity: powerHov.containsMouse ? 1 : 0.7
                    }
                    MouseArea {
                        id: powerHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["wlogout"])
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: "#24283b"
            }

            // ── Sliders ───────────────────────────────────────────────────────

            // Volume
            SliderRow {
                Layout.fillWidth: true
                iconSource: Quickshell.iconPath(AudioService.muted || AudioService.volume <= 0 ? "audio-volume-muted-symbolic" : AudioService.volume <= 0.33 ? "audio-volume-low-symbolic" : AudioService.volume <= 0.66 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic")
                value: AudioService.volume
                maxValue: 1.5
                onChanged: v => AudioService.setVolume(v)
            }

            // Microphone (read-only for now — future: pactl set-source-volume)
            SliderRow {
                Layout.fillWidth: true
                iconSource: Quickshell.iconPath("audio-input-microphone-symbolic")
                value: 0.8
                maxValue: 1.0
                showArrow: true
                onArrowClicked: Quickshell.execDetached(["pavucontrol"])
            }

            // Brightness
            SliderRow {
                Layout.fillWidth: true
                iconSource: Quickshell.iconPath("display-brightness-symbolic")
                value: BrightnessService.brightness
                maxValue: 1.0
                onChanged: v => BrightnessService.setBrightness(v)
            }

            // ── Divider ───────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: "#24283b"
            }

            // ── Toggle pills grid ─────────────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                // Wi-Fi
                TogglePill {
                    Layout.fillWidth: true
                    iconSource: Quickshell.iconPath(root.ethUp ? "network-wired-symbolic" : root.wifiUp ? "network-wireless-symbolic" : "network-wireless-signal-none-symbolic")
                    label: "Wi-Fi"
                    sublabel: root.wifiSsid
                    active: root.wifiEnabled
                    showChevron: true
                    onClicked: {
                        root.wifiEnabled = !root.wifiEnabled;
                        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiEnabled ? "on" : "off"]);
                    }
                    onChevronClicked: Quickshell.execDetached(["nm-connection-editor"])
                }

                // Bluetooth
                TogglePill {
                    Layout.fillWidth: true
                    iconSource: Quickshell.iconPath("bluetooth-symbolic")
                    label: "Bluetooth"
                    active: root.bluetoothEnabled
                    showChevron: true
                    onClicked: {
                        root.bluetoothEnabled = !root.bluetoothEnabled;
                        Quickshell.execDetached(["rfkill", root.bluetoothEnabled ? "unblock" : "block", "bluetooth"]);
                    }
                    onChevronClicked: Quickshell.execDetached(["blueman-manager"])
                }

                // Airplane Mode
                TogglePill {
                    Layout.fillWidth: true
                    iconSource: Quickshell.iconPath("airplane-mode-symbolic")
                    label: "Airplane Mode"
                    active: root.airplaneMode
                    onClicked: {
                        root.airplaneMode = !root.airplaneMode;
                        Quickshell.execDetached(["nmcli", "radio", "all", root.airplaneMode ? "off" : "on"]);
                    }
                }

                // Do Not Disturb
                TogglePill {
                    Layout.fillWidth: true
                    iconSource: Quickshell.iconPath("notifications-disabled-symbolic")
                    label: "Do Not Disturb"
                    active: Notifs.dnd
                    onClicked: Notifs.dnd = !Notifs.dnd
                }

                // Idle Inhibitor
                TogglePill {
                    Layout.fillWidth: true
                    iconSource: Quickshell.iconPath("caffeine-symbolic")
                    label: "Idle Inhibitor"
                    active: root.idleInhibited
                    onClicked: {
                        root.idleInhibited = !root.idleInhibited;
                        if (root.idleInhibited)
                            inhibitProc.running = true;
                        else {
                            inhibitProc.running = false;
                        }
                    }
                }

                // Night Light placeholder
                TogglePill {
                    Layout.fillWidth: true
                    iconSource: Quickshell.iconPath("night-light-symbolic")
                    label: "Night Light"
                    active: false
                    onClicked: Quickshell.execDetached(["hyprshade", "toggle", "blue-light-filter"])
                }
            }

            // Bottom spacer
            Item { implicitHeight: 4 }
        }
        }
        }
    }

    // Close when clicking outside
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.panelVisible = false
    }
}
