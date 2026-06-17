import QtQuick
import Quickshell

// Elegant slim OSD slider.
// Horizontal layout: [icon] [────track with fill────]
// Vertical layout:   icon on top, thin track below
Item {
    id: root

    property int orientation: Qt.Horizontal
    property real value: 0
    property real _dragValue: 0
    property real from: 0
    property real to: 100
    property string iconPath: ""
    signal moved(real newValue)

    readonly property bool isInteracting: dragArea.pressed
    readonly property real effectiveValue: isInteracting ? _dragValue : value
    readonly property real percent: (to > from) ? Math.max(0, Math.min(1, (effectiveValue - from) / (to - from))) : 0

    // ── horizontal layout ────────────────────────────────────────────────
    Row {
        anchors.fill: parent
        anchors.leftMargin:  root.orientation === Qt.Horizontal ? 2 : 0
        anchors.rightMargin: root.orientation === Qt.Horizontal ? 2 : 0
        spacing: 10
        visible: root.orientation === Qt.Horizontal

        // Icon
        Image {
            id: hIcon
            anchors.verticalCenter: parent.verticalCenter
            width: 20; height: 20
            sourceSize: Qt.size(20, 20)
            source: root.iconPath
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
        }

        // Track
        Item {
            id: hTrack
            anchors.verticalCenter: parent.verticalCenter
            width:  parent.width - hIcon.width - parent.spacing
            height: 4

            // Background
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#2a2c3d"
            }

            // Fill
            Rectangle {
                width:  parent.width * root.percent
                height: parent.height
                radius: height / 2
                color:  "#7aa2f7"

                Behavior on width {
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                }
            }

            // Thumb dot
            Rectangle {
                x: (parent.width - width) * root.percent
                y: (parent.height - height) / 2
                width:  10
                height: 10
                radius: 5
                color:  "#c0caf5"

                scale: dragArea.pressed ? 1.4 : 1
                Behavior on scale  { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                Behavior on x {
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    // ── vertical layout ───────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.topMargin:    root.orientation === Qt.Vertical ? 2 : 0
        anchors.bottomMargin: root.orientation === Qt.Vertical ? 2 : 0
        spacing: 10
        visible: root.orientation === Qt.Vertical

        Image {
            id: vIcon
            anchors.horizontalCenter: parent.horizontalCenter
            width: 20; height: 20
            sourceSize: Qt.size(20, 20)
            source: root.iconPath
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
        }

        Item {
            id: vTrack
            anchors.horizontalCenter: parent.horizontalCenter
            width:  4
            height: parent.height - vIcon.height - parent.spacing

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#2a2c3d"
            }

            // Fill (grows from bottom)
            Rectangle {
                anchors.bottom: parent.bottom
                width:  parent.width
                height: parent.height * root.percent
                radius: width / 2
                color:  "#7aa2f7"

                Behavior on height {
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                }
            }

            // Thumb dot
            Rectangle {
                x: (parent.width - width) / 2
                y: (parent.height - height) * (1 - root.percent)
                width:  10
                height: 10
                radius: 5
                color:  "#c0caf5"

                scale: dragArea.pressed ? 1.4 : 1
                Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                Behavior on y {
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    Timer {
        id: throttleTimer
        interval: 32 // ~30fps max IPC emission
    }

    // ── interaction ───────────────────────────────────────────────────────
    MouseArea {
        id: dragArea
        anchors.fill: parent

        onPositionChanged: (mouse) => {
            if (!pressed) return;
            let p = root.orientation === Qt.Horizontal
                ? Math.max(0, Math.min(1, (mouse.x - hIcon.width - 10) / hTrack.width))
                : Math.max(0, Math.min(1, 1 - (mouse.y / root.height)));
            root._dragValue = root.from + p * (root.to - root.from);
            
            if (!throttleTimer.running) {
                root.moved(root._dragValue);
                throttleTimer.restart();
            }
        }

        onPressed: (mouse) => {
            let p = root.orientation === Qt.Horizontal
                ? Math.max(0, Math.min(1, (mouse.x - hIcon.width - 10) / hTrack.width))
                : Math.max(0, Math.min(1, 1 - (mouse.y / root.height)));
            root._dragValue = root.from + p * (root.to - root.from);
            root.moved(root._dragValue);
            throttleTimer.restart();
        }
        
        onReleased: {
            root.moved(root._dragValue);
        }
    }
}
