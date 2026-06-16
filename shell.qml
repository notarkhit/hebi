//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules/bar"
import "modules/launcher"
import "modules/notifications"
import Quickshell

ShellRoot {
    settings.watchFiles: true

    Bars {}
    Launcher {}

    // ── notification popups ─────────────────────────────────────────────────
    // position: "top-right" | "bottom-right" | "top-left" | "bottom-left"
    Notifications {
        position: "top-right"
    }
}
