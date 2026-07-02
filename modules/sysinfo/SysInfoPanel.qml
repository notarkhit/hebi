pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Hebi.Blobs
import "../../services"

// Standalone System Info popup panel.
// Mirrors the SettingsPanel blob animation exactly.
// Toggled via IPC target "sysinfo".
PanelWindow {
    id: root

    property bool panelVisible: false

    IpcHandler {
        target: "sysinfo"
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
    anchors.top: true
    anchors.left: false
    anchors.bottom: false

    implicitWidth: 320
    implicitHeight: content.implicitHeight + 80
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

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

    // ── panel blob ────────────────────────────────────────────────────────────
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

            // Closed: approximate position of the SysInfoButton in the bar
            // (sits to the left of the SysInfo pill which is ~140px from right)
            property real closedX: root.width - 12 - 270
            property real closedY: 0
            property real closedW: 120
            property real closedH: 20

            // Open: flush to top-right, pushed off-screen to hide radius
            property real openX: root.width - 300
            property real openY: -20
            property real openW: 312
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

        // Overlay border matching the expanding BlobRect


        // Clip wrapper — bounds content to the expanding box
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

                // Fade in after blob has expanded
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

                implicitWidth: 312
                implicitHeight: col.implicitHeight + 52
                layer.enabled: true

                ColumnLayout {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 36
                    anchors.leftMargin: 16
                    anchors.rightMargin: 24
                    spacing: 0

                    // ── Heading ───────────────────────────────────────────────
                    Text {
                        text: "System Info"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: "#c0caf5"
                        Layout.bottomMargin: 10
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: "#24283b"
                        Layout.bottomMargin: 6
                    }

                    // ── Rows ──────────────────────────────────────────────────
                    InfoRow {
                        icon: "\u{f4bc}"
                        label: "CPU Usage"
                        fillPct: SystemInfoService.cpuPercent
                        value: Math.round(SystemInfoService.cpuPercent) + "%"
                        accentColor: SystemInfoService.cpuPercent > 85 ? "#f7768e" : SystemInfoService.cpuPercent > 60 ? "#e0af68" : "#ffffff"
                    }
                    InfoRow {
                        icon: "\u{efc5}"
                        label: "Memory Usage"
                        fillPct: SystemInfoService.ramPercent
                        value: Math.round(SystemInfoService.ramPercent) + "%"
                        accentColor: SystemInfoService.ramPercent > 85 ? "#f7768e" : SystemInfoService.ramPercent > 70 ? "#e0af68" : "#ffffff"
                    }
                    InfoRow {
                        icon: "\u{f0e2}"
                        label: "Swap Usage"
                        fillPct: SystemInfoService.swapPercent
                        value: Math.round(SystemInfoService.swapPercent) + "%"
                        accentColor: SystemInfoService.swapPercent > 80 ? "#f7768e" : SystemInfoService.swapPercent > 50 ? "#e0af68" : "#ffffff"
                    }
                    InfoRow {
                        icon: "\u{f2c7}"
                        label: "Temperature"
                        fillPct: -1
                        value: SystemInfoService.tempCelsius > 0 ? Math.round(SystemInfoService.tempCelsius) + " \u00b0C" : "\u2014"
                        accentColor: SystemInfoService.tempCelsius > 85 ? "#f7768e" : SystemInfoService.tempCelsius > 70 ? "#e0af68" : "#ffffff"
                    }
                    InfoRow {
                        icon: "\u{f0a0}"
                        label: "Disk Usage /"
                        fillPct: SystemInfoService.diskPercent
                        value: Math.round(SystemInfoService.diskPercent) + "%"
                        accentColor: SystemInfoService.diskPercent > 90 ? "#f7768e" : SystemInfoService.diskPercent > 75 ? "#e0af68" : "#ffffff"
                    }
                    InfoRow {
                        icon: "\u{f019}"
                        label: "Download Speed"
                        fillPct: -1
                        value: SystemInfoService.fmtSpeed(SystemInfoService.rxKbps)
                        accentColor: "#ffffff"
                    }
                    InfoRow {
                        icon: "\u{f093}"
                        label: "Upload Speed"
                        fillPct: -1
                        value: SystemInfoService.fmtSpeed(SystemInfoService.txKbps)
                        accentColor: "#ffffff"
                    }

                    // Bottom spacer
                    Item {
                        implicitHeight: 4
                    }
                }
            }
        }
    }

    // ── Inline row component ──────────────────────────────────────────────────
    component InfoRow: Item {
        property string icon: ""
        property string label: ""
        property string value: ""
        property real fillPct: -1
        property color accentColor: "#ffffff"  // white by default, callers override per metric

        Layout.fillWidth: true
        implicitHeight: 30

        RowLayout {
            anchors.fill: parent
            spacing: 10

            // Icon — white, tinted with accentColor when not nominal
            Text {
                text: icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: accentColor
                opacity: 0.9
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 20
                Behavior on color {
                    ColorAnimation {
                        duration: 300
                    }
                }
            }

            // Label — stays subtle grey
            Text {
                text: label
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: "#a9b1d6"
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
            }

            // Mini progress bar
            Item {
                visible: fillPct >= 0
                implicitWidth: 44
                implicitHeight: 4
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: "#1e2235"
                }
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(100, fillPct)) / 100
                    height: parent.height
                    radius: 2
                    color: accentColor
                    Behavior on width {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }
                    }
                }
            }

            // Value — white, coloured when metric is elevated
            Text {
                text: value
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: accentColor
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 72
                Behavior on color {
                    ColorAnimation {
                        duration: 300
                    }
                }
            }
        }
    }

    // Close on outside click
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.panelVisible = false
    }
}
