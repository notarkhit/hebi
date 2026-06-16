import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../services"

PanelWindow {
    id: root

    // Configuration Properties
    property string position: "bottom center"
    property int orientation: Qt.Horizontal

    color: "transparent"

    property bool initDone: false

    Timer {
        id: initDelayTimer
        interval: 1500
        running: true
        onTriggered: initDone = true
    }

    // Sizing: fixed pill size — no dynamic resize when switching
    implicitWidth:  orientation === Qt.Horizontal ? 300 : 80
    implicitHeight: orientation === Qt.Horizontal ? 80  : 300

    anchors {
        bottom: position.includes("bottom")
        top:    position.includes("top")
        left:   position.includes("left")
        right:  position.includes("right")
    }

    margins {
        bottom: position.includes("bottom") ? 60 : 0
        top:    position.includes("top")    ? 60 : 0
        left:   position.includes("left")   ? 60 : 0
        right:  position.includes("right")  ? 60 : 0
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    // ── state ─────────────────────────────────────────────────────────────
    property real currentVolume:     AudioService.volume
    property bool currentMuted:      AudioService.muted
    property real currentBrightness: BrightnessService.brightness

    // "volume" | "brightness" | ""
    property string activeOsd: ""
    property bool   osdVisible: false

    onCurrentVolumeChanged:     { if (initDone) { activeOsd = "volume";     osdVisible = true; hideTimer.restart() } }
    onCurrentMutedChanged:      { if (initDone) { activeOsd = "volume";     osdVisible = true; hideTimer.restart() } }
    onCurrentBrightnessChanged: { if (initDone) { activeOsd = "brightness"; osdVisible = true; hideTimer.restart() } }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: osdVisible = false
    }

    IpcHandler {
        target: "osd"
        function showBrightness(val: string) {
            let percent = parseFloat(val);
            if (!isNaN(percent)) BrightnessService.setBrightness(percent / 100);
            root.activeOsd = "brightness";
            root.osdVisible = true;
            hideTimer.restart();
        }
        function showVolume() {
            root.activeOsd = "volume";
            root.osdVisible = true;
            hideTimer.restart();
        }
    }

    mask: Region {
        x: pill.x; y: pill.y
        width: pill.width; height: pill.height
    }

    Item {
        anchors.fill: parent

        // ── pill ──────────────────────────────────────────────────────────
        Rectangle {
            id: pill
            anchors.centerIn: parent

            width:  root.implicitWidth
            height: root.implicitHeight

            color:  "#cc1a1b26"
            radius: Math.min(width, height) / 2

            // No border — clean pill shape
            opacity: root.osdVisible ? 1 : 0
            scale:   root.osdVisible ? 1 : 0.88

            Behavior on opacity {
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
            }

            // ── volume slider ──────────────────────────────────────────────
            FilledSlider {
                anchors.fill: parent
                anchors.margins: 12
                orientation: root.orientation
                visible: root.activeOsd === "volume"
                opacity: root.activeOsd === "volume" ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                value: root.currentVolume
                from: 0
                to: 150

                iconPath: {
                    if (root.currentMuted) return "file:///home/notarkhit/.icons/custom/volume/muted.svg";
                    let v = Math.min(150, Math.max(0, Math.round(root.currentVolume / 5) * 5));
                    return `file:///home/notarkhit/.icons/custom/volume/vol-${v}.svg`;
                }

                onMoved: {
                    AudioService.setVolume(value / 100);
                    hideTimer.restart();
                }
            }

            // ── brightness slider ──────────────────────────────────────────
            FilledSlider {
                anchors.fill: parent
                anchors.margins: 12
                orientation: root.orientation
                visible: root.activeOsd === "brightness"
                opacity: root.activeOsd === "brightness" ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                value: root.currentBrightness * 100
                from: 0
                to: 100

                iconPath: {
                    let b = Math.min(100, Math.max(0, Math.round((root.currentBrightness * 100) / 5) * 5));
                    return `file:///home/notarkhit/.icons/custom/brightness/br-${b}.svg`;
                }

                onMoved: {
                    BrightnessService.setBrightness(value / 100);
                    hideTimer.restart();
                }
            }
        }
    }
}
