//@ pragma Env QML2_IMPORT_PATH=/home/notarkhit/.config/hebi/plugin/build/qml
import QtQuick
import Quickshell
import Hebi.Config
import Hebi.Services

PanelWindow {
    color: "black"
    width: 200
    height: 100
    Text {
        text: "Hebi Loaded: " + ServiceRef.memory.percentage
        color: "white"
        anchors.centerIn: parent
    }
}
