pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Hebi.Blobs
import "../../services"

// Notification Manager popup panel.
// Toggled via IPC target "notifmanager".
PanelWindow {
    id: root

    property bool panelVisible: false

    onPanelVisibleChanged: {
        Notifs.managerOpen = panelVisible;
        if (panelVisible) {
            Notifs.clearPopups();
        }
    }

    IpcHandler {
        target: "notifmanager"
        function toggle(): void {
            root.panelVisible = !root.panelVisible;
        }
        function open(): void {
            root.panelVisible = true;
        }
        function close(): void {
            root.panelVisible = false;
        }
    }

    // ── window setup ──────────────────────────────────────────────────────────
    anchors.right: true
    anchors.top: true
    anchors.left: false
    anchors.bottom: false

    implicitWidth: 340
    implicitHeight: Math.min(800, content.implicitHeight + 80)
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: panelVisible ? activeRegion : emptyRegion
    Region {
        id: emptyRegion
    }
    Region {
        id: activeRegion
        x: content.x
        y: content.y
        width: content.width
        height: content.height
    }

    // ── panel blob ────────────────────────────────────────────────────────────
    BlobGroup {
        id: bgGroup
        color: Theme.surface
    }

    Item {
        id: container
        anchors.fill: parent

        BlobRect {
            id: panelBg
            group: bgGroup

            // Closed position matches the right area where SysInfo is
            property real closedX: root.width - 12 - 160
            property real closedY: 0
            property real closedW: 120
            property real closedH: 20

            // Open position
            property real openX: root.width - 320
            property real openY: -20
            property real openW: 332
            property real openH: Math.min(600, col.implicitHeight + 64)

            x: openX
            y: openY
            width: openW
            height: openH
            radius: 20

            stiffness: 200
            damping: 18
            deformScale: 0.004

            opacity: root.panelVisible ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        // Overlay border
        Rectangle {
            x: panelBg.x
            y: panelBg.y
            width: panelBg.width
            height: panelBg.height
            radius: panelBg.radius
            color: "transparent"
            border.color: "#2a2d3e"
            border.width: 1
            opacity: panelBg.opacity
        }

        // Clip wrapper
        Item {
            x: panelBg.x
            y: panelBg.y
            width: panelBg.width
            height: panelBg.height
            clip: true

            Item {
                id: content
                anchors.right: parent.right
                anchors.top: parent.top
                width: panelBg.openW
                height: panelBg.openH

                opacity: root.panelVisible ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                implicitWidth: 332
                implicitHeight: col.implicitHeight + 64
                layer.enabled: true

                ColumnLayout {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 36
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 0

                    // ── Heading ───────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 10

                        Text {
                            text: "Notifications"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: "#c0caf5"
                            Layout.fillWidth: true
                        }

                        // Clear all button
                        Rectangle {
                            visible: Notifs.history.length > 0
                            implicitWidth: clearText.implicitWidth + 12
                            implicitHeight: 20
                            radius: 4
                            color: clearHover.containsMouse ? "#f7768e22" : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Text {
                                id: clearText
                                anchors.centerIn: parent
                                text: "Clear All"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: clearHover.containsMouse ? "#f7768e" : "#565f89"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            MouseArea {
                                id: clearHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifs.clearHistory()
                            }
                        }
                    }

                    // ── List ──────────────────────────────────────────────────
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(500, list.contentHeight)
                        clip: true

                        ListView {
                            id: list
                            width: parent.width
                            implicitHeight: contentHeight
                            spacing: 8
                            interactive: true
                            boundsBehavior: Flickable.StopAtBounds

                            model: ScriptModel {
                                values: Notifs.history
                            }

                            delegate: NotifManagerCard {
                                width: ListView.view.width - 8
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            // Empty state
                            Item {
                                visible: Notifs.history.length === 0
                                width: parent.width
                                implicitHeight: 100

                                Text {
                                    anchors.centerIn: parent
                                    text: "No notifications"
                                    color: "#565f89"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                }
                            }
                        }
                    }

                    // Bottom spacer
                    Item {
                        implicitHeight: 8
                    }
                }
            }
        }
    }

    // Close on outside click
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.panelVisible = false
    }
}
