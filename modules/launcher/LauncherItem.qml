pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../components"
import Quickshell.Widgets
import "../../services"

Item {
    id: root

    required property bool launcherVisible

    signal closeRequested

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int currentHeight: card.fullHeight

    // The launcher is anchors.bottom in MainWindow, so we need full height
    implicitWidth: 560
    implicitHeight: card.fullHeight

    onLauncherVisibleChanged: {
        if (launcherVisible) {
            searchField.text = "";
            searchField.forceActiveFocus();
        }
    }

    // env/shell offsetScale animation — slides below the screen bottom
    property real offsetScale: root.launcherVisible ? 0 : 1
    Behavior on offsetScale {
        Anim {}
    }
    // blobY: visual y for MainWindow's shared BlobRect (launcher slides from bottom)
    readonly property real blobY: parent ? parent.height - implicitHeight + (card.fullHeight + 5) * offsetScale : 0
    transform: Translate {
        y: (card.fullHeight + 5) * root.offsetScale
    }

    // ── card ──────────────────────────────────────────────────────────────────
    Item {
        id: card

        readonly property int fullHeight: stack.implicitHeight + 56

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 560
        height: fullHeight

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
                        return "";
                    if (contentItem.mode === "emoji")
                        return "";
                    return "󱓞";
                }
                color: "#7aa2f7"
                font.family: root.font
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            TextInput {
                id: searchField
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: "#c0caf5"
                font.family: root.font
                font.pixelSize: 14
                clip: true

                Text {
                    anchors.fill: parent
                    text: "Search apps..."
                    color: "#565f89"
                    font.family: root.font
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                    visible: !searchField.text
                }

                Keys.onEscapePressed: {
                    root.closeRequested();
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
                font.family: root.font
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

        Item {
            id: contentItem

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

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: searchRow.top
            anchors.bottomMargin: 0
            height: stack.implicitHeight

            Item {
                id: stack
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 6
                anchors.rightMargin: 6

                readonly property var activeView: {
                    if (contentItem.mode === "calc")
                        return calcView;
                    if (contentItem.mode === "emoji")
                        return emojiView;
                    if (contentItem.mode === "nerdfont")
                        return nerdfontView;
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
                    onAction: root.closeRequested()
                }
                LauncherCalc {
                    id: calcView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: contentItem.mode === "calc"
                    expr: contentItem.mode === "calc" ? searchField.text.slice(1).trim() : ""
                    onAction: root.closeRequested()
                }
                LauncherEmoji {
                    id: emojiView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: contentItem.mode === "emoji"
                    query: contentItem.mode === "emoji" ? searchField.text.slice(1).toLowerCase().trim() : ""
                    onAction: root.closeRequested()
                }
                LauncherNerdfont {
                    id: nerdfontView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: contentItem.mode === "nerdfont"
                    query: contentItem.mode === "nerdfont" ? searchField.text.slice(2).toLowerCase().trim() : ""
                    onAction: root.closeRequested()
                }
            }
        }
    }
}
