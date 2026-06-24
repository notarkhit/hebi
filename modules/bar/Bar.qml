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

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int barHeight: 32

    screen: root.screen
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: barHeight
    color: Qt.rgba(0x1a / 255, 0x1b / 255, 0x26 / 255, 0.92)

    WlrLayershell.exclusiveZone: barHeight
    WlrLayershell.layer: WlrLayer.Top

    // ── center clock ─────────────────────────────────────────────────────────
    Clock {
        id: centerClock
        anchors.centerIn: parent
    }

    // ── left side ────────────────────────────────────────────────────────────
    RowLayout {
        anchors.left: parent.left
        anchors.right: centerClock.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Logo
        Text {
            text: ""
            color: "#7aa2f7"
            font.family: root.font
            font.pixelSize: 16

            opacity: 0
            NumberAnimation on opacity {
                from: 0
                to: 1
                duration: 600
                easing.type: Easing.OutCubic
                running: true
            }
        }

        // Workspaces
        Workspaces {
            Layout.alignment: Qt.AlignVCenter
        }

        // Active window title
        ActiveWindow {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // ── right side ───────────────────────────────────────────────────────────
    RowLayout {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 12
        spacing: 12

        // System info: network · volume · battery
        SysInfo {
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
