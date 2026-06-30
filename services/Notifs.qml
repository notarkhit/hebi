pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Hebi notification server — replaces dunst.
// IPC target: "notifs"  →  qs ipc -p ~/.config/hebi call notifs <fn>
Singleton {
    id: root

    // Active popup list — only visible popups; reassigned triggers ListView update
    property var popups: []
    property bool dnd: false
    property bool loaded: false
    property bool managerOpen: false

    // ── save path ─────────────────────────────────────────────────────────────
    readonly property string savePath: Qt.resolvedUrl(`file://${Quickshell.env("HOME")}/.local/state/hebi/notifs.json`)

    // ── helpers ───────────────────────────────────────────────────────────────
    function removePopup(notif: NotifData): void {
        root.popups = root.popups.filter(n => n !== notif);
    }

    function removeHistoryItem(item): void {
        root.history = root.history.filter(h => {
            if (h.id !== 0 && item.id !== 0 && h.id === item.id) return false;
            if (h.time === item.time && h.appName === item.appName && h.summary === item.summary) return false;
            return true;
        });
        storage.setText(JSON.stringify(root.history));
    }

    function clearHistory(): void {
        root.history = [];
        storage.setText("[]");
    }

    function clearPopups(): void {
        for (const n of root.popups.slice())
            n.dismiss();
    }

    property var history: []

    function syncHistory(): void {
        const activeEntries = root.popups.map(n => ({
            id:            n.id,
            summary:       n.summary,
            body:          n.body,
            appName:       n.appName,
            appIcon:       n.appIcon,
            image:         n.image,
            urgency:       n.urgency,
            expireTimeout: n.expireTimeout,
            resident:      n.resident,
            time:          n.time.getTime()
        }));
        
        let newHistory = [...activeEntries];
        let seen = new Set();
        for (const e of activeEntries) {
            let sig = e.id != 0 ? `id:${e.id}` : `app:${e.appName}|sum:${e.summary}`;
            seen.add(sig);
        }
        
        for (const h of root.history) {
            let sig = h.id != 0 ? `id:${h.id}` : `app:${h.appName}|sum:${h.summary}`;
            if (!seen.has(sig)) {
                newHistory.push(h);
                seen.add(sig);
            }
        }
        
        newHistory.sort((a, b) => b.time - a.time);
        if (newHistory.length > 50) {
            newHistory = newHistory.slice(0, 50);
        }
        
        root.history = newHistory;
    }

    // Debounced save — fires 1s after last change to avoid thrashing
    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: {
            storage.setText(JSON.stringify(root.history));
        }
    }

    function _triggerSave(): void {
        if (root.loaded) saveTimer.restart();
    }

    // ── IPC ───────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "notifs"

        function clear(): void {
            root.clearPopups();
        }

        function toggleDnd(): void { root.dnd = !root.dnd; }
        function enableDnd(): void  { root.dnd = true;      }
        function disableDnd(): void { root.dnd = false;     }

        function isDndEnabled(): bool { return root.dnd; }
    }

    // ── DBus notification server ───────────────────────────────────────────────
    NotificationServer {
        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            // 1. DBus replaces_id: Quickshell reuses the same integer id,
            //    so find any existing popup whose id matches.
            for (const existing of root.popups) {
                if (existing.id != 0 && existing.id == notif.id) {
                    existing.updateFrom(notif);
                    root._triggerSave();
                    return;
                }
            }

            // 2. Dunst stack-tag (x-dunst-stack-tag hint)
            let stackTag = (notif.hints && notif.hints["x-dunst-stack-tag"]) ? notif.hints["x-dunst-stack-tag"] : "";
            if (stackTag !== "") {
                for (const existing of root.popups) {
                    let extTag = (existing.hints && existing.hints["x-dunst-stack-tag"]) ? existing.hints["x-dunst-stack-tag"] : "";
                    if (extTag === stackTag) {
                        existing.updateFrom(notif);
                        root._triggerSave();
                        return;
                    }
                }
            }

            // 3. Same app + same summary — dedup repeated identical notifications
            if (notif.appName !== "" && notif.summary !== "") {
                for (const existing of root.popups) {
                    if (existing.appName === notif.appName && existing.summary === notif.summary) {
                        existing.updateFrom(notif);
                        root._triggerSave();
                        return;
                    }
                }
            }

            // New notification — prepend so newest appears first
            const data = notifComp.createObject(root, {
                notification: notif,
                popup: !root.dnd && !root.managerOpen
            });
            root.popups = [data, ...root.popups];
            root._triggerSave();
        }
    }

    // ── persistent storage ────────────────────────────────────────────────────
    FileView {
        id: storage
        path: root.savePath
        printErrors: false

        onLoaded: {
            try {
                const entries = JSON.parse(text());
                root.history = Array.isArray(entries) ? entries : [];
            } catch (err) {
                // Corrupt or empty file — start fresh
                storage.setText("[]");
                root.history = [];
            }
            root.loaded = true;
        }

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                storage.setText("[]");
                root.history = [];
            }
            root.loaded = true;
        }
    }

    // Watch popups changes and trigger a save
    onPopupsChanged: {
        root.syncHistory();
        root._triggerSave();
    }

    Component {
        id: notifComp
        NotifData {}
    }
}
