import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../services"

Scope {
    id: root

    // Configuration Properties
    property string position: "bottom center"
    property int orientation: Qt.Horizontal

    property bool initDone: false

    Timer {
        id: initDelayTimer
        interval: 1500
        running: true
        onTriggered: initDone = true
    }

    // ── state ─────────────────────────────────────────────────────────────
    property real currentVolume:     AudioService.volume
    property bool currentMuted:      AudioService.muted
    property real currentBrightness: BrightnessService.brightness

    // "volume" | "brightness" | ""
    property string activeOsd: ""
    property bool   osdVisible: false
    property bool   windowActive: false

    onCurrentVolumeChanged:     { if (initDone) { activeOsd = "volume";     osdVisible = true; hideTimer.restart() } }
    onCurrentMutedChanged:      { if (initDone) { activeOsd = "volume";     osdVisible = true; hideTimer.restart() } }
    onCurrentBrightnessChanged: { if (initDone) { activeOsd = "brightness"; osdVisible = true; hideTimer.restart() } }

    onOsdVisibleChanged: {
        if (osdVisible) windowActive = true;
    }

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

    Loader {
        active: root.windowActive
        sourceComponent: Component {
            PanelWindow {
                id: windowRoot

                color: "transparent"

                // Sizing: fixed pill size — no dynamic resize when switching
                implicitWidth:  root.orientation === Qt.Horizontal ? 260 : 52
                implicitHeight: root.orientation === Qt.Horizontal ? 52  : 260

                anchors {
                    bottom: root.position.includes("bottom")
                    top:    root.position.includes("top")
                    left:   root.position.includes("left")
                    right:  root.position.includes("right")
                }

                margins {
                    bottom: root.position.includes("bottom") ? 60 : 0
                    top:    root.position.includes("top")    ? 60 : 0
                    left:   root.position.includes("left")   ? 60 : 0
                    right:  root.position.includes("right")  ? 60 : 0
                }

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.exclusiveZone: 0

                mask: Region {
                    x: pill.x; y: pill.y
                    width: pill.width; height: pill.height
                }

                Connections {
                    target: pill
                    function onOpacityChanged() {
                        if (!root.osdVisible && pill.opacity === 0) {
                            root.windowActive = false;
                        }
                    }
                }

                Item {
                    anchors.fill: parent

                    // ── pill ──────────────────────────────────────────────────────────
                    Rectangle {
                        id: pill
                        anchors.centerIn: parent

                        width:  windowRoot.implicitWidth
                        height: windowRoot.implicitHeight

                        color:  "#e01a1b26"
                        radius: Math.min(width, height) / 2

                        opacity: root.osdVisible ? 1 : 0
                        scale:   root.osdVisible ? 1 : 0.92

                        Behavior on opacity {
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                        }

                        // ── value label ────────────────────────────────────────────────
                        Text {
                            text: root.activeOsd === "volume"
                                  ? `${Math.round(root.currentVolume)}%`
                                  : `${Math.round(root.currentBrightness * 100)}%`
                            color: "#c0caf5"
                            font.family: "FiraMono Nerd Font"
                            font.pixelSize: 14
                            font.weight: Font.Medium

                            anchors.right: root.orientation === Qt.Horizontal ? parent.right : undefined
                            anchors.rightMargin: root.orientation === Qt.Horizontal ? 18 : 0
                            anchors.verticalCenter: root.orientation === Qt.Horizontal ? parent.verticalCenter : undefined

                            anchors.top: root.orientation === Qt.Vertical ? parent.top : undefined
                            anchors.topMargin: root.orientation === Qt.Vertical ? 18 : 0
                            anchors.horizontalCenter: root.orientation === Qt.Vertical ? parent.horizontalCenter : undefined

                            opacity: root.osdVisible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }

                        // ── volume slider ──────────────────────────────────────────────
                        FilledSlider {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.bottomMargin: 12
                            anchors.topMargin: root.orientation === Qt.Vertical ? 48 : 12
                            anchors.rightMargin: root.orientation === Qt.Horizontal ? 56 : 12
                            orientation: root.orientation
                            visible: root.activeOsd === "volume"
                            opacity: root.activeOsd === "volume" ? 1 : 0

                            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                            value: root.currentVolume
                            from: 0
                            to: 150

                            iconPath: {
                                if (root.currentMuted) return Quickshell.iconPath("audio-volume-muted");
                                const v = root.currentVolume;
                                if (v <= 0)   return Quickshell.iconPath("audio-volume-muted");
                                if (v <= 33)  return Quickshell.iconPath("audio-volume-low");
                                if (v <= 66)  return Quickshell.iconPath("audio-volume-medium");
                                return Quickshell.iconPath("audio-volume-high");
                            }

                            onMoved: {
                                AudioService.setVolume(value / 100);
                                hideTimer.restart();
                            }
                        }

                        // ── brightness slider ──────────────────────────────────────────
                        FilledSlider {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.bottomMargin: 8
                            anchors.topMargin: root.orientation === Qt.Vertical ? 44 : 8
                            anchors.rightMargin: root.orientation === Qt.Horizontal ? 52 : 8
                            orientation: root.orientation
                            visible: root.activeOsd === "brightness"
                            opacity: root.activeOsd === "brightness" ? 1 : 0

                            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                            value: root.currentBrightness * 100
                            from: 0
                            to: 100

                            iconPath: Quickshell.iconPath("display-brightness-symbolic")

                            onMoved: {
                                BrightnessService.setBrightness(value / 100);
                                hideTimer.restart();
                            }
                        }
                    }
                }
            }
        }
    }
}
