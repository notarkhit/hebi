//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules/bar"
import "modules/launcher"
import Quickshell

ShellRoot {
    settings.watchFiles: true

    Bars {}
    Launcher {}
}
