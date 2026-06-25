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

    // ── helpers ───────────────────────────────────────────────────────────────
    function removePopup(notif: NotifData): void {
        root.popups = root.popups.filter(n => n !== notif);
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

            // 1. DBus replaces_id: the server assigns the same `notif.id` as
            //    what the client passed via -r, so we look for an existing popup
            //    whose *tracked* id matches. Quickshell guarantees that when
            //    replaces_id > 0 the server reuses that same integer as the new
            //    notification's id.
            for (const existing of root.popups) {
                if (existing.id != 0 && existing.id == notif.id) {
                    existing.updateFrom(notif);
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
                        return;
                    }
                }
            }

            // 3. Same app + same summary — dedup repeated identical notifications
            if (notif.appName !== "" && notif.summary !== "") {
                for (const existing of root.popups) {
                    if (existing.appName === notif.appName && existing.summary === notif.summary) {
                        existing.updateFrom(notif);
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
        }
    }

    Component {
        id: notifComp
        NotifData {}
    }
}
