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
    property bool windowVisible: false

    onLauncherVisibleChanged: {
        if (launcherVisible) {
            windowVisible = true
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: root.windowVisible = false
    }

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

        visible: root.windowVisible
        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Focus + clear search when launcher opens
        onVisibleChanged: {
            if (visible) {
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }

        // ── background click-catcher (transparent) ────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: root.launcherVisible = false
            }
        }

        // ── launcher card ─────────────────────────────────────────────────────
        Item {
            id: card

            width: 560
            height: listView.implicitHeight + 56

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:     root.launcherVisible ? 12 : -(height + 20)

            opacity: root.launcherVisible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on anchors.bottomMargin {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
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

            // ── app list (above search, grows upward) ────────────────────────────
            ListView {
                id: listView

                anchors.left:         parent.left
                anchors.right:        parent.right
                anchors.bottom:       searchRow.top
                anchors.bottomMargin: 8
                anchors.leftMargin:   6
                anchors.rightMargin:  6

                clip: true

                layoutDirection: Qt.LeftToRight
                verticalLayoutDirection: ListView.BottomToTop

                readonly property int itemH:    48
                readonly property int maxItems:  8
                implicitHeight: Math.min(count, maxItems) * itemH

                spacing:      0
                currentIndex: 0
                onCountChanged: currentIndex = 0

                model: {
                    const q = searchField.text.toLowerCase().trim()
                    const all = DesktopEntries.applications.values
                    if (!q)
                        return [...all].sort((a, b) => a.name.localeCompare(b.name))
                    
                    return all.filter(a => {
                        const n = (a.name || "").toLowerCase()
                        const g = (a.genericName || "").toLowerCase()
                        const c = (a.comment || "").toLowerCase()
                        return n.includes(q) || g.includes(q) || c.includes(q)
                    }).sort((a, b) => {
                        const nA = (a.name || "").toLowerCase()
                        const nB = (b.name || "").toLowerCase()
                        
                        // 1. Exact match
                        const aExact = nA === q
                        const bExact = nB === q
                        if (aExact !== bExact) return aExact ? -1 : 1
                        
                        // 2. Starts with
                        const aStart = nA.startsWith(q)
                        const bStart = nB.startsWith(q)
                        if (aStart !== bStart) return aStart ? -1 : 1
                        
                        // 3. Name match over comment match
                        const aNameMatch = nA.includes(q)
                        const bNameMatch = nB.includes(q)
                        if (aNameMatch !== bNameMatch) return aNameMatch ? -1 : 1
                        
                        // 4. Alphabetical tie-breaker
                        return a.name.localeCompare(b.name)
                    })
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
                        color: hoverHandler.hovered ? Qt.rgba(0x7a/255, 0xa2/255, 0xf7/255, 0.12) : "transparent"
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
                                color:          (listView.currentIndex === delegateRoot.index || hoverHandler.hovered)
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

            // ── search row (at bottom) ────────────────────────────────────────
            RowLayout {
                id: searchRow

                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
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
        }
    }
}
