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
        if (typeof actionsView !== "undefined")
            actionsView.activeMenu = "root";
    }

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int currentHeight: card.fullHeight

    // The launcher is anchors.bottom in MainWindow, so we need full height
    implicitWidth: {
        if (currentMode === "clipboard") return 860;
        if (currentMode === "actions" && typeof actionsView !== "undefined" && actionsView.activeMenu === "wallpaper") {
            return typeof wallpapersView !== "undefined" ? wallpapersView.implicitWidth : 1080;
        }
        return 560;
    }
    Behavior on implicitWidth {
        enabled: root.offsetScale === 0
        Anim {}
    }
    implicitHeight: card.fullHeight

    onMenuVisibleChanged: {
        if (menuVisible) {
            searchField.text = "";
            searchField.forceActiveFocus();
            if (typeof actionsView !== "undefined")
                actionsView.activeMenu = "root";
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

        readonly property bool isWallpaperPicker: root.currentMode === "actions" && typeof actionsView !== "undefined" && actionsView.activeMenu === "wallpaper"
        readonly property int fullHeight: contentItem.height + (isWallpaperPicker ? 0 : 56)

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: root.implicitWidth
        height: fullHeight

        RowLayout {
            id: searchRow
            visible: !card.isWallpaperPicker
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
                color: Theme.accent
                font.family: root.font
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            TextInput {
                id: searchField
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: Theme.text
                font.family: root.font
                font.pixelSize: 14
                clip: true

                Text {
                    anchors.fill: parent
                    text: "Search apps..."
                    color: Theme.subtext
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
                Keys.onLeftPressed: {
                    const v = stack.activeView;
                    if (v?.handleLeft)
                        v.handleLeft();
                }
                Keys.onRightPressed: {
                    const v = stack.activeView;
                    if (v?.handleRight)
                        v.handleRight();
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
                Keys.onTabPressed: {
                    const v = stack.activeView;
                    if (v?.handleTab)
                        v.handleTab();
                }
            }

            Text {
                text: ""
                color: Theme.subtext
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
            anchors.bottom: parent.bottom
            anchors.bottomMargin: card.isWallpaperPicker ? 0 : 56
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
                    if (contentItem.mode === "actions") {
                        if (actionsView.activeMenu === "wallpaper")
                            return wallpapersView;
                        return actionsView;
                    }
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
                    visible: contentItem.mode === "actions" && actionsView.activeMenu !== "wallpaper"
                    query: contentItem.mode === "actions" ? searchField.text.trim() : ""
                    onAction: root.closeRequested()
                    onAutocomplete: text => {
                        root.currentMode = "drun";
                        root.navigatedViaPrefix = false;
                        searchField.text = text;
                    }
                }
                MenuWallpapers {
                    id: wallpapersView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: contentItem.mode === "actions" && actionsView.activeMenu === "wallpaper"
                    onAction: root.closeRequested()
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
