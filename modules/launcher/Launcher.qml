pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../components"
import Quickshell.Widgets
import Quickshell.Wayland
import "../../services"

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
        function openMode(text: string): void {
            root.launcherVisible = true;
            searchField.text = text;
        }
    }

    PanelWindow {
        id: overlay

        readonly property string font: "JetBrainsMono Nerd Font"

        // Only anchor to bottom — window is content-sized, like env/shell
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        anchors.top: false

        implicitWidth: 560
        implicitHeight: card.fullHeight

        color: "transparent"
        visible: root.windowVisible

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.exclusiveZone: 0

        mask: root.launcherVisible ? activeRegion : emptyRegion
        Region {
            id: emptyRegion
        }
        Region {
            id: activeRegion
            x: (overlay.width - 560) / 2
            y: 0
            width: 560
            height: card.fullHeight
        }

        Connections {
            target: root
            function onLauncherVisibleChanged() {
                if (!root.launcherVisible)
                    closeTimer.restart();
            }
        }
        Timer {
            id: closeTimer
            interval: 520
            onTriggered: root.windowVisible = false
        }

        onVisibleChanged: {
            if (visible) {
                searchField.text = "";
                searchField.forceActiveFocus();
            }
        }

        // Full-screen dismiss area behind the card
        MouseArea {
            anchors.fill: parent
            onClicked: root.launcherVisible = false
        }

        // ── card (animation lives here, not on PanelWindow) ─────────────────────
        Item {
            id: card

            readonly property int fullHeight: stack.implicitHeight + 56

            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - fullHeight
            width: 560
            height: fullHeight

            // env/shell offsetScale animation — slides below the screen edge
            property real offsetScale: root.launcherVisible ? 0 : 1
            Behavior on offsetScale {
                Anim {}
            }
            transform: Translate {
                y: (card.fullHeight + 5) * card.offsetScale
            }
            opacity: 1 - offsetScale

            Item {
                id: contentItem
                anchors.fill: parent
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -12
                    color: Theme.surface
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
                        text: contentItem.mode === "calc" ? "󰃬" :
                              contentItem.mode === "nerdfont" ? "" :
                              contentItem.mode === "emoji" ? "" :
                              contentItem.mode === "clipboard" ? "󰅌" : "󱓞"
                        color: "#7aa2f7"
                        font.family: overlay.font
                        font.pixelSize: 16
                        verticalAlignment: Text.AlignVCenter
                        Layout.alignment: Qt.AlignVCenter
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
                            const v = stack.activeView;
                            if (v?.handleUp)
                                v.handleUp();
                        }
                        Keys.onDownPressed: {
                            const v = stack.activeView;
                            if (v?.handleDown)
                                v.handleDown();
                        }
                        Keys.onReturnPressed: {
                            const v = stack.activeView;
                            if (v?.handleReturn)
                                v.handleReturn();
                        }
                    }

                    Text {
                        text: ""
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
                    if (t.startsWith("@"))
                        return "clipboard";
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
                        if (contentItem.mode === "calc")
                            return calcView;
                        if (contentItem.mode === "emoji")
                            return emojiView;
                        if (contentItem.mode === "nerdfont")
                            return nerdfontView;
                        if (contentItem.mode === "clipboard")
                            return clipboardView;
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
                    LauncherClipboard {
                        id: clipboardView
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        visible: contentItem.mode === "clipboard"
                        query: contentItem.mode === "clipboard" ? searchField.text.slice(1).toLowerCase().trim() : ""
                        onAction: root.launcherVisible = false
                    }
                }
            }
        }
    }
}
