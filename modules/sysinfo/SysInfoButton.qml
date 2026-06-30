// Bar widget showing live CPU / RAM / temp / net — opens SysInfoPanel on click.
// Icon size matches SysInfo images (14px). Text color matches ActiveWindow (#c0caf5).
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

        // CPU icon — 14px matches SysInfo image size
        Text {
            text: "\u{f4bc}"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: SystemInfoService.cpuPercent > 85 ? "#f7768e"
                 : SystemInfoService.cpuPercent > 60 ? "#e0af68"
                 : "#c0caf5"
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // CPU % — 10px matches SysInfo battery text size
        Text {
            text: Math.round(SystemInfoService.cpuPercent) + "%"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            color: SystemInfoService.cpuPercent > 85 ? "#f7768e"
                 : SystemInfoService.cpuPercent > 60 ? "#e0af68"
                 : "#c0caf5"
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // RAM icon
        Text {
            text: "\u{efc5}"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: SystemInfoService.ramPercent > 85 ? "#f7768e"
                 : SystemInfoService.ramPercent > 70 ? "#e0af68"
                 : "#c0caf5"
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // RAM %
        Text {
            text: Math.round(SystemInfoService.ramPercent) + "%"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            color: SystemInfoService.ramPercent > 85 ? "#f7768e"
                 : SystemInfoService.ramPercent > 70 ? "#e0af68"
                 : "#c0caf5"
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Temp icon (hidden if no sensor)
        Text {
            visible: SystemInfoService.tempCelsius > 0
            text: "\u{f2c7}"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: SystemInfoService.tempCelsius > 85 ? "#f7768e"
                 : SystemInfoService.tempCelsius > 70 ? "#e0af68"
                 : "#c0caf5"
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Temp value
        Text {
            visible: SystemInfoService.tempCelsius > 0
            text: Math.round(SystemInfoService.tempCelsius) + "\u00b0"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            color: SystemInfoService.tempCelsius > 85 ? "#f7768e"
                 : SystemInfoService.tempCelsius > 70 ? "#e0af68"
                 : "#c0caf5"
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Download icon
        Text {
            text: "\u{f019}"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: "#c0caf5"
            Layout.alignment: Qt.AlignVCenter
        }

        // Download speed
        Text {
            text: SystemInfoService.fmtSpeed(SystemInfoService.rxKbps)
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            color: "#c0caf5"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
