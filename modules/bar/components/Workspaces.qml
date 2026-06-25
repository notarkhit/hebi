pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "."

// Workspace indicator row
Row {
    id: root

    spacing: 4

    Repeater {
        model: 10
        WorkspaceButton {
            activeWsId: Hypr.activeWsId
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y > 0)
                Hypr.dispatch("workspace -1");
            else
                Hypr.dispatch("workspace +1");
        }
    }
}
