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

    property bool launcherVisible: false
    property bool windowVisible: false

    onLauncherVisibleChanged: {
        if (launcherVisible) {
            windowVisible = true
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.launcherVisible = !root.launcherVisible
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
                        if (!root.launcherVisible) {
                            closeTimer.restart();
                        }
                    }
                }

                Timer {
                    id: closeTimer
                    interval: 280
                    onTriggered: root.windowVisible = false
                }

        readonly property string font: "FiraMono Nerd Font"

        anchors.top:    true
        anchors.bottom: true
        anchors.left:   true
        anchors.right:  true

        color: "transparent"

        visible: root.windowVisible
        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: {
            if (visible) {
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            onClicked: root.launcherVisible = false
        }

        // ── launcher card wrapper ────────────────────────────────────────────
        // The card sits at the bottom. clipHeight animates 0 → fullHeight,
        // revealing content upward like a drawer.
        Item {
            id: card

            width: 560
            readonly property int fullHeight: listView.implicitHeight + 56
            height: fullHeight

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:     12

            // Visible slice grows from the bottom upward
            property real clipHeight: 0

            Component.onCompleted: {
                clipHeight = Qt.binding(function() { return root.launcherVisible ? card.fullHeight : 0 })
            }

            Behavior on clipHeight {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutQuint
                }
            }

            // Inner clip container — only shows the bottom clipHeight pixels
            Item {
                id: clipMask
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.bottom: parent.bottom
                height: card.clipHeight
                clip: true

                // Swallow clicks so they don't reach the close MouseArea
                MouseArea { anchors.fill: parent }

                // Card background — positioned at the bottom of the full-height space
                Rectangle {
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    anchors.bottom: parent.bottom
                    height: card.fullHeight
                    radius: 14
                    color:  Qt.rgba(0x1a/255, 0x1b/255, 0x26/255, 0.97)
                    border.color: "#3b4261"
                    border.width: 1
                    layer.enabled: true
                }

                // ── search row — pinned to the bottom of the visible area ────
                RowLayout {
                    id: searchRow

                    anchors.bottom:  parent.bottom
                    anchors.left:    parent.left
                    anchors.right:   parent.right
                    anchors.margins: 14
                    implicitHeight:  46
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

                        Keys.onEscapePressed: { root.launcherVisible = false; text = "" }
                        // BottomToTop layout: index 0 is at the bottom (best match).
                        // Visually UP means going to higher indices; DOWN to lower.
                        Keys.onUpPressed: {
                            if (listView.count === 0) return
                            if (listView.currentIndex >= listView.count - 1)
                                listView.currentIndex = 0
                            else
                                listView.incrementCurrentIndex()
                        }
                        Keys.onDownPressed: {
                            if (listView.count === 0) return
                            if (listView.currentIndex <= 0)
                                listView.currentIndex = listView.count - 1
                            else
                                listView.decrementCurrentIndex()
                        }
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

                // ── app list — sits above the search row ─────────────────────
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

                    // Fuzzy scorer: returns a score >= 0 if the query matches, or -1 if not.
                    // Higher score = better match. Priorities:
                    //  1000  exact name match
                    //   900  name starts with query
                    //   800  name contains query as substring
                    //   750  word-initials start with query  (vmm → Virtual Machine Manager)
                    //   700  word-initials contain query
                    //   600  sequential fuzzy match in name  (zb → Zen Browser)
                    //   500  substring match in genericName or comment
                    //   400  fuzzy match in genericName
                    function fuzzyScore(app, query) {
                        const q = query.toLowerCase()
                        const name = (app.name || "").toLowerCase()
                        const generic = (app.genericName || "").toLowerCase()
                        const comment = (app.comment || "").toLowerCase()

                        if (name === q) return 1000
                        if (name.startsWith(q)) return 900
                        if (name.includes(q)) return 800

                        // Word-initials match
                        const initials = name.split(/[\s\-_]+/).map(w => w[0] || "").join("")
                        if (initials.startsWith(q)) return 750
                        if (initials.includes(q)) return 700

                        // Sequential fuzzy in name: every char of q must appear in order
                        let qi = 0
                        for (let i = 0; i < name.length && qi < q.length; i++)
                            if (name[i] === q[qi]) qi++
                        if (qi === q.length) return 600 - Math.min(name.length - q.length, 99)

                        // Substring in genericName / comment
                        if (generic.includes(q) || comment.includes(q)) return 500

                        // Sequential fuzzy across full string (name + generic)
                        const combined = name + " " + generic
                        let qi2 = 0
                        for (let i = 0; i < combined.length && qi2 < q.length; i++)
                            if (combined[i] === q[qi2]) qi2++
                        if (qi2 === q.length) return 400

                        return -1
                    }

                    model: {
                        const q = searchField.text.trim()
                        const all = DesktopEntries.applications.values
                        if (!q)
                            return [...all].sort((a, b) => a.name.localeCompare(b.name))

                        return all
                            .map(a => ({ app: a, score: fuzzyScore(a, q) }))
                            .filter(x => x.score >= 0)
                            .sort((x, y) => y.score !== x.score
                                ? y.score - x.score
                                : x.app.name.localeCompare(y.app.name))
                            .map(x => x.app)
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
                    highlightMoveDuration: 80
                    highlightResizeDuration: 0

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 80 }
                    }
                    displaced: Transition {
                        NumberAnimation { property: "y"; duration: 120; easing.type: Easing.OutCubic }
                    }

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
                            color: hoverHandler.hovered
                                   ? Qt.rgba(0x7a/255, 0xa2/255, 0xf7/255, 0.12)
                                   : "transparent"
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
            }
        }
            }
        }
    }
}
