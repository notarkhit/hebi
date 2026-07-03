pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "modules/settings"
import "modules/sysinfo"
import "modules/media"
import "modules/calendar"
import "modules/launcher"
import "services"

// Single full-screen Overlay window.
// All panels live here as Items sharing one BlobGroup with the bar blob.
// This enables the "bulge from bar" merge effect.
PanelWindow {
    id: root

    // ── visibility state ──────────────────────────────────────────────────────
    property bool settingsVisible:    false
    property bool sysInfoVisible:     false
    property bool notifMgrVisible:    false
    property bool mediaVisible:       false
    property bool calendarVisible:    false
    property bool launcherVisible:    false

    readonly property bool anyPanelVisible: settingsVisible || sysInfoVisible ||
                                            notifMgrVisible || mediaVisible   ||
                                            calendarVisible || launcherVisible

    // Mutual exclusion: opening one closes others (except launcher is independent)
    onSettingsVisibleChanged:  if (settingsVisible)  { sysInfoVisible = false; notifMgrVisible = false; mediaVisible = false; calendarVisible = false }
    onSysInfoVisibleChanged:   if (sysInfoVisible)   { settingsVisible = false; notifMgrVisible = false; mediaVisible = false; calendarVisible = false }
    onNotifMgrVisibleChanged:  if (notifMgrVisible)  { settingsVisible = false; sysInfoVisible = false; mediaVisible = false; calendarVisible = false }
    onMediaVisibleChanged:     if (mediaVisible)     { settingsVisible = false; sysInfoVisible = false; notifMgrVisible = false; calendarVisible = false }
    onCalendarVisibleChanged:  if (calendarVisible)  { settingsVisible = false; sysInfoVisible = false; notifMgrVisible = false; mediaVisible = false }

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

    // ── window config ─────────────────────────────────────────────────────────
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: root.launcherVisible
                                     ? WlrKeyboardFocus.Exclusive
                                     : WlrKeyboardFocus.None

    // When any panel is open, allow input everywhere (dismiss MouseArea + panel items handle it).
    // When nothing is open, block all input so the shell doesn't steal clicks.
    mask: root.anyPanelVisible ? fullMask : emptyMask
    Region { id: emptyMask }
    Region { id: fullMask; x: 0; y: 0; width: root.width; height: root.height }

    // ── panels ────────────────────────────────────────────────────────────────
    SettingsPanelItem {
        id: settingsItem
        panelVisible: root.settingsVisible
        anchors.right: parent.right
        y: 0
        onCloseRequested: root.settingsVisible = false
    }

    SysInfoPanelItem {
        id: sysInfoItem
        panelVisible: root.sysInfoVisible
        anchors.right: parent.right
        y: 0
        onCloseRequested: root.sysInfoVisible = false
    }

    NotifManagerPanelItem {
        id: notifMgrItem
        panelVisible: root.notifMgrVisible
        anchors.right: parent.right
        y: 0
        onCloseRequested: root.notifMgrVisible = false
    }

    MediaPanelItem {
        id: mediaItem
        panelVisible: root.mediaVisible
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        onCloseRequested: root.mediaVisible = false
    }

    CalendarPanelItem {
        id: calendarItem
        panelVisible: root.calendarVisible
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        onCloseRequested: root.calendarVisible = false
    }

    LauncherItem {
        id: launcherItem
        launcherVisible: root.launcherVisible
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        onCloseRequested: root.launcherVisible = false
    }

    // ── dismiss click (behind all panels) ─────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            root.settingsVisible = false
            root.sysInfoVisible  = false
            root.notifMgrVisible = false
            root.mediaVisible    = false
            root.calendarVisible = false
            root.launcherVisible = false
        }
    }
}
