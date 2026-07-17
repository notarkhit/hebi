pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"

Item {
    id: root

    required property bool panelVisible

    signal closeRequested

    readonly property real currentHeight: col.implicitHeight + 52
    readonly property real panelWidth: 312

    implicitWidth: panelWidth
    implicitHeight: currentHeight

    property real offsetScale: root.panelVisible ? 0 : 1
    Behavior on offsetScale {
        Anim {}
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
            color: Theme.text
            Layout.bottomMargin: 10
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.surfaceHex
            Layout.bottomMargin: 6
        }

        InfoRow {
            icon: "\u{f4bc}"
            label: "CPU Usage"
            fillPct: SystemInfoService.cpuPercent
            value: Math.round(SystemInfoService.cpuPercent) + "%"
            accentColor: SystemInfoService.cpuPercent > 85 ? Theme.error : SystemInfoService.cpuPercent > 60 ? Theme.warning : Theme.text
        }
        InfoRow {
            icon: "\u{efc5}"
            label: "Memory Usage"
            fillPct: SystemInfoService.ramPercent
            value: Math.round(SystemInfoService.ramPercent) + "%"
            accentColor: SystemInfoService.ramPercent > 85 ? Theme.error : SystemInfoService.ramPercent > 70 ? Theme.warning : Theme.text
        }
        InfoRow {
            icon: "\u{f0e2}"
            label: "Swap Usage"
            fillPct: SystemInfoService.swapPercent
            value: Math.round(SystemInfoService.swapPercent) + "%"
            accentColor: SystemInfoService.swapPercent > 80 ? Theme.error : SystemInfoService.swapPercent > 50 ? Theme.warning : Theme.text
        }
        InfoRow {
            icon: "\u{f2c7}"
            label: "Temperature"
            fillPct: -1
            value: SystemInfoService.tempCelsius > 0 ? Math.round(SystemInfoService.tempCelsius) + " °C" : "—"
            accentColor: SystemInfoService.tempCelsius > 85 ? Theme.error : SystemInfoService.tempCelsius > 70 ? Theme.warning : Theme.text
        }
        InfoRow {
            icon: "\u{f0a0}"
            label: "Disk Usage /"
            fillPct: SystemInfoService.diskPercent
            value: Math.round(SystemInfoService.diskPercent) + "%"
            accentColor: SystemInfoService.diskPercent > 90 ? Theme.error : SystemInfoService.diskPercent > 75 ? Theme.warning : Theme.text
        }
        InfoRow {
            icon: "\u{f019}"
            label: "Download Speed"
            fillPct: -1
            value: SystemInfoService.fmtSpeed(SystemInfoService.rxKbps)
            accentColor: Theme.text
        }
        InfoRow {
            icon: "\u{f093}"
            label: "Upload Speed"
            fillPct: -1
            value: SystemInfoService.fmtSpeed(SystemInfoService.txKbps)
            accentColor: Theme.text
        }

        Item {
            implicitHeight: 4
        }
    }

    component InfoRow: Item {
        property string icon: ""
        property string label: ""
        property string value: ""
        property real fillPct: -1
        property color accentColor: Theme.text
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
                color: Theme.secondary
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
                    color: Theme.surfaceHex
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
}
