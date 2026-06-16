import QtQuick
import Quickshell
import Quickshell.Widgets

PanelWindow {
    color: "transparent"
    width: 200
    height: 100

    Row {
        spacing: 10
        anchors.centerIn: parent

        // Standard IconImage
        IconImage {
            implicitSize: 32
            source: Quickshell.iconPath("firefox")
        }

        // IconImage with fillMode
        IconImage {
            width: 32
            height: 32
            fillMode: Image.PreserveAspectFit
            source: Quickshell.iconPath("firefox")
        }
        
        // Standard Qt Image using image://icon/
        Image {
            width: 32
            height: 32
            sourceSize: Qt.size(32, 32)
            source: "image://icon/firefox"
            fillMode: Image.PreserveAspectFit
        }
    }
}
