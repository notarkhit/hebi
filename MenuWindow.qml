pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Hebi.Blobs
import Hebi.Config
import "services"
import "modules/menu"

PanelWindow {
    id: window

    property bool menuVisible: false
    visible: menuVisible

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "menu"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    IpcHandler {
        target: "menu"
        function toggle(): void {
            window.menuVisible = !window.menuVisible;
        }
        function drun(): void {
            window.menuVisible = true;
            menuItem.openMode("drun");
        }
        function emoji(): void {
            window.menuVisible = true;
            menuItem.openMode("emoji");
        }
        function calc(): void {
            window.menuVisible = true;
            menuItem.openMode("calc");
        }
        function nerdfont(): void {
            window.menuVisible = true;
            menuItem.openMode("nerdfont");
        }
        function actions(): void {
            window.menuVisible = true;
            menuItem.openMode("actions");
        }
    }

    // Dismiss click
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            window.menuVisible = false;
        }
    }

    Item {
        anchors.fill: parent

        BlobGroup {
            id: blobGroup
            color: Theme.surface
            // Use same smoothing as MainWindow for consistency
        }

        BlobRect {
            group: blobGroup
            x: (window.width - menuItem.width) / 2
            y: menuItem.blobY
            width: menuItem.width
            height: menuItem.height
            radius: 12
            stiffness: 200
            damping: 18
            deformScale: (0.15 * Config.appearance.deformScale) / 10000
            visible: menuItem.offsetScale < 1
        }
    }

    MenuItem {
        id: menuItem
        menuVisible: window.menuVisible
        onCloseRequested: window.menuVisible = false

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
