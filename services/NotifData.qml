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
    property var locks: new Set()

    // ── notification data ──────────────────────────────────────────────────────
    property Notification notification: null
    property int id: 0
    property string summary: ""
    property string body: ""
    property string appName: ""
    property string appIcon: ""
    property string image: ""
    property int urgency: NotificationUrgency.Normal
    property real expireTimeout: 5000
    property list<var> actions: []
    property var hints: null
    property bool resident: false
    property bool hasActionIcons: false

    // ── timestamp / elapsed time string ──────────────────────────────────────
    property date time: new Date()
    property string timeStr: "now"

    readonly property Timer timeStrTimer: Timer {
        running: !notif.closed
        repeat: true
        interval: 5000
        onTriggered: notif.updateTimeStr()
    }

    function updateTimeStr(): void {
        const diff = Date.now() - notif.time.getTime();
        const m = Math.floor(diff / 60000);
        if (m < 1) {
            notif.timeStr = "now";
            timeStrTimer.interval = 5000;
        } else {
            const h = Math.floor(m / 60);
            const d = Math.floor(h / 24);
            if (d > 0) {
                notif.timeStr = `${d}d`;
                timeStrTimer.interval = 3600000;
            } else if (h > 0) {
                notif.timeStr = `${h}h`;
                timeStrTimer.interval = 300000;
            } else {
                notif.timeStr = `${m}m`;
                timeStrTimer.interval = m < 10 ? 30000 : 60000;
            }
        }
    }

    // ── auto-expire ───────────────────────────────────────────────────────────
    readonly property Timer expireTimer: Timer {
        // Critical notifications and resident ones never auto-expire
        interval: (notif.urgency === NotificationUrgency.Critical || notif.resident) ? 0 : (notif.expireTimeout > 0 ? notif.expireTimeout : 5000)
        running: interval > 0 && notif.popup && !notif.closed
        onTriggered: notif.dismiss()
    }

    // ── sync live updates from the Notification object ────────────────────────
    readonly property Connections conn: Connections {
        target: notif.notification

        function onClosed(): void {
            notif.dismiss();
        }
        function onSummaryChanged(): void {
            notif.summary = notif.notification.summary;
        }
        function onBodyChanged(): void {
            notif.body = notif.notification.body;
        }
        function onAppIconChanged(): void {
            notif.appIcon = notif.notification.appIcon;
        }
        function onAppNameChanged(): void {
            notif.appName = notif.notification.appName;
        }
        function onImageChanged(): void {
            notif.image = notif.notification.image;
        }
        function onExpireTimeoutChanged(): void {
            notif.expireTimeout = notif.notification.expireTimeout;
        }
        function onUrgencyChanged(): void {
            notif.urgency = notif.notification.urgency;
        }
        function onResidentChanged(): void {
            notif.resident = notif.notification.resident;
        }
        function onHasActionIconsChanged(): void {
            notif.hasActionIcons = notif.notification.hasActionIcons;
        }
        function onHintsChanged(): void {
            notif.hints = notif.notification.hints;
        }
        function onActionsChanged(): void {
            notif.syncActions();
        }
    }

    // ── public API ────────────────────────────────────────────────────────────
    function pauseTimer(): void {
        expireTimer.stop();
    }
    function resumeTimer(): void {
        if (popup && !closed && expireTimer.interval > 0)
            expireTimer.start();
    }

    function lock(item): void {
        locks.add(item);
    }

    function unlock(item): void {
        locks.delete(item);
        if (closed)
            _doDestroy();
    }

    // Hides popup (triggers UI exit animation); actual destroy happens via unlock
    function dismiss(): void {
        if (closed)
            return;
        closed = true;
        popup = false;
        Notifs.removePopup(notif);
        notification?.dismiss();
        if (locks.size === 0)
            _doDestroy();
    }

    function syncActions(): void {
        actions = notification.actions.map(a => ({
                    identifier: a.identifier,
                    text: a.text,
                    invoke: () => a.invoke()
                }));
    }

    function _doDestroy(): void {
        Qt.callLater(() => destroy());
    }

    function updateFrom(newNotif: Notification): void {
        notification = newNotif;
        id = newNotif.id;
        summary = newNotif.summary;
        body = newNotif.body;
        appName = newNotif.appName;
        appIcon = newNotif.appIcon;
        image = newNotif.image;
        urgency = newNotif.urgency;
        expireTimeout = newNotif.expireTimeout;
        hints = newNotif.hints;
        resident = newNotif.resident;
        hasActionIcons = newNotif.hasActionIcons;
        time = new Date();
        timeStr = "now";
        timeStrTimer.interval = 5000;
        syncActions();

        if (expireTimer.running || (popup && !closed && expireTimer.interval > 0)) {
            expireTimer.restart();
        }
    }

    // ── initialise from Notification on creation ──────────────────────────────
    Component.onCompleted: {
        if (!notification)
            return;
        id = notification.id;
        summary = notification.summary;
        body = notification.body;
        appName = notification.appName;
        appIcon = notification.appIcon;
        image = notification.image;
        urgency = notification.urgency;
        expireTimeout = notification.expireTimeout;
        hints = notification.hints;
        resident = notification.resident;
        hasActionIcons = notification.hasActionIcons;
        syncActions();
    }
}
