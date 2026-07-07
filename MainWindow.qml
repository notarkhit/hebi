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
import Hebi.Config

// Single full-screen Overlay window covering the entire screen (y=0).
// Panels live here as Items. A shared BlobGroup is used for all panel BlobRects,
// which are siblings positioned to track each panel's visual location.
// This enables blob merge when panels transition between each other.
PanelWindow {
    id: root

    readonly property int barHeight: 32

    // ── visibility state ──────────────────────────────────────────────────────
    property bool settingsVisible: false
    property bool sysInfoVisible: false
    property bool notifMgrVisible: false
    property bool mediaVisible: false
    property bool calendarVisible: false
    property bool launcherVisible: false

    readonly property bool anyPanelVisible: settingsVisible || sysInfoVisible || notifMgrVisible || mediaVisible || calendarVisible || launcherVisible

    // ── fullscreen detection ──────────────────────────────────────────────────
    readonly property var activeMonitor: Hypr.monitorFor(root.screen)
    readonly property bool hasFullscreenOnNormalWs: activeMonitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property bool hasFullscreen: {
        const specialWs = activeMonitor?.lastIpcObject?.specialWorkspace?.name;
        if (specialWs && specialWs.length > 0)
            return Hypr.workspaces.values.find(w => w.name === specialWs)?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        return hasFullscreenOnNormalWs;
    }

    // Mutual exclusion: opening one closes others (launcher is independent)
    onSettingsVisibleChanged: if (settingsVisible) {
        sysInfoVisible = false;
        notifMgrVisible = false;
        mediaVisible = false;
        calendarVisible = false;
    }
    onSysInfoVisibleChanged: if (sysInfoVisible) {
        settingsVisible = false;
        notifMgrVisible = false;
        mediaVisible = false;
        calendarVisible = false;
    }
    onNotifMgrVisibleChanged: if (notifMgrVisible) {
        settingsVisible = false;
        sysInfoVisible = false;
        mediaVisible = false;
        calendarVisible = false;
    }
    onMediaVisibleChanged: if (mediaVisible) {
        settingsVisible = false;
        sysInfoVisible = false;
        notifMgrVisible = false;
        calendarVisible = false;
    }
    onCalendarVisibleChanged: if (calendarVisible) {
        settingsVisible = false;
        sysInfoVisible = false;
        notifMgrVisible = false;
        mediaVisible = false;
    }

    // ── IPC handlers ──────────────────────────────────────────────────────────
    IpcHandler {
        target: "settings"
        function toggle(): void {
            root.settingsVisible = !root.settingsVisible;
        }
        function open(): void {
            root.settingsVisible = true;
        }
        function close(): void {
            root.settingsVisible = false;
        }
    }
    IpcHandler {
        target: "sysinfo"
        function toggle(): void {
            root.sysInfoVisible = !root.sysInfoVisible;
        }
        function open(): void {
            root.sysInfoVisible = true;
        }
        function close(): void {
            root.sysInfoVisible = false;
        }
    }
    IpcHandler {
        target: "notifmanager"
        function toggle(): void {
            root.notifMgrVisible = !root.notifMgrVisible;
        }
        function open(): void {
            root.notifMgrVisible = true;
        }
        function close(): void {
            root.notifMgrVisible = false;
        }
    }
    IpcHandler {
        target: "media"
        function toggle(): void {
            root.mediaVisible = !root.mediaVisible;
        }
        function open(): void {
            root.mediaVisible = true;
        }
        function close(): void {
            root.mediaVisible = false;
        }
    }
    IpcHandler {
        target: "calendar"
        function toggle(): void {
            root.calendarVisible = !root.calendarVisible;
        }
        function open(): void {
            root.calendarVisible = true;
        }
        function close(): void {
            root.calendarVisible = false;
        }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.launcherVisible = !root.launcherVisible;
        }
    }

    // ── window ────────────────────────────────────────────────────────────────
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    margins.top: -root.barHeight

    color: "transparent"

    WlrLayershell.layer: root.hasFullscreen ? WlrLayer.Bottom : WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: root.launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: root.anyPanelVisible ? fullMask : emptyMask
    Region {
        id: emptyMask
        x: 0
        y: 0
        width: root.width
        height: root.barHeight
    }
    Region {
        id: fullMask
        x: 0
        y: 0
        width: root.width
        height: root.height
    }

    // ── shared blob layer ─────────────────────────────────────────────────────
    // All panel BlobRects live here as siblings, sharing one BlobGroup.
    // They track the visual position of their respective panel Items.
    // When two panels' blobs are close (e.g. while one closes and another opens),
    // the metaball SDF causes them to merge organically.
    Item {
        id: blobLayer
        anchors.fill: parent

        BlobGroup {
            id: blobGroup
            color: Theme.surface
        }

        // Bar blob — always present, merges with panel blobs as they slide up to barHeight
        BlobRect {
            group: blobGroup
            x: 0
            y: 0
            width: root.width
            height: root.barHeight
            radius: 0
            stiffness: 600
            damping: 40
            deformScale: 0
        }

        // Settings blob — pinned at bar edge, grows down as panel opens
        BlobRect {
            group: blobGroup
            x: root.width - settingsItem.implicitWidth
            y: root.barHeight
            width: settingsItem.offsetScale < 1 ? settingsItem.implicitWidth : 0
            height: settingsItem.implicitHeight * (1 - settingsItem.offsetScale)
            radius: 20
            topLeftRadius: 0
            topRightRadius: 0
            stiffness: 200
            damping: 18
            deformScale: (0.15 * Config.appearance.deformScale) / 10000
            visible: settingsItem.offsetScale < 1
        }

        // SysInfo blob
        BlobRect {
            group: blobGroup
            x: root.width - sysInfoItem.implicitWidth
            y: root.barHeight
            width: sysInfoItem.offsetScale < 1 ? sysInfoItem.implicitWidth : 0
            height: sysInfoItem.implicitHeight * (1 - sysInfoItem.offsetScale)
            radius: 20
            topLeftRadius: 0
            topRightRadius: 0
            stiffness: 200
            damping: 18
            deformScale: (0.15 * Config.appearance.deformScale) / 10000
            visible: sysInfoItem.offsetScale < 1
        }

        // NotifManager blob
        BlobRect {
            group: blobGroup
            x: root.width - notifMgrItem.implicitWidth
            y: root.barHeight
            width: notifMgrItem.offsetScale < 1 ? notifMgrItem.implicitWidth : 0
            height: notifMgrItem.implicitHeight * (1 - notifMgrItem.offsetScale)
            radius: 20
            topLeftRadius: 0
            topRightRadius: 0
            stiffness: 200
            damping: 18
            deformScale: (0.15 * Config.appearance.deformScale) / 10000
            visible: notifMgrItem.offsetScale < 1
        }

        // Media blob
        BlobRect {
            group: blobGroup
            x: barItem.mediaX + (barItem.mediaWidth - mediaItem.implicitWidth) / 2
            y: root.barHeight
            width: mediaItem.offsetScale < 1 ? mediaItem.implicitWidth : 0
            height: mediaItem.implicitHeight * (1 - mediaItem.offsetScale)
            radius: 20
            topLeftRadius: 0
            topRightRadius: 0
            stiffness: 200
            damping: 18
            deformScale: (0.15 * Config.appearance.deformScale) / 10000
            visible: mediaItem.offsetScale < 1
        }

        // Calendar blob — center-aligned
        BlobRect {
            group: blobGroup
            x: (root.width - calendarItem.implicitWidth) / 2
            y: root.barHeight
            width: calendarItem.offsetScale < 1 ? calendarItem.implicitWidth : 0
            height: calendarItem.implicitHeight * (1 - calendarItem.offsetScale)
            radius: 24
            topLeftRadius: 0
            topRightRadius: 0
            stiffness: 200
            damping: 18
            deformScale: (0.15 * Config.appearance.deformScale) / 10000
            visible: calendarItem.offsetScale < 1
        }

        // Launcher blob — bottom-centered
        BlobRect {
            group: blobGroup
            x: (root.width - launcherItem.width) / 2
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

    // ── bar visual content ────────────────────────────────────────────────────
    BarItem {
        id: barItem
    }

    // ── panel content items ───────────────────────────────────────────────────
    // Each panel lives in a clip:true wrapper at y=barHeight.
    // The wrapper grows from height=0 to full panel height as the panel opens,
    // revealing content top-to-bottom — panels feel like extensions of the bar.

    Item {
        id: settingsWrapper
        clip: true
        anchors.right: parent.right
        y: root.barHeight
        width: settingsItem.implicitWidth
        height: settingsItem.implicitHeight * (1 - settingsItem.offsetScale)

        SettingsPanelItem {
            id: settingsItem
            panelVisible: root.settingsVisible
            width: parent.width
            onCloseRequested: root.settingsVisible = false
        }
    }

    Item {
        id: sysInfoWrapper
        clip: true
        anchors.right: parent.right
        y: root.barHeight
        width: sysInfoItem.implicitWidth
        height: sysInfoItem.implicitHeight * (1 - sysInfoItem.offsetScale)

        SysInfoPanelItem {
            id: sysInfoItem
            panelVisible: root.sysInfoVisible
            width: parent.width
            onCloseRequested: root.sysInfoVisible = false
        }
    }

    Item {
        id: notifMgrWrapper
        clip: true
        anchors.right: parent.right
        y: root.barHeight
        width: notifMgrItem.implicitWidth
        height: notifMgrItem.implicitHeight * (1 - notifMgrItem.offsetScale)

        NotifManagerPanelItem {
            id: notifMgrItem
            panelVisible: root.notifMgrVisible
            width: parent.width
            onCloseRequested: root.notifMgrVisible = false
        }
    }

    Item {
        id: mediaWrapper
        clip: true
        x: barItem.mediaX + (barItem.mediaWidth - mediaItem.implicitWidth) / 2
        y: root.barHeight
        width: mediaItem.implicitWidth
        height: mediaItem.implicitHeight * (1 - mediaItem.offsetScale)

        MediaPanelItem {
            id: mediaItem
            panelVisible: root.mediaVisible
            width: parent.width
            onCloseRequested: root.mediaVisible = false
        }
    }

    Item {
        id: calendarWrapper
        clip: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.barHeight
        width: calendarItem.implicitWidth
        height: calendarItem.implicitHeight * (1 - calendarItem.offsetScale)

        CalendarPanelItem {
            id: calendarItem
            panelVisible: root.calendarVisible
            width: parent.width
            onCloseRequested: root.calendarVisible = false
        }
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
            root.settingsVisible = false;
            root.sysInfoVisible = false;
            root.notifMgrVisible = false;
            root.mediaVisible = false;
            root.calendarVisible = false;
            root.launcherVisible = false;
        }
    }
}
