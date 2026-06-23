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
                    interval: 280
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
                    anchors.bottomMargin: 12

                    property real clipHeight: 0

                    Component.onCompleted: {
                        clipHeight = Qt.binding(function () {
                            return root.launcherVisible ? card.fullHeight : 0;
                        });
                    }

                    Behavior on clipHeight {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }

                    Item {
                        id: contentItem
                        width: parent.width
                        height: card.clipHeight
                        anchors.bottom: parent.bottom
                        clip: true

                        Rectangle {
                            anchors.fill: parent
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
                                        return "󰡨";
                                    if (contentItem.mode === "emoji")
                                        return "󰞅";
                                    return "";
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
                                    text: "Search apps…  ·  =calc  ·  :emoji  ·  ::nerdfont"
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
                                    const currentItem = stack.children[stack.currentIndex];
                                    if (currentItem && currentItem.handleUp)
                                        currentItem.handleUp();
                                }
                                Keys.onDownPressed: {
                                    const currentItem = stack.children[stack.currentIndex];
                                    if (currentItem && currentItem.handleDown)
                                        currentItem.handleDown();
                                }
                                Keys.onReturnPressed: {
                                    const currentItem = stack.children[stack.currentIndex];
                                    if (currentItem && currentItem.handleReturn)
                                        currentItem.handleReturn();
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

                        StackLayout {
                            id: stack
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: searchRow.top
                            anchors.bottomMargin: 8
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6

                            implicitHeight: currentItem ? currentItem.implicitHeight : 0

                            currentIndex: {
                                if (contentItem.mode === "calc")
                                    return 1;
                                if (contentItem.mode === "emoji")
                                    return 2;
                                if (contentItem.mode === "nerdfont")
                                    return 3;
                                return 0;
                            }

                            LauncherApps {
                                id: appsView
                                query: contentItem.mode === "apps" ? searchField.text.trim() : ""
                                onAction: root.launcherVisible = false
                            }
                            LauncherCalc {
                                id: calcView
                                expr: contentItem.mode === "calc" ? searchField.text.slice(1).trim() : ""
                                onAction: root.launcherVisible = false
                            }
                            LauncherEmoji {
                                id: emojiView
                                query: contentItem.mode === "emoji" ? searchField.text.slice(1).toLowerCase().trim() : ""
                                onAction: root.launcherVisible = false
                            }
                            LauncherNerdfont {
                                id: nerdfontView
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
🇷