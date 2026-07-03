pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

// Dummy transparent window to reserve 32px exclusive zone.
// The actual visual bar is rendered inside MainWindow to share the blob layer.
PanelWindow {
    id: root

    required property ShellScreen screen

    screen: root.screen
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 1
    color: "transparent"

    // Ignore all inputs so clicks pass through to MainWindow below it
    mask: Region {}

    WlrLayershell.exclusiveZone: 32
    WlrLayershell.layer: WlrLayer.Top
}
