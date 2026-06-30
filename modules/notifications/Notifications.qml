pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../services"

// Notification popup stack — one instance per shell.
// Anchors to a corner and stacks popups toward the center.
//
// ┌─ position ────────────────────────────────────────────────────────┐
// │  "top-right"    │  "top-left"                                     │
// │  "bottom-right" │  "bottom-left"                                  │
// └────────────────────────────────────────────────────────────────── ┘
PanelWindow {
    id: root

    // ── configurable position ──────────────────────────────────────────────
    property string position: "top-right"

    readonly property bool fromBottom: position.startsWith("bottom")
    readonly property bool fromLeft:   position.endsWith("left")
    readonly property string slideDir: fromLeft ? "left" : "right"

    // Extra top offset injected by shell.qml when a panel is open
    property real topMargin: 0

    // ── layer shell anchoring ──────────────────────────────────────────────
    anchors.top:    !fromBottom
    anchors.bottom:  fromBottom
    anchors.left:    fromLeft
    anchors.right:  !fromLeft

    // Full screen height so the inner ListView can grow freely
    implicitWidth:  380 + 24   // popup width + side margins
    implicitHeight: (QsWindow.window as QsWindow)?.screen?.height ?? 1080

    color:   "transparent"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    // Only intercept clicks over the actual notifications list
    mask: Region {
        x: list.x
        y: list.y
        width: list.width
        height: list.height
    }

    // ── popup stack ───────────────────────────────────────────────────────
    ListView {
        id: list

        // Anchor to the active corner
        anchors.left:   root.fromLeft  ? parent.left   : undefined
        anchors.right:  root.fromLeft  ? undefined     : parent.right
        anchors.top:    root.fromBottom ? undefined    : parent.top
        anchors.bottom: root.fromBottom ? parent.bottom : undefined
        anchors.margins: 12
        anchors.topMargin: root.fromBottom ? 12 : 12 + root.topMargin

        Behavior on anchors.topMargin {
            NumberAnimation { duration: 320; easing.type: Easing.OutQuint }
        }

        width:   380
        height:  contentHeight   // shrink-wrap; never clips content

        // Newest popup appears closest to the anchored corner
        verticalLayoutDirection: root.fromBottom
                                    ? ListView.BottomToTop
                                    : ListView.TopToBottom

        spacing:     8
        interactive: false       // no manual scrolling; stack is always short

        model: ScriptModel {
            values: Notifs.popups
        }

        delegate: NotifPopup {
            slideFrom: root.slideDir
        }

        // ── transitions ────────────────────────────────────────────────────
        add: Transition {
            // Slide-in handled by NotifPopup itself; just fade the slot
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 10 }
        }

        remove: Transition {
            // Slide-out + fade (card x is already animated by swipe or dismiss)
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 220; easing.type: Easing.OutCubic }
        }

        displaced: Transition {
            // Other cards shift smoothly when one is removed
            NumberAnimation { property: "y"; duration: 280; easing.type: Easing.OutQuint }
        }
    }
}
