import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"

Rectangle {
    id: root

    property string artist: Players.active?.trackArtist ?? ""
    property string title: Players.active?.trackTitle ?? ""

    visible: Players.active !== null

    implicitHeight: 28
    implicitWidth: layout.implicitWidth + 24
    radius: 14
    color: hoverHandler.hovered ? Qt.rgba(122/255, 162/255, 247/255, 0.1) : "transparent"
    border.color: hoverHandler.hovered ? "#7aa2f7" : "transparent"
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }
    
    function updateOffset() {
        if (!root.visible || !root.Window.window) return;
        const globalX = root.mapToItem(null, 0, 0).x;
        Players.mediaCenterRightOffset = root.Window.width - (globalX + root.width / 2);
    }
    
    onXChanged: root.updateOffset()
    onWidthChanged: root.updateOffset()
    
    Timer {
        running: root.visible
        interval: 100
        repeat: true
        onTriggered: root.updateOffset()
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: Quickshell.execDetached(["qs", "ipc", "-p", "/home/notarkhit/.config/hebi", "call", "media", "toggle"])
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: "󰎆"
            color: "#7aa2f7"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.artist ? root.artist + " - " + root.title : root.title
            color: "#c0caf5"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 200
            elide: Text.ElideRight
        }
    }
}
