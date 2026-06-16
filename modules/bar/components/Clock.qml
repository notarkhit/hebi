import QtQuick
import ".." as BarModule
import "../../../services"

// Clock: HH:mm with small date below
Column {
    id: root

    spacing: -2

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.format("h:mm AP")
        color: BarModule.Palette.text
        font.family: "FiraMono Nerd Font"
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.dateStr
        color: BarModule.Palette.subtext0
        font.family: "FiraMono Nerd Font"
        font.pixelSize: 9
    }
}
