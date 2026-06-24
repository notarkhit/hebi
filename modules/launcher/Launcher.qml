pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

Scope {
    id: root

    property bool launcherVisible: false
    property bool windowVisible: false

    onLauncherVisibleChanged: {
        if (launcherVisible)
            windowVisible = true;
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.launcherVisible = !root.launcherVisible;
        }
    }

    Loader {
        id: loader
        active: root.windowVisible
        sourceComponent: Component {
            PanelWindow {
                id: overlay

                Connections {
                    target: root
                    function onLauncherVisibleChanged() {
                        if (!root.launcherVisible)
                            closeTimer.restart();
                    }
                }

                Timer {
                    id: closeTimer
                    interval: 150
                    onTriggered: root.windowVisible = false
                }

                readonly property string font: "JetBrainsMono Nerd Font"

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                color: "transparent"

                visible: root.windowVisible
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: root.launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                onVisibleChanged: {
                    if (visible) {
                        searchField.text = "";
                        searchField.forceActiveFocus();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.launcherVisible = false
                }

                Item {
                    id: card

                    width: 560
                    readonly property int fullHeight: stack.implicitHeight + 56
                    height: fullHeight

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom

                    property real clipHeight: 0

                    Component.onCompleted: {
                        clipHeight = Qt.binding(function () {
                            return root.launcherVisible ? card.fullHeight : 0;
                        });
                    }

                    Behavior on clipHeight {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                    }

                    Item {
                        id: contentItem
                        width: parent.width
                        height: card.clipHeight
                        anchors.bottom: parent.bottom
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: -12
                            color: "#1a1b26"
                            radius: 12
                            border.color: "#414868"
                            border.width: 1

                            layer.enabled: true
                        }

                        RowLayout {
                            id: searchRow
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Text {
                                text: {
                                    if (contentItem.mode === "calc")
                                        return "󰃬";
                                    if (contentItem.mode === "nerdfont")
                                        return "";
                                    if (contentItem.mode === "emoji")
                                        return "";
                                    return "󱓞";
                                }
                                color: "#7aa2f7"
                                font.family: overlay.font
                                font.pixelSize: 16
                                verticalAlignment: Text.AlignVCenter
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on text {}
                            }

                            TextInput {
                                id: searchField

                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                color: "#c0caf5"
                                font.family: overlay.font
                                font.pixelSize: 14
                                clip: true

                                Text {
                                    anchors.fill: parent
                                    text: "Search apps..."
                                    color: "#565f89"
                                    font.family: overlay.font
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                    visible: !searchField.text
                                }

                                Keys.onEscapePressed: {
                                    root.launcherVisible = false;
                                    text = "";
                                }

                                Keys.onUpPressed: {
                                    const activeView = stack.activeView;
                                    if (activeView && activeView.handleUp)
                                        activeView.handleUp();
                                }
                                Keys.onDownPressed: {
                                    const activeView = stack.activeView;
                                    if (activeView && activeView.handleDown)
                                        activeView.handleDown();
                                }
                                Keys.onReturnPressed: {
                                    const activeView = stack.activeView;
                                    if (activeView && activeView.handleReturn)
                                        activeView.handleReturn();
                                }
                            }

                            Text {
                                text: ""
                                color: "#565f89"
                                font.family: overlay.font
                                font.pixelSize: 14
                                visible: searchField.text.length > 0
                                Layout.alignment: Qt.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: searchField.text = ""
                                }
                            }
                        }

                        readonly property string mode: {
                            const t = searchField.text;
                            if (t.startsWith("="))
                                return "calc";
                            if (t.startsWith("::"))
                                return "nerdfont";
                            if (t.startsWith(":"))
                                return "emoji";
                            return "apps";
                        }

                        Item {
                            id: stack
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: searchRow.top
                            anchors.bottomMargin: 8
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6

                            readonly property var activeView: {
                                if (contentItem.mode === "calc")      return calcView;
                                if (contentItem.mode === "emoji")     return emojiView;
                                if (contentItem.mode === "nerdfont")  return nerdfontView;
                                return appsView;
                            }

                            implicitHeight: activeView ? activeView.implicitHeight : 0

                            LauncherApps {
                                id: appsView
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                visible: contentItem.mode === "apps"
                                query: contentItem.mode === "apps" ? searchField.text.trim() : ""
                                onAction: root.launcherVisible = false
                            }
                            LauncherCalc {
                                id: calcView
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                visible: contentItem.mode === "calc"
                                expr: contentItem.mode === "calc" ? searchField.text.slice(1).trim() : ""
                                onAction: root.launcherVisible = false
                            }
                            LauncherEmoji {
                                id: emojiView
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                visible: contentItem.mode === "emoji"
                                query: contentItem.mode === "emoji" ? searchField.text.slice(1).toLowerCase().trim() : ""
                                onAction: root.launcherVisible = false
                            }
                            LauncherNerdfont {
                                id: nerdfontView
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                visible: contentItem.mode === "nerdfont"
                                query: contentItem.mode === "nerdfont" ? searchField.text.slice(2).toLowerCase().trim() : ""
                                onAction: root.launcherVisible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
