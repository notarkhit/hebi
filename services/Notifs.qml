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
        root.popups = root.popups.filter(n => n !== notif)
    }

    // ── IPC ───────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "notifs"

        function clear(): void {
            for (const n of root.popups.slice())
                n.dismiss()
        }

        function toggleDnd(): void { root.dnd = !root.dnd }
        function enableDnd(): void  { root.dnd = true       }
        function disableDnd(): void { root.dnd = false      }

        function isDndEnabled(): bool { return root.dnd }
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
            notif.tracked = true

            // Deduplicate spammy notifications (like Volume/Brightness sliders in scripts)
            // Update them inline to avoid ListView add/remove animations
            let isSpammy = (notif.appName === "Volume" || notif.appName === "Brightness");
            let isDefaultApp = (notif.appName === "dunstify" || notif.appName === "notify-send");

            if (isSpammy || isDefaultApp) {
                for (const existing of root.popups) {
                    if (existing.appName === notif.appName) {
                        // For default apps, ensure the summary prefixes match before replacing
                        if (isDefaultApp && !existing.summary.startsWith((notif.summary || "").split(":")[0])) {
                            continue;
                        }
                        
                        existing.updateFrom(notif);
                        notif.tracked = true;
                        return; // Successfully replaced inline, do not append a new one!
                    }
                }
            }

            const data = notifComp.createObject(root, {
                notification: notif,
                popup: !root.dnd
            })
            // Prepend so newest appears first (list is reversed per position)
            root.popups = [data, ...root.popups]
        }
    }

    Component {
        id: notifComp
        NotifData {}
    }
}
