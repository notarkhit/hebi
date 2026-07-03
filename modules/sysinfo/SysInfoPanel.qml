pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../components"
import Quickshell.Wayland
import Hebi.Blobs
import "../../services"

PanelWindow {
    id: root

    property bool panelVisible: false
    property bool windowVisible: false

    onPanelVisibleChanged: {
        if (panelVisible)
            windowVisible = true;
        else
            closeTimer.restart();
    }

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

    Timer {
        id: closeTimer
        interval: 520
        onTriggered: root.windowVisible = false
    }

    anchors.right: true
    anchors.top: true
    anchors.left: false
    anchors.bottom: false

    implicitWidth: 320
    implicitHeight: 500

    color: "transparent"
    visible: root.windowVisible

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    mask: panelVisible ? activeRegion : emptyRegion
    Region {
        id: emptyRegion
    }
    Region {
        id: activeRegion
        x: root.implicitWidth - wrapper.width
        y: wrapper.y + wrapper.transform[0].y
        width: wrapper.width
        height: wrapper.height
    }

    // ── animated wrapper ───────────────────────────────────────────────────────
    Item {
        id: wrapper
        anchors.right: parent.right
        x: 0
        y: 0
        width: 312
        height: col.implicitHeight + 52

        property real offsetScale: root.panelVisible ? 0 : 1
        Behavior on offsetScale {
            Anim {}
        }
        transform: Translate {
            y: (-wrapper.height - 5) * wrapper.offsetScale
        }
        opacity: 1 - offsetScale

        BlobGroup {
            id: bgGroup
            color: Theme.surface
        }
        BlobRect {
            group: bgGroup
            anchors.fill: parent
            radius: 20
            stiffness: 200
            damping: 18
            deformScale: 0.004
        }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.leftMargin: 16
            anchors.rightMargin: 24
            anchors.bottomMargin: 16
            spacing: 0

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
                value: SystemInfoService.tempCelsius > 0 ? Math.round(SystemInfoService.tempCelsius) + " °C" : "—"
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

            Item {
                implicitHeight: 4
            }
        }
    }

    component InfoRow: Item {
        property string icon: ""
        property string label: ""
        property string value: ""
        property real fillPct: -1
        property color accentColor: "#ffffff"
        Layout.fillWidth: true
        implicitHeight: 30
        RowLayout {
            anchors.fill: parent
            spacing: 10
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
            Text {
                text: label
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: "#a9b1d6"
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
            }
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

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.panelVisible = false
    }
}
