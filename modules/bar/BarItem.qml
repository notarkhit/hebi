pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "components"
import "../sysinfo"
import "../../services"

// The visual content of the bar (lives inside MainWindow to share the blob layer)
Item {
    id: root

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int barHeight: 32

    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: barHeight
    
    // Background color is provided by the blobLayer in MainWindow

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

        // Media control
        Media {
            Layout.alignment: Qt.AlignVCenter
        }

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
