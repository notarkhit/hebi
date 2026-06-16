pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications

// Lightweight data wrapper that survives after the raw Notification object
// is cleaned up. Held alive by the lock/unlock mechanism during UI animations.
QtObject {
    id: notif

    // ── state ─────────────────────────────────────────────────────────────────
    property bool popup: true    // is the popup currently shown?
    property bool closed: false
    property var  locks: new Set()

    // ── notification data ──────────────────────────────────────────────────────
    property Notification notification: null
    property string id:            ""
    property string summary:       ""
    property string body:          ""
    property string appName:       ""
    property string appIcon:       ""
    property string image:         ""
    property int    urgency:       NotificationUrgency.Normal
    property real   expireTimeout: 5000
    property list<var> actions:    []
    property var    hints:         null

    // ── auto-expire ───────────────────────────────────────────────────────────
    readonly property Timer expireTimer: Timer {
        // Critical: never auto-expire (user must dismiss)
        interval: notif.urgency === NotificationUrgency.Critical
                    ? 0
                    : (notif.expireTimeout > 0 ? notif.expireTimeout : 5000)
        running: interval > 0 && notif.popup && !notif.closed
        onTriggered: notif.dismiss()
    }

    // ── sync live updates from the Notification object ────────────────────────
    readonly property Connections conn: Connections {
        target: notif.notification

        function onClosed(): void                { notif.dismiss() }
        function onSummaryChanged(): void        { notif.summary       = notif.notification.summary }
        function onBodyChanged(): void           { notif.body          = notif.notification.body }
        function onAppIconChanged(): void        { notif.appIcon       = notif.notification.appIcon }
        function onAppNameChanged(): void        { notif.appName       = notif.notification.appName }
        function onImageChanged(): void          { notif.image         = notif.notification.image }
        function onExpireTimeoutChanged(): void  { notif.expireTimeout = notif.notification.expireTimeout }
        function onUrgencyChanged(): void        { notif.urgency       = notif.notification.urgency }
        function onActionsChanged(): void        { notif.syncActions() }
    }

    // ── public API ────────────────────────────────────────────────────────────
    function pauseTimer(): void  { expireTimer.stop()  }
    function resumeTimer(): void { if (popup && !closed && expireTimer.interval > 0) expireTimer.start() }

    function lock(item): void {
        locks.add(item)
    }

    function unlock(item): void {
        locks.delete(item)
        if (closed) _doDestroy()
    }

    // Hides popup (triggers UI exit animation); actual destroy happens via unlock
    function dismiss(): void {
        if (closed) return
        closed = true
        popup  = false
        Notifs.removePopup(notif)
        notification?.dismiss()
        if (locks.size === 0) _doDestroy()
    }

    function syncActions(): void {
        actions = notification.actions.map(a => ({
            identifier: a.identifier,
            text:       a.text,
            invoke:     () => a.invoke()
        }))
    }

    function _doDestroy(): void {
        Qt.callLater(() => destroy())
    }

    // ── initialise from Notification on creation ──────────────────────────────
    Component.onCompleted: {
        if (!notification) return
        id            = notification.id
        summary       = notification.summary
        body          = notification.body
        appName       = notification.appName
        appIcon       = notification.appIcon
        image         = notification.image
        urgency       = notification.urgency
        expireTimeout = notification.expireTimeout
        hints         = notification.hints
        syncActions()
    }
}
