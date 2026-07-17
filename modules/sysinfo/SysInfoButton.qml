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
        spacing: 6

        // CPU group
        Item {
            Layout.preferredWidth: 40
            implicitHeight: 14
            Row {
                anchors.centerIn: parent
                spacing: 4
                
                Text {
                    text: "\u{f4bc}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: SystemInfoService.cpuPercent > 85 ? Theme.error : SystemInfoService.cpuPercent > 60 ? Theme.warning : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: Math.round(SystemInfoService.cpuPercent) + "%"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: SystemInfoService.cpuPercent > 85 ? Theme.error : SystemInfoService.cpuPercent > 60 ? Theme.warning : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // RAM group
        Item {
            Layout.preferredWidth: 40
            implicitHeight: 14
            Row {
                anchors.centerIn: parent
                spacing: 4
                
                Text {
                    text: "\u{efc5}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: SystemInfoService.ramPercent > 85 ? Theme.error : SystemInfoService.ramPercent > 70 ? Theme.warning : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: Math.round(SystemInfoService.ramPercent) + "%"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: SystemInfoService.ramPercent > 85 ? Theme.error : SystemInfoService.ramPercent > 70 ? Theme.warning : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Temp group (hidden if no sensor)
        Item {
            visible: SystemInfoService.tempCelsius > 0
            Layout.preferredWidth: 38
            implicitHeight: 14
            Row {
                anchors.centerIn: parent
                spacing: 4
                
                Text {
                    text: "\u{f2c7}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: SystemInfoService.tempCelsius > 85 ? Theme.error : SystemInfoService.tempCelsius > 70 ? Theme.warning : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: Math.round(SystemInfoService.tempCelsius) + "\u00b0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: SystemInfoService.tempCelsius > 85 ? Theme.error : SystemInfoService.tempCelsius > 70 ? Theme.warning : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Download group
        Item {
            Layout.preferredWidth: 58
            implicitHeight: 14
            Row {
                anchors.centerIn: parent
                spacing: 4
                
                Text {
                    text: "\u{f019}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: SystemInfoService.fmtSpeed(SystemInfoService.rxKbps)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
