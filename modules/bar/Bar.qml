pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "components"

// Per-screen horizontal top bar
PanelWindow {
    id: root

    required property ShellScreen screen

    readonly property string font: "FiraMono Nerd Font"
    readonly property int    barHeight: 32

    screen: root.screen
    anchors.top:   true
    anchors.left:  true
    anchors.right: true
    implicitHeight: barHeight
    color: Qt.rgba(0x1a/255, 0x1b/255, 0x26/255, 0.92)

    WlrLayershell.exclusiveZone: barHeight
    WlrLayershell.layer: WlrLayer.Top

    // ── bottom border ────────────────────────────────────────────────────────
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#3b4261"
    }

    // ── content row ──────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill:         parent
        anchors.leftMargin:   12
        anchors.rightMargin:  12
        spacing: 12

        // Logo
        Text {
            text: "" 
            color: "#7aa2f7"
            font.family: root.font
            font.pixelSize: 20

            opacity: 0
            NumberAnimation on opacity {
                from: 0; to: 1; duration: 600
                easing.type: Easing.OutCubic; running: true
            }


        }

        // Workspaces
        Workspaces {
            Layout.alignment: Qt.AlignVCenter
        }

        // Active window title
        ActiveWindow {
            Layout.fillWidth:  true
            Layout.alignment:  Qt.AlignVCenter
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // Clock
        Clock {
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
