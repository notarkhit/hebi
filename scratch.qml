import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    color: "black"
    width: 200
    height: 100
    IpcHandler {
        target: "osd"
        function test(val: string) {
            console.log("IPC RECEIVED:", val);
        }
    }
}
