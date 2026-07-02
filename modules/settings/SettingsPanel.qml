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

    implicitWidth: 404
    implicitHeight: content.implicitHeight + 80
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Only grab input over the actual panel when visible
    mask: panelVisible ? activeRegion : emptyRegion

    Region {
        id: emptyRegion
    }
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
        color: Theme.surface
    }

    Item {
        id: container
        anchors.fill: parent

        BlobRect {
            id: panelBg
            group: bgGroup

            // Closed state: position of the SysInfo pill in the bar
            property real closedX: root.width - 12 - 140
            property real closedY: 0
            property real closedW: 140
            property real closedH: 20

            // Open state: flush to top-right, pushed off-screen to hide radius
            property real openX: root.width - 380
            property real openY: -20
            property real openW: 400
            property real openH: col.implicitHeight + 52

            x: root.panelVisible ? openX : closedX
            y: root.panelVisible ? openY : closedY
            width: root.panelVisible ? openW : closedW
            height: root.panelVisible ? openH : closedH
            radius: root.panelVisible ? 20 : 10

            stiffness: 200
            damping: 18
            deformScale: 0.004

            Behavior on x {
                NumberAnimation {
                    duration: 320
                    easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 320
                    easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 320
                    easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: 320
                    easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic
                }
            }
            Behavior on radius {
                NumberAnimation {
                    duration: 320
                    easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic
                }
            }

            // Fade in instantly, fade out slowly so the blob retract is visible
            opacity: root.panelVisible ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: root.panelVisible ? 80 : 280
                }
            }
        }



        // Clip wrapper that bounds the content exactly to the expanding box
        Item {
            x: panelBg.x
            y: panelBg.y
            width: panelBg.width
            height: panelBg.height
            clip: true

            Item {
                id: content
                anchors.right: parent.right
                anchors.top: parent.top
                width: panelBg.openW
                height: panelBg.openH

                // Only become visible well after the blob has expanded
                opacity: root.panelVisible ? 1 : 0
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: root.panelVisible ? 300 : 0
                        }
                        NumberAnimation {
                            duration: root.panelVisible ? 180 : 80
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                implicitWidth: 400
                implicitHeight: col.implicitHeight + 52

                layer.enabled: true
                // Do NOT clip the inner content, the wrapper handles it!

                ColumnLayout {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 36
                    anchors.rightMargin: 36
                    anchors.leftMargin: 16
                    anchors.bottomMargin: 16
                    spacing: 12

                    // ── Header: battery + actions ─────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Battery icon + label
                        Text {
                            text: {
                                if (!root.hasBat)
                                    return "\u{f109}";   // 󰄉 desktop
                                if (root.batCharging)
                                    return "\u{f0e7}"; // ⚡ bolt
                                const p = root.batPct;
                                if (p >= 0.90)
                                    return "\u{f240}"; // 󰉀 full
                                if (p >= 0.75)
                                    return "\u{f241}"; // 󰉁 3/4
                                if (p >= 0.50)
                                    return "\u{f242}"; // 󰉂 half
                                if (p >= 0.25)
                                    return "\u{f243}"; // 󰉃 1/4
                                return "\u{f244}";                // 󰉄 empty
                            }
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            Layout.alignment: Qt.AlignVCenter
                            color: root.hasBat && root.batPct < 0.20 && !root.batCharging ? "#f7768e" : "#ffffff"
                            opacity: 1.0
                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                }
                            }
                        }
                        Text {
                            text: root.hasBat ? `${Math.round(root.batPct * 100)}%${root.batCharging ? " ⚡" : ""}` : "Desktop"
                            color: "#ffffff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
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
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                color: "#ffffff"
                                opacity: lockHov.containsMouse ? 1.0 : 0.9
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }
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
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                color: "#ffffff"
                                opacity: powerHov.containsMouse ? 1.0 : 0.9
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }
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
                        iconText: AudioService.muted || AudioService.volume <= 0 ? "" : AudioService.volume <= 0.33 ? "" : AudioService.volume <= 0.66 ? "墳" : ""
                        value: AudioService.volume
                        maxValue: 1.5
                        onChanged: v => AudioService.setVolume(v)
                    }

                    // Microphone (read-only for now — future: pactl set-source-volume)
                    SliderRow {
                        Layout.fillWidth: true
                        iconText: ""
                        value: 0.8
                        maxValue: 1.0
                        showArrow: true
                        onArrowClicked: Quickshell.execDetached(["pavucontrol"])
                    }

                    // Brightness
                    SliderRow {
                        Layout.fillWidth: true
                        iconText: ""
                        value: BrightnessService.brightness
                        maxValue: 1.0
                        onChanged: v => BrightnessService.setBrightness(v)
                    }

                    // ── Divider ───────────────────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: "#1e2235"
                        opacity: 0.8
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
                            iconText: root.ethUp ? "" : root.wifiUp ? "" : "睊"
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
                            iconText: ""
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
                            iconText: ""
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
                            iconText: ""
                            label: "Do Not Disturb"
                            active: Notifs.dnd
                            onClicked: Notifs.dnd = !Notifs.dnd
                        }

                        // Idle Inhibitor
                        TogglePill {
                            Layout.fillWidth: true
                            iconText: ""
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
                            iconText: ""
                            label: "Night Light"
                            active: false
                            onClicked: Quickshell.execDetached(["hyprshade", "toggle", "blue-light-filter"])
                        }
                    }

                    // Bottom spacer
                    Item {
                        implicitHeight: 4
                    }
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
