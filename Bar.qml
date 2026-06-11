import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    property color colBg: "#1e1e2e"
    property color colFg: "#cdd6f4"
    property color colMuted: "#45475a"
    property color colSurface: "#313244"
    property color colBlue: "#89b4fa"
    property color colText: "#cdd6f4"
    property string fontFamily: "FiraMono Nerd Font"
    property int fontSize: 12

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    color: root.colBg

    WlrLayershell.exclusiveZone: implicitHeight

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        // Left: custom label
        Text {
            text: "󰣇 archlinux"
            color: root.colBlue
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.weight: Font.Medium

            opacity: 0
            NumberAnimation on opacity {
                from: 0
                to: 1
                duration: 600
                easing.type: Easing.OutCubic
                running: true
            }
        }

        RowLayout {
            spacing: 5

            Repeater {
                model: 10

                Rectangle {
                    property bool active: Hyprland.focusedWorkspace?.id === (index + 1)
                    property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)

                    width: active ? 28 : 22
                    height: 22
                    radius: 11
                    color: active ? root.colBlue : (ws ? root.colSurface : "transparent")

                    Behavior on width {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: index + 1
                        color: parent.active ? root.colBg : (parent.ws ? root.colText : root.colMuted)
                        font.family: root.fontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Right: clock
        Text {
            id: clock
            text: Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
            color: root.colFg
            font.family: root.fontFamily
            font.pixelSize: root.fontSize

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
            }
        }
    }
}
