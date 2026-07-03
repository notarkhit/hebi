pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Hebi.Blobs
import "modules/settings"
import "modules/sysinfo"
import "modules/media"
import "modules/calendar"
import "modules/launcher"
import "modules/bar"
import "services"

// Single full-screen Overlay window covering the entire screen (y=0).
// Panels live here as Items. A shared BlobGroup is used for all panel BlobRects,
// which are siblings positioned to track each panel's visual location.
// This enables blob merge when panels transition between each other.
PanelWindow {
    id: root

    readonly property int barHeight: 32

    // ── visibility state ──────────────────────────────────────────────────────
    property bool settingsVisible:  false
    property bool sysInfoVisible:   false
    property bool notifMgrVisible:  false
    property bool mediaVisible:     false
    property bool calendarVisible:  false
    property bool launcherVisible:  false

    readonly property bool anyPanelVisible: settingsVisible || sysInfoVisible ||
                                            notifMgrVisible || mediaVisible   ||
                                            calendarVisible || launcherVisible

    // Mutual exclusion: opening one closes others (launcher is independent)
    onSettingsVisibleChanged: if (settingsVisible)  { sysInfoVisible = false; notifMgrVisible = false; mediaVisible = false; calendarVisible = false }
    onSysInfoVisibleChanged:  if (sysInfoVisible)   { settingsVisible = false; notifMgrVisible = false; mediaVisible = false; calendarVisible = false }
    onNotifMgrVisibleChanged: if (notifMgrVisible)  { settingsVisible = false; sysInfoVisible = false; mediaVisible = false; calendarVisible = false }
    onMediaVisibleChanged:    if (mediaVisible)     { settingsVisible = false; sysInfoVisible = false; notifMgrVisible = false; calendarVisible = false }
    onCalendarVisibleChanged: if (calendarVisible)  { settingsVisible = false; sysInfoVisible = false; notifMgrVisible = false; mediaVisible = false }

    // ── IPC handlers ──────────────────────────────────────────────────────────
    IpcHandler {
        target: "settings"
        function toggle(): void { root.settingsVisible = !root.settingsVisible }
        function open(): void   { root.settingsVisible = true }
        function close(): void  { root.settingsVisible = false }
    }
    IpcHandler {
        target: "sysinfo"
        function toggle(): void { root.sysInfoVisible = !root.sysInfoVisible }
        function open(): void   { root.sysInfoVisible = true }
        function close(): void  { root.sysInfoVisible = false }
    }
    IpcHandler {
        target: "notifmanager"
        function toggle(): void { root.notifMgrVisible = !root.notifMgrVisible }
        function open(): void   { root.notifMgrVisible = true }
        function close(): void  { root.notifMgrVisible = false }
    }
    IpcHandler {
        target: "media"
        function toggle(): void { root.mediaVisible = !root.mediaVisible }
        function open(): void   { root.mediaVisible = true }
        function close(): void  { root.mediaVisible = false }
    }
    IpcHandler {
        target: "calendar"
        function toggle(): void { root.calendarVisible = !root.calendarVisible }
        function open(): void   { root.calendarVisible = true }
        function close(): void  { root.calendarVisible = false }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { root.launcherVisible = !root.launcherVisible }
    }

    // ── window ────────────────────────────────────────────────────────────────
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    margins.top: -root.barHeight

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: root.launcherVisible
                                     ? WlrKeyboardFocus.Exclusive
                                     : WlrKeyboardFocus.None

    mask: root.anyPanelVisible ? fullMask : emptyMask
    Region { id: emptyMask; x: 0; y: 0; width: root.width; height: root.barHeight }
    Region { id: fullMask; x: 0; y: 0; width: root.width; height: root.height }

    // ── shared blob layer ─────────────────────────────────────────────────────
    // All panel BlobRects live here as siblings, sharing one BlobGroup.
    // They track the visual position of their respective panel Items.
    // When two panels' blobs are close (e.g. while one closes and another opens),
    // the metaball SDF causes them to merge organically.
    Item {
        id: blobLayer
        anchors.fill: parent

        BlobGroup { id: blobGroup; color: Theme.surface }

        // Bar blob — always present, merges with panel blobs as they slide up to barHeight
        BlobRect {
            group: blobGroup
            x: 0; y: 0
            width: root.width; height: root.barHeight
            radius: 0
            stiffness: 600; damping: 40; deformScale: 0
        }

        // Settings blob — tracks settingsItem's visual bounds
        BlobRect {
            group: blobGroup
            x: root.width - settingsItem.width
            y: settingsItem.blobY - (200 * settingsItem.offsetScale)
            width: settingsItem.width
            height: settingsItem.height
            radius: 20; stiffness: 200; damping: 18
            deformScale: 0.006 * (1 - settingsItem.offsetScale)
            visible: settingsItem.offsetScale < 1
        }

        // SysInfo blob
        BlobRect {
            group: blobGroup
            x: root.width - sysInfoItem.width
            y: sysInfoItem.blobY - (200 * sysInfoItem.offsetScale)
            width: sysInfoItem.width
            height: sysInfoItem.height
            radius: 20; stiffness: 200; damping: 18
            deformScale: 0.006 * (1 - sysInfoItem.offsetScale)
            visible: sysInfoItem.offsetScale < 1
        }

        // NotifManager blob
        BlobRect {
            group: blobGroup
            x: root.width - notifMgrItem.width
            y: notifMgrItem.blobY - (200 * notifMgrItem.offsetScale)
            width: notifMgrItem.width
            height: notifMgrItem.height
            radius: 20; stiffness: 200; damping: 18
            deformScale: 0.006 * (1 - notifMgrItem.offsetScale)
            visible: notifMgrItem.offsetScale < 1
        }

        // Media blob — center-aligned
        BlobRect {
            group: blobGroup
            x: (root.width - mediaItem.width) / 2
            y: mediaItem.blobY - (200 * mediaItem.offsetScale)
            width: mediaItem.width
            height: mediaItem.height
            radius: 20; stiffness: 200; damping: 18
            deformScale: 0.006 * (1 - mediaItem.offsetScale)
            visible: mediaItem.offsetScale < 1
        }

        // Calendar blob — center-aligned
        BlobRect {
            group: blobGroup
            x: (root.width - calendarItem.width) / 2
            y: calendarItem.blobY - (200 * calendarItem.offsetScale)
            width: calendarItem.width
            height: calendarItem.height
            radius: 24; stiffness: 200; damping: 18
            deformScale: 0.006 * (1 - calendarItem.offsetScale)
            visible: calendarItem.offsetScale < 1
        }

        // Launcher blob — bottom-centered
        BlobRect {
            group: blobGroup
            x: (root.width - launcherItem.width) / 2
            y: launcherItem.blobY + (50 * launcherItem.offsetScale) // Push down off screen
            width: launcherItem.width
            height: launcherItem.height
            radius: 12; stiffness: 200; damping: 18
            deformScale: 0.006 * (1 - launcherItem.offsetScale)
            visible: launcherItem.offsetScale < 1
        }
    }

    // ── bar visual content ────────────────────────────────────────────────────
    BarItem {
        id: barItem
    }

    // ── panel content items ───────────────────────────────────────────────────
    // Panels are positioned at y=barHeight (just below the bar).
    // Their slide animation (offsetScale via Translate) slides them in/out from
    // behind the bar edge. blobY is exposed so the shared BlobRect above can track them.

    SettingsPanelItem {
        id: settingsItem
        panelVisible: root.settingsVisible
        anchors.right: parent.right
        y: root.barHeight
        onCloseRequested: root.settingsVisible = false
    }

    SysInfoPanelItem {
        id: sysInfoItem
        panelVisible: root.sysInfoVisible
        anchors.right: parent.right
        y: root.barHeight
        onCloseRequested: root.sysInfoVisible = false
    }

    NotifManagerPanelItem {
        id: notifMgrItem
        panelVisible: root.notifMgrVisible
        anchors.right: parent.right
        y: root.barHeight
        onCloseRequested: root.notifMgrVisible = false
    }

    MediaPanelItem {
        id: mediaItem
        panelVisible: root.mediaVisible
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.barHeight
        onCloseRequested: root.mediaVisible = false
    }

    CalendarPanelItem {
        id: calendarItem
        panelVisible: root.calendarVisible
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.barHeight
        onCloseRequested: root.calendarVisible = false
    }

    LauncherItem {
        id: launcherItem
        launcherVisible: root.launcherVisible
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        onCloseRequested: root.launcherVisible = false
    }

    // ── dismiss click ─────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            root.settingsVisible  = false
            root.sysInfoVisible   = false
            root.notifMgrVisible  = false
            root.mediaVisible     = false
            root.calendarVisible  = false
            root.launcherVisible  = false
        }
    }
}
