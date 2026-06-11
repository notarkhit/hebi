import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property string time

    Variants {
        model: Quickshell.screens

        PanelWindow {
            Component.onCompleted: console.log(JSON.stringify(HyprlandIpc.workspaces))
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 30
            color: "#1e1e2e"

            WlrLayershell.exclusiveZone: implicitHeight

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                // Left: custom label
                Text {
                    text: "hebi"
                    color: "#89b4fa"
                    font.family: "FiraMono Nerd Font"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                // Center: workspaces
                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 5
                    Repeater {
                        model: HyprlandIpc.workspaces.sort((a, b) => a.id - b.id)
                        Rectangle {
                            required property var modelData
                            property bool active: modelData.id === HyprlandIpc.focusedWorkspace?.id
                            width: active ? 28 : 22
                            height: 22
                            radius: 11
                            color: active ? "#89b4fa" : "#313244"
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
                                text: modelData.id
                                color: parent.active ? "#1e1e2e" : "#cdd6f4"
                                font.family: "FiraMono Nerd Font"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: HyprlandIpc.dispatch("workspace " + modelData.id)
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Right: time (your existing logic)
                Text {
                    text: root.time
                    color: "#cdd6f4"
                    font.family: "FiraMono Nerd Font"
                    font.pixelSize: 12
                }
            }
        }
    }

    Process {
        id: dateProc
        command: ["date"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.time = this.text
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: dateProc.running = true
    }
}
