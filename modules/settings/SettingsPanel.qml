pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import "components"
import "../../services"

// Settings panel — slides up from the bar on the right side.
// Opened by clicking SysInfo in the bar.
PanelWindow {
    id: root

    property bool panelVisible: false

    IpcHandler {
        target: "settings"
        function toggle(): void { root.panelVisible = !root.panelVisible }
        function open(): void   { root.panelVisible = true  }
        function close(): void  { root.panelVisible = false }
    }

    // ── window setup ──────────────────────────────────────────────────────────
    anchors.right:  true
    anchors.bottom: true
    anchors.top:    false
    anchors.left:   false

    implicitWidth:  360
    implicitHeight: content.implicitHeight + 24
    color:          "transparent"

    WlrLayershell.layer:        WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // Only grab input when visible
    mask: panelVisible ? null : emptyRegion

    Region { id: emptyRegion }

    // ── network state ─────────────────────────────────────────────────────────
    property bool   wifiEnabled:  true
    property bool   wifiUp:       false
    property string wifiSsid:     ""
    property int    wifiSignal:   -1
    property bool   ethUp:        false
    property bool   bluetoothEnabled: false
    property bool   airplaneMode: false

    Process {
        id: netProc
        command: ["sh", "-c",
            "nmcli radio wifi; " +
            "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no 2>/dev/null | grep '^yes' | head -1; " +
            "nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep ':ethernet:connected' | head -1; " +
            "rfkill list bluetooth 2>/dev/null | grep -i 'soft blocked: no' | head -1"
        ]
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
        interval: 5000; repeat: true; running: root.panelVisible
        triggeredOnStart: true
        onTriggered: {
            root.wifiUp = false; root.ethUp = false
            root.bluetoothEnabled = false
            netProc.running = true
        }
    }

    // ── battery ───────────────────────────────────────────────────────────────
    readonly property real  batPct:      UPower.displayDevice.percentage ?? 0
    readonly property bool  batCharging: [
        UPowerDeviceState.Charging,
        UPowerDeviceState.FullyCharged,
        UPowerDeviceState.PendingCharge
    ].includes(UPower.displayDevice.state)
    readonly property bool hasBat: UPower.displayDevice.isLaptopBattery

    // ── idle inhibitor state ──────────────────────────────────────────────────
    property bool idleInhibited: false

    Process {
        id: inhibitProc
        command: ["systemd-inhibit", "--what=idle", "--who=Hebi", "--why=User requested", "--mode=block", "sleep", "infinity"]
        running: false
    }

    // ── panel card ────────────────────────────────────────────────────────────
    Rectangle {
        id: content

        anchors.right:        parent.right
        anchors.rightMargin:  12
        anchors.bottom:       parent.bottom
        anchors.bottomMargin: 12

        implicitWidth:  336
        implicitHeight: col.implicitHeight + 28

        radius: 20
        color:  "#1a1b26"
        border.color: "#2a2d3e"
        border.width: 1

        layer.enabled: true

        // Slide up + fade animation
        property real slideY: root.panelVisible ? 0 : 20
        transform: Translate { y: content.slideY }
        Behavior on slideY { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        opacity: root.panelVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        clip: true

        ColumnLayout {
            id: col
            anchors.left:    parent.left
            anchors.right:   parent.right
            anchors.top:     parent.top
            anchors.margins: 16
            spacing: 14

            // ── Header: battery + actions ─────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Battery icon + label
                Image {
                    sourceSize:       Qt.size(18, 18)
                    source:           Quickshell.iconPath(root.hasBat
                        ? (root.batCharging ? "battery-good-charging-symbolic" : "battery-full-symbolic")
                        : "computer-symbolic")
                    fillMode:         Image.PreserveAspectFit
                    Layout.alignment: Qt.AlignVCenter
                    opacity:          0.8
                }
                Text {
                    text:           root.hasBat
                        ? `${Math.round(root.batPct * 100)}%${root.batCharging ? " ⚡" : ""}`
                        : "Desktop"
                    color:          "#c0caf5"
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.weight:    Font.Medium
                    Layout.fillWidth: true
                }

                // Lock button
                Rectangle {
                    implicitWidth: 32; implicitHeight: 32
                    radius: 16
                    color:  lockHov.containsMouse ? "#292e42" : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Image {
                        anchors.centerIn: parent
                        sourceSize: Qt.size(16, 16)
                        source: Quickshell.iconPath("system-lock-screen-symbolic")
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.7
                    }
                    MouseArea {
                        id: lockHov; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.panelVisible = false
                            Quickshell.execDetached(["hyprlock"])
                        }
                    }
                }

                // Power button
                Rectangle {
                    implicitWidth: 32; implicitHeight: 32
                    radius: 16
                    color:  powerHov.containsMouse ? "#2a1020" : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Image {
                        anchors.centerIn: parent
                        sourceSize: Qt.size(16, 16)
                        source: Quickshell.iconPath("system-shutdown-symbolic")
                        fillMode: Image.PreserveAspectFit
                        opacity: powerHov.containsMouse ? 1 : 0.7
                    }
                    MouseArea {
                        id: powerHov; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["wlogout"])
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight:   1
                color:            "#24283b"
            }

            // ── Sliders ───────────────────────────────────────────────────────

            // Volume
            SliderRow {
                Layout.fillWidth: true
                iconSource: Quickshell.iconPath(
                    AudioService.muted || AudioService.volume <= 0 ? "audio-volume-muted-symbolic"
                    : AudioService.volume <= 0.33 ? "audio-volume-low-symbolic"
                    : AudioService.volume <= 0.66 ? "audio-volume-medium-symbolic"
                    : "audio-volume-high-symbolic")
                value:    AudioService.volume
                maxValue: 1.5
                onChanged: v => AudioService.setVolume(v)
            }

            // Microphone (read-only for now — future: pactl set-source-volume)
            SliderRow {
                Layout.fillWidth: true
                iconSource: Quickshell.iconPath("audio-input-microphone-symbolic")
                value:    0.8
                maxValue: 1.0
                showArrow: true
                onArrowClicked: Quickshell.execDetached(["pavucontrol"])
            }

            // Brightness
            SliderRow {
                Layout.fillWidth: true
                iconSource: Quickshell.iconPath("display-brightness-symbolic")
                value:    BrightnessService.brightness
                maxValue: 1.0
                onChanged: v => BrightnessService.setBrightness(v)
            }

            // ── Divider ───────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight:   1
                color:            "#24283b"
            }

            // ── Toggle pills grid ─────────────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns:          2
                columnSpacing:    8
                rowSpacing:       8

                // Wi-Fi
                TogglePill {
                    Layout.fillWidth: true
                    iconSource:  Quickshell.iconPath(
                        root.ethUp ? "network-wired-symbolic"
                        : root.wifiUp ? "network-wireless-symbolic"
                        : "network-wireless-signal-none-symbolic")
                    label:       "Wi-Fi"
                    sublabel:    root.wifiSsid
                    active:      root.wifiEnabled
                    showChevron: true
                    onClicked: {
                        root.wifiEnabled = !root.wifiEnabled
                        Quickshell.execDetached(["nmcli", "radio", "wifi",
                            root.wifiEnabled ? "on" : "off"])
                    }
                    onChevronClicked: Quickshell.execDetached(["nm-connection-editor"])
                }

                // Bluetooth
                TogglePill {
                    Layout.fillWidth: true
                    iconSource:  Quickshell.iconPath("bluetooth-symbolic")
                    label:       "Bluetooth"
                    active:      root.bluetoothEnabled
                    showChevron: true
                    onClicked: {
                        root.bluetoothEnabled = !root.bluetoothEnabled
                        Quickshell.execDetached(["rfkill",
                            root.bluetoothEnabled ? "unblock" : "block", "bluetooth"])
                    }
                    onChevronClicked: Quickshell.execDetached(["blueman-manager"])
                }

                // Airplane Mode
                TogglePill {
                    Layout.fillWidth: true
                    iconSource:  Quickshell.iconPath("airplane-mode-symbolic")
                    label:       "Airplane Mode"
                    active:      root.airplaneMode
                    onClicked: {
                        root.airplaneMode = !root.airplaneMode
                        Quickshell.execDetached(["nmcli", "radio", "all",
                            root.airplaneMode ? "off" : "on"])
                    }
                }

                // Do Not Disturb
                TogglePill {
                    Layout.fillWidth: true
                    iconSource:  Quickshell.iconPath("notifications-disabled-symbolic")
                    label:       "Do Not Disturb"
                    active:      Notifs.dnd
                    onClicked:   Notifs.dnd = !Notifs.dnd
                }

                // Idle Inhibitor
                TogglePill {
                    Layout.fillWidth: true
                    iconSource:  Quickshell.iconPath("caffeine-symbolic")
                    label:       "Idle Inhibitor"
                    active:      root.idleInhibited
                    onClicked: {
                        root.idleInhibited = !root.idleInhibited
                        if (root.idleInhibited)
                            inhibitProc.running = true
                        else {
                            inhibitProc.running = false
                        }
                    }
                }

                // Night Light placeholder
                TogglePill {
                    Layout.fillWidth: true
                    iconSource:  Quickshell.iconPath("night-light-symbolic")
                    label:       "Night Light"
                    active:      false
                    onClicked:   Quickshell.execDetached(["hyprshade", "toggle", "blue-light-filter"])
                }
            }

            // Bottom spacer
            Item { implicitHeight: 4 }
        }
    }

    // Close when clicking outside
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.panelVisible = false
    }
}
