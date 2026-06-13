pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

// App launcher — toggle via: qs ipc -p ~/.config/hebi call launcher toggle
Scope {
    id: root

    // ── shared state ─────────────────────────────────────────────────────────
    property bool launcherVisible: false

    // ── IPC handler ───────────────────────────────────────────────────────────
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.launcherVisible = !root.launcherVisible
        }
    }

    // ── full-screen overlay (dim + card) ──────────────────────────────────────
    PanelWindow {
        id: overlay

        readonly property string font: "FiraMono Nerd Font"

        anchors.top:    true
        anchors.bottom: true
        anchors.left:   true
        anchors.right:  true

        color: "transparent"

        visible: root.launcherVisible
        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Focus + clear search when launcher opens
        onVisibleChanged: {
            if (visible) {
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }

        // ── dim background ────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)

            TapHandler {
                onTapped: root.launcherVisible = false
            }
        }

        // ── launcher card ─────────────────────────────────────────────────────
        Item {
            id: card

            width: 560
            implicitHeight: searchRow.implicitHeight + divider.height
                            + listView.implicitHeight + 28

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              parent.top
            anchors.topMargin:        root.launcherVisible ? 44 : 34

            opacity: root.launcherVisible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
            Behavior on anchors.topMargin {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            // Swallow taps so they don't reach the dim TapHandler
            TapHandler {}

            // Card background
            Rectangle {
                anchors.fill: parent
                radius: 14
                color:  Qt.rgba(0x1a/255, 0x1b/255, 0x26/255, 0.97)
                border.color: "#3b4261"
                border.width: 1
                layer.enabled: true
            }

            // ── search row ────────────────────────────────────────────────────
            RowLayout {
                id: searchRow

                anchors.top:   parent.top
                anchors.left:  parent.left
                anchors.right: parent.right
                anchors.margins: 14
                implicitHeight: 46
                spacing: 10

                Text {
                    text:           ""
                    color:          "#7aa2f7"
                    font.family:    overlay.font
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment:  Qt.AlignVCenter
                }

                TextInput {
                    id: searchField

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    color:          "#c0caf5"
                    font.family:    overlay.font
                    font.pixelSize: 14
                    clip:           true

                    Text {
                        anchors.fill: parent
                        text:         "Search apps…"
                        color:        "#565f89"
                        font.family:  overlay.font
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        visible: !searchField.text
                    }

                    Keys.onEscapePressed: {
                        root.launcherVisible = false
                        text = ""
                    }
                    Keys.onUpPressed:   listView.decrementCurrentIndex()
                    Keys.onDownPressed: listView.incrementCurrentIndex()
                    Keys.onReturnPressed: {
                        const item = listView.currentItem
                        if (item) {
                            item.launchApp()
                            root.launcherVisible = false
                            text = ""
                        }
                    }
                }

                Text {
                    text:           ""
                    color:          "#565f89"
                    font.family:    overlay.font
                    font.pixelSize: 14
                    visible:        searchField.text.length > 0
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    searchField.text = ""
                    }
                }
            }

            // ── divider ───────────────────────────────────────────────────────
            Rectangle {
                id: divider

                anchors.top:   searchRow.bottom
                anchors.left:  parent.left
                anchors.right: parent.right
                anchors.leftMargin:  14
                anchors.rightMargin: 14
                height: 1
                color:  "#3b4261"
            }

            // ── app list ──────────────────────────────────────────────────────
            ListView {
                id: listView

                anchors.top:         divider.bottom
                anchors.left:        parent.left
                anchors.right:       parent.right
                anchors.topMargin:    6
                anchors.bottomMargin: 6
                anchors.leftMargin:   6
                anchors.rightMargin:  6

                clip: true

                readonly property int itemH:    48
                readonly property int maxItems:  8
                implicitHeight: Math.min(count, maxItems) * itemH

                spacing:      2
                currentIndex: 0
                onCountChanged: currentIndex = 0

                model: {
                    const q = searchField.text.toLowerCase()
                    if (!q) return DesktopEntries.applications.values
                    return DesktopEntries.applications.values.filter(a =>
                        a.name.toLowerCase().includes(q)
                        || (a.genericName && a.genericName.toLowerCase().includes(q))
                        || (a.comment    && a.comment.toLowerCase().includes(q))
                    )
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: "#292e42"
                    }
                }

                highlight: Rectangle {
                    radius: 8
                    color:  Qt.rgba(0x7a/255, 0xa2/255, 0xf7/255, 0.12)
                    width:  listView.width
                }
                highlightFollowsCurrentItem: true
                highlightMoveVelocity: 1200

                delegate: Item {
                    id: delegateRoot

                    required property var modelData
                    required property int index

                    width:  listView.width
                    height: listView.itemH

                    function launchApp(): void {
                        if (delegateRoot.modelData)
                            Quickshell.execDetached({ command: delegateRoot.modelData.command })
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: hoverHandler.hovered ? "#7aa2f714" : "transparent"
                        Behavior on color { ColorAnimation { duration: 90 } }
                    }

                    RowLayout {
                        anchors.fill:        parent
                        anchors.leftMargin:  10
                        anchors.rightMargin: 10
                        spacing: 12

                        IconImage {
                            implicitSize: 28
                            source: delegateRoot.modelData
                                ? Quickshell.iconPath(delegateRoot.modelData.icon, "application-x-executable")
                                : ""
                            asynchronous: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                text:           delegateRoot.modelData?.name ?? ""
                                color:          listView.currentIndex === delegateRoot.index
                                                    ? "#7aa2f7" : "#c0caf5"
                                font.family:    overlay.font
                                font.pixelSize: 13
                                font.weight:    Font.Medium
                                elide:          Text.ElideRight
                                width:          parent.width
                                Behavior on color { ColorAnimation { duration: 110 } }
                            }

                            Text {
                                visible:        !!text
                                text:           delegateRoot.modelData?.comment
                                                ?? delegateRoot.modelData?.genericName
                                                ?? ""
                                color:          "#565f89"
                                font.family:    overlay.font
                                font.pixelSize: 10
                                elide:          Text.ElideRight
                                width:          parent.width
                            }
                        }

                        // terminal badge
                        Text {
                            visible:        delegateRoot.modelData?.runInTerminal ?? false
                            text:           ""
                            color:          "#9ece6a"
                            font.family:    overlay.font
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    HoverHandler {
                        id: hoverHandler
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (hovered) listView.currentIndex = delegateRoot.index
                        }
                    }

                    TapHandler {
                        onTapped: {
                            listView.currentIndex = delegateRoot.index
                            delegateRoot.launchApp()
                            root.launcherVisible = false
                            searchField.text = ""
                        }
                    }
                }
            }
        }
    }
}
