pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "components"
import "../sysinfo"
import "../../services"

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
    color: Theme.surface

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

        // System tray (SNI applets — qBittorrent, Telegram, etc.)
        Tray {
            Layout.alignment: Qt.AlignVCenter
        }

        // Thin divider
        Rectangle {
            implicitWidth:  1
            implicitHeight: 14
            color: "#2a2d3e"
            Layout.alignment: Qt.AlignVCenter
        }

        // System info stats button (opens SysInfoPanel)
        SysInfoButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: Quickshell.execDetached(["qs", "ipc", "-p", "/home/notarkhit/.config/hebi", "call", "sysinfo", "toggle"])
        }

        // System info: network · volume · battery (opens settings)
        SysInfo {
            Layout.alignment: Qt.AlignVCenter
            onClicked: Quickshell.execDetached(["qs", "ipc", "-p", "/home/notarkhit/.config/hebi", "call", "settings", "toggle"])
        }
    }
}
