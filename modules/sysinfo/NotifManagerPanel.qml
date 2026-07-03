pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Hebi.Blobs
import "../../services"

PanelWindow {
    id: root

    property bool panelVisible: false
    property bool windowVisible: false

    onPanelVisibleChanged: {
        Notifs.managerOpen = panelVisible
        if (panelVisible) { windowVisible = true; Notifs.clearPopups() }
        else closeTimer.restart()
    }

    IpcHandler {
        target: "notifmanager"
        function toggle(): void { root.panelVisible = !root.panelVisible }
        function open(): void   { root.panelVisible = true }
        function close(): void  { root.panelVisible = false }
    }

    Timer { id: closeTimer; interval: 520; onTriggered: root.windowVisible = false }

    anchors.right: true
    anchors.top: true
    anchors.left: false
    anchors.bottom: false

    implicitWidth: 420
    implicitHeight: 800

    color: "transparent"
    visible: root.windowVisible

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    mask: panelVisible ? activeRegion : emptyRegion
    Region { id: emptyRegion }
    Region { id: activeRegion; x: 0; y: 0; width: root.implicitWidth; height: wrapper.height }

    // ── animated wrapper ───────────────────────────────────────────────────────
    Item {
        id: wrapper
        anchors.top: parent.top; anchors.right: parent.right
        width: 412
        height: Math.min(600, col.implicitHeight + 64)

        property real offsetScale: root.panelVisible ? 0 : 1
        Behavior on offsetScale {
            NumberAnimation { duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1] }
        }
        anchors.topMargin: (-height - 5) * offsetScale
        opacity: 1 - offsetScale

        BlobGroup { id: bgGroup; color: Theme.surface }
        BlobRect { group: bgGroup; anchors.fill: parent; radius: 20; stiffness: 200; damping: 18; deformScale: 0.004 }

        ColumnLayout {
            id: col
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.topMargin: 20; anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.bottomMargin: 16
            spacing: 0

            RowLayout {
                Layout.fillWidth: true; Layout.bottomMargin: 10
                Text { text: "Notifications"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.weight: Font.DemiBold; color: "#c0caf5"; Layout.fillWidth: true }
                Rectangle {
                    visible: Notifs.history.length > 0
                    implicitWidth: clearText.implicitWidth + 12; implicitHeight: 20; radius: 4
                    color: clearHover.containsMouse ? "#22f7768e" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { id: clearText; anchors.centerIn: parent; text: "Clear All"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: clearHover.containsMouse ? "#f7768e" : "#565f89"; Behavior on color { ColorAnimation { duration: 150 } } }
                    MouseArea { id: clearHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearHistory() }
                }
            }

            ScrollView {
                Layout.fillWidth: true; Layout.preferredHeight: Math.min(500, list.contentHeight)
                visible: Notifs.history.length > 0; clip: true
                ListView {
                    id: list; width: parent.width; implicitHeight: contentHeight
                    spacing: 8; interactive: true; boundsBehavior: Flickable.StopAtBounds
                    model: ScriptModel { values: Notifs.history }
                    delegate: NotifManagerCard { width: ListView.view.width - 8; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }

            Item {
                visible: Notifs.history.length === 0; Layout.fillWidth: true; implicitHeight: 84
                Text { anchors.centerIn: parent; text: "No notifications"; color: "#565f89"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
            }

            Item { implicitHeight: 8 }
        }
    }

    MouseArea { anchors.fill: parent; z: -1; onClicked: root.panelVisible = false }
}
