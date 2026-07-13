pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Hebi.Blobs
import Hebi.Config
import "services"
import "modules/launcher"

PanelWindow {
    id: window

    property bool launcherVisible: false
    visible: launcherVisible

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "launcher"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            window.launcherVisible = !window.launcherVisible;
        }
    }

    // Dismiss click
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            window.launcherVisible = false;
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
            x: (window.width - launcherItem.width) / 2
            y: launcherItem.blobY
            width: launcherItem.width
            height: launcherItem.height
            radius: 12
            stiffness: 200
            damping: 18
            deformScale: (0.15 * Config.appearance.deformScale) / 10000
            visible: launcherItem.offsetScale < 1
        }
    }

    LauncherItem {
        id: launcherItem
        launcherVisible: window.launcherVisible
        onCloseRequested: window.launcherVisible = false

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
