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

    required property bool menuVisible

    signal closeRequested

    property string currentMode: "drun"
    property bool navigatedViaPrefix: false

    function openMode(m) {
        currentMode = m;
        navigatedViaPrefix = false;
        searchField.text = "";
        searchField.forceActiveFocus();
    }

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int currentHeight: card.fullHeight

    // The launcher is anchors.bottom in MainWindow, so we need full height
    implicitWidth: currentMode === "clipboard" ? 860 : 560
    Behavior on implicitWidth {
        enabled: root.offsetScale === 0
        Anim {}
    }
    implicitHeight: card.fullHeight

    onMenuVisibleChanged: {
        if (menuVisible) {
            searchField.text = "";
            searchField.forceActiveFocus();
        }
    }

    // env/shell offsetScale animation — slides below the screen bottom
    property real offsetScale: root.menuVisible ? 0 : 1
    Behavior on offsetScale {
        Anim {}
    }
    onOffsetScaleChanged: {
        if (offsetScale === 1) {
            currentMode = "drun";
            navigatedViaPrefix = false;
        }
    }
    // blobY: visual y for MainWindow's shared BlobRect (launcher slides from bottom)
    readonly property real blobY: parent ? parent.height - implicitHeight + (card.fullHeight + 5) * offsetScale : 0
    transform: Translate {
        y: (card.fullHeight + 5) * root.offsetScale
    }

    // ── card ──────────────────────────────────────────────────────────────────
    Item {
        id: card

        readonly property int fullHeight: contentItem.height + 56

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: root.implicitWidth
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
                        return "";
                    if (contentItem.mode === "emoji")
                        return "";
                    if (contentItem.mode === "actions")
                        return "";
                    if (contentItem.mode === "clipboard")
                        return "󱘢";
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

                onTextChanged: {
                    if (root.currentMode === "drun") {
                        if (text.startsWith("=")) {
                            root.currentMode = "calc";
                            root.navigatedViaPrefix = true;
                            text = text.substring(1);
                        } else if (text.startsWith("::")) {
                            root.currentMode = "nerdfont";
                            root.navigatedViaPrefix = true;
                            text = text.substring(2);
                        } else if (text.startsWith(":")) {
                            root.currentMode = "emoji";
                            root.navigatedViaPrefix = true;
                            text = text.substring(1);
                        } else if (text.startsWith(">")) {
                            root.currentMode = "actions";
                            root.navigatedViaPrefix = true;
                            text = text.substring(1);
                        } else if (text.startsWith("@")) {
                            root.currentMode = "clipboard";
                            root.navigatedViaPrefix = true;
                            text = text.substring(1);
                        }
                    } else if (root.currentMode === "emoji" && text.startsWith(":")) {
                        root.currentMode = "nerdfont";
                        root.navigatedViaPrefix = true;
                        text = text.substring(1);
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Backspace && text.length === 0 && root.currentMode !== "drun" && root.navigatedViaPrefix) {
                        root.currentMode = "drun";
                        root.navigatedViaPrefix = false;
                        event.accepted = true;
                    }
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
                Keys.onDeletePressed: {
                    const v = stack.activeView;
                    if (v?.handleDelete)
                        v.handleDelete();
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

            readonly property string mode: root.currentMode

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: searchRow.top
            anchors.bottomMargin: 0
            height: stack.implicitHeight
            Behavior on height {
                enabled: root.offsetScale === 0
                Anim {}
            }

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
                    if (contentItem.mode === "actions")
                        return actionsView;
                    if (contentItem.mode === "clipboard")
                        return clipboardView;
                    return drunView;
                }
                implicitHeight: activeView ? activeView.implicitHeight : 0

                MenuDrun {
                    id: drunView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: contentItem.mode === "drun"
                    query: contentItem.mode === "drun" ? searchField.text.trim() : ""
                    onAction: root.closeRequested()
                }
                MenuCalc {
                    id: calcView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: contentItem.mode === "calc"
                    expr: contentItem.mode === "calc" ? searchField.text.trim() : ""
                    onAction: root.closeRequested()
                }
                MenuEmoji {
                    id: emojiView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: contentItem.mode === "emoji"
                    query: contentItem.mode === "emoji" ? searchField.text.toLowerCase().trim() : ""
                    onAction: root.closeRequested()
                }
                MenuNerdfont {
                    id: nerdfontView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: contentItem.mode === "nerdfont"
                    query: contentItem.mode === "nerdfont" ? searchField.text.toLowerCase().trim() : ""
                    onAction: root.closeRequested()
                }
                MenuActions {
                    id: actionsView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: contentItem.mode === "actions"
                    query: contentItem.mode === "actions" ? searchField.text.trim() : ""
                    onAction: root.closeRequested()
                    onAutocomplete: text => {
                        root.currentMode = "drun";
                        root.navigatedViaPrefix = false;
                        searchField.text = text;
                    }
                }
                MenuClipboard {
                    id: clipboardView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: contentItem.mode === "clipboard"
                    query: contentItem.mode === "clipboard" ? searchField.text.trim() : ""
                    onAction: root.closeRequested()
                }
            }
        }
    }
}
