// Small bar widget that shows live CPU % + temp and opens the SysInfo panel on click.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"

Item {
    id: root
    signal clicked()

    implicitWidth:  row.implicitWidth + 16
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        // CPU icon
        Text {
            text: "\u{f4bc}"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: SystemInfoService.cpuPercent > 85 ? "#f7768e"
                 : SystemInfoService.cpuPercent > 60 ? "#e0af68"
                 : "#ffffff"
            opacity: 0.9
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // CPU %
        Text {
            text: Math.round(SystemInfoService.cpuPercent) + "%"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: SystemInfoService.cpuPercent > 85 ? "#f7768e"
                 : SystemInfoService.cpuPercent > 60 ? "#e0af68"
                 : "#ffffff"
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // RAM icon
        Text {
            text: "\u{efc5}"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: SystemInfoService.ramPercent > 85 ? "#f7768e"
                 : SystemInfoService.ramPercent > 70 ? "#e0af68"
                 : "#ffffff"
            opacity: 0.9
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // RAM %
        Text {
            text: Math.round(SystemInfoService.ramPercent) + "%"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: SystemInfoService.ramPercent > 85 ? "#f7768e"
                 : SystemInfoService.ramPercent > 70 ? "#e0af68"
                 : "#ffffff"
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Temp icon (only if sensor available)
        Text {
            visible: SystemInfoService.tempCelsius > 0
            text: "\u{f2c7}"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: SystemInfoService.tempCelsius > 85 ? "#f7768e"
                 : SystemInfoService.tempCelsius > 70 ? "#e0af68"
                 : "#ffffff"
            opacity: 0.9
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Temp value
        Text {
            visible: SystemInfoService.tempCelsius > 0
            text: Math.round(SystemInfoService.tempCelsius) + "°"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: SystemInfoService.tempCelsius > 85 ? "#f7768e"
                 : SystemInfoService.tempCelsius > 70 ? "#e0af68"
                 : "#ffffff"
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Net download icon
        Text {
            text: "\u{f019}"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#ffffff"
            opacity: 0.9
            Layout.alignment: Qt.AlignVCenter
        }

        // Net download speed
        Text {
            text: SystemInfoService.fmtSpeed(SystemInfoService.rxKbps)
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: "#ffffff"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
