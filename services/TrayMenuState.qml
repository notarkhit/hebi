pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// Singleton that tracks which tray item's menu should be open, and its X position.
// Tray.qml writes here; MainWindow.qml reads here to render the overlay.
Singleton {
    property bool    visible:    false
    property var     menuHandle: null  // QsMenuHandle from the clicked tray item
    property real    menuX:      0     // X position in MainWindow coords (to align column)

    function open(handle, x) {
        menuHandle = handle
        menuX      = x
        visible    = true
    }

    function close() {
        visible    = false
        menuHandle = null
    }
}
