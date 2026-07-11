import QtQuick
import Quickshell
import ".." as BarModule
import "../../../services"

// Clock: HH:mm with small date below
Item {
    id: root
    
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        anchors.centerIn: parent
        spacing: -2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.format("h:mm AP")
            color: BarModule.Palette.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.dateStr
            color: BarModule.Palette.subtext0
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
        }
    }
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/hebi", "call", "calendar", "toggle"]);
        }
    }
}
