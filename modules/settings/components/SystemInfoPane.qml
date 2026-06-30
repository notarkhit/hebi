// System Info pane — shown at the bottom of the settings panel.
// Uses SystemInfoService for live metrics (CPU, RAM, swap, temp, disk, IP, net).
import QtQuick
import QtQuick.Layouts
import "../../../services"

Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 2

        // Section heading
        Text {
            text: "System Info"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: "#565f89"
            font.letterSpacing: 0.8
            Layout.bottomMargin: 4
        }

        // CPU
        SysInfoRow {
            iconText: "\u{f4bc}"    // nf-md-cpu_64_bit
            label: "CPU"
            fillPercent: SystemInfoService.cpuPercent
            value: Math.round(SystemInfoService.cpuPercent) + "%"
        }

        // Memory
        SysInfoRow {
            iconText: "\u{efc5}"    // nf-md-memory
            label: "Memory"
            fillPercent: SystemInfoService.ramPercent
            value: Math.round(SystemInfoService.ramPercent) + "%"
        }

        // Swap
        SysInfoRow {
            iconText: "\u{f0e2}"    // nf-fa-refresh (swap)
            label: "Swap"
            fillPercent: SystemInfoService.swapPercent
            value: Math.round(SystemInfoService.swapPercent) + "%"
        }

        // Temperature
        SysInfoRow {
            iconText: "\u{f2c7}"    // nf-fa-thermometer_half
            label: "Temperature"
            fillPercent: -1
            value: SystemInfoService.tempCelsius > 0
                   ? Math.round(SystemInfoService.tempCelsius) + " °C"
                   : "—"
        }

        // Disk
        SysInfoRow {
            iconText: "\u{f0a0}"    // nf-fa-hdd_o
            label: "Disk /"
            fillPercent: SystemInfoService.diskPercent
            value: Math.round(SystemInfoService.diskPercent) + "%"
        }

        // IP address
        SysInfoRow {
            iconText: "\u{f015}"    // nf-fa-home (network)
            label: "IP Address"
            fillPercent: -1
            value: SystemInfoService.ipAddress
        }

        // Download
        SysInfoRow {
            iconText: "\u{f019}"    // nf-fa-download
            label: "Download"
            fillPercent: -1
            value: SystemInfoService.fmtSpeed(SystemInfoService.rxKbps)
        }

        // Upload
        SysInfoRow {
            iconText: "\u{f093}"    // nf-fa-upload
            label: "Upload"
            fillPercent: -1
            value: SystemInfoService.fmtSpeed(SystemInfoService.txKbps)
        }
    }
}
