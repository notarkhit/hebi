//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma DefaultEnv QT_QPA_PLATFORMTHEME=gtk3

import "modules/bar"
import "modules/notifications"
import "modules/osd"
import "services"
import Quickshell

ShellRoot {
    settings.watchFiles: true

    property var _audioInit: AudioService.volume // Force singleton instantiation safely

    // ── per-screen bar (exclusiveZone + visual bar content) ───────────────────
    Bars {}

    // ── single full-screen overlay: all panels + shared blob group ────────────
    MainWindow {}

    // ── notification popups ───────────────────────────────────────────────────
    Notifications {
        position: "top-right"
    }

    // ── osd ───────────────────────────────────────────────────────────────────
    OsdPopup {}
}
