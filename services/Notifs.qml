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

    // ── save path ─────────────────────────────────────────────────────────────
    readonly property string savePath: Qt.resolvedUrl(`file://${Quickshell.env("HOME")}/.local/state/hebi/notifs.json`)

    // ── helpers ───────────────────────────────────────────────────────────────
    function removePopup(notif: NotifData): void {
        root.popups = root.popups.filter(n => n !== notif);
    }

    // Debounced save — fires 1s after last change to avoid thrashing
    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: {
            const entries = root.popups.map(n => ({
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
            storage.setText(JSON.stringify(entries));
        }
    }

    function _triggerSave(): void {
        if (root.loaded) saveTimer.restart();
    }

    // ── IPC ───────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "notifs"

        function clear(): void {
            for (const n of root.popups.slice())
                n.dismiss();
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
                popup: !root.dnd
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
                const restored = [];
                for (const e of entries) {
                    const obj = notifComp.createObject(root, {
                        popup:         false,   // restored notifs don't re-popup
                        id:            e.id            ?? 0,
                        summary:       e.summary       ?? "",
                        body:          e.body          ?? "",
                        appName:       e.appName       ?? "",
                        appIcon:       e.appIcon       ?? "",
                        image:         e.image         ?? "",
                        urgency:       e.urgency       ?? 1,
                        expireTimeout: e.expireTimeout ?? 5000,
                        resident:      e.resident      ?? false,
                        time:          new Date(e.time ?? Date.now())
                    });
                    restored.push(obj);
                }
                // Append restored (already newest-first from previous save)
                root.popups = [...root.popups, ...restored];
            } catch (err) {
                // Corrupt or empty file — start fresh
                storage.setText("[]");
            }
            root.loaded = true;
        }

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                storage.setText("[]");
            root.loaded = true;
        }
    }

    // Watch popups changes and trigger a save
    onPopupsChanged: root._triggerSave()

    Component {
        id: notifComp
        NotifData {}
    }
}
