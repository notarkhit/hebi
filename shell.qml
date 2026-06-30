//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules/bar"
import "modules/launcher"
import "modules/notifications"
import "modules/osd"
import "modules/settings"
import "modules/sysinfo"
import "services"
import Quickshell

ShellRoot {
    settings.watchFiles: true

    property var _audioInit: AudioService.volume // Force singleton instantiation safely

    Bars {}
    Launcher {}

    // ── notification popups ─────────────────────────────────────────────────
    // position: "top-right" | "bottom-right" | "top-left" | "bottom-left"
    Notifications {
        position: "top-right"
    }

    // ── osd ──────────────────────────────────────────────────────────────────
    OsdPopup {}

    // ── settings panel ───────────────────────────────────────────────────────
    SettingsPanel {
        id: settingsPanel
        onPanelVisibleChanged: {
            if (panelVisible && sysInfoPanel.panelVisible)
                sysInfoPanel.panelVisible = false;
        }
    }

    // ── system info panel ─────────────────────────────────────────────────────
    SysInfoPanel {
        id: sysInfoPanel
        onPanelVisibleChanged: {
            if (panelVisible && settingsPanel.panelVisible)
                settingsPanel.panelVisible = false;
        }
    }
}
