pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import ".." as Bar
import "../../../services"

// Single numbered workspace pill
Item {
    id: root

    required property int index
    required property int activeWsId

    readonly property int  wsId:     index + 1
    readonly property bool active:   activeWsId === wsId
    readonly property var  ws:       Hypr.workspaces.values.find(w => w.id === wsId)
    readonly property bool occupied: ws !== undefined

    // Show 1-5 always; show 6+ only when active or has windows
    visible: wsId <= 5 || active || occupied

    implicitHeight: 16
    implicitWidth:  active ? 26 : 16

    Behavior on implicitWidth {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        layer.enabled: true
        color: root.active   ? Bar.Palette.blue
             : root.occupied ? Bar.Palette.surface1
             :                 "transparent"
        border.color: root.active || root.occupied ? "transparent" : Bar.Palette.surface1
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: root.wsId
            font.family:    "FiraMono Nerd Font"
            font.pixelSize: 9
            font.bold:      root.active
            color: root.active   ? Bar.Palette.base
                 : root.occupied ? Bar.Palette.text
                 :                 Bar.Palette.overlay0

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    TapHandler {
        onTapped: Hypr.dispatch("workspace " + root.wsId)
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
