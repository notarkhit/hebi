import QtQuick
import Quickshell

Item {
    id: root

    property int orientation: Qt.Horizontal
    property real value: 0
    property real from: 0
    property real to: 100
    property string iconPath: ""
    signal moved()

    readonly property real percent: (to > from) ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    readonly property bool isInteracting: dragArea.pressed

    // Fill track
    Rectangle {
        id: fill
        color: "#7aa2f7"
        radius: root.orientation === Qt.Horizontal ? height / 2 : width / 2

        x: 0
        y: root.orientation === Qt.Horizontal ? 0 : parent.height * (1 - root.percent)

        width:  root.orientation === Qt.Horizontal ? parent.width * root.percent : parent.width
        height: root.orientation === Qt.Horizontal ? parent.height : parent.height * root.percent
    }

    // Handle bubble
    Rectangle {
        id: handle
        width:  root.orientation === Qt.Horizontal ? parent.height : parent.width
        height: root.orientation === Qt.Horizontal ? parent.height : parent.width

        x: root.orientation === Qt.Horizontal ? (parent.width - width) * root.percent : 0
        y: root.orientation === Qt.Horizontal ? 0 : (parent.height - height) * (1 - root.percent)

        radius: Math.min(width, height) / 2
        color:  "#7aa2f7"

        scale: dragArea.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        Image {
            id: icon
            anchors.centerIn: parent
            source: root.iconPath
            sourceSize: Qt.size(24, 24)

            opacity: dragArea.pressed ? 0 : 1
            scale:   dragArea.pressed ? 0.6 : 1

            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        }

        Text {
            anchors.centerIn: parent
            text:  Math.round(root.value)
            color: "#1a1b26"
            font.bold: true
            font.pixelSize: 13

            opacity: dragArea.pressed ? 1 : 0
            scale:   dragArea.pressed ? 1 : 0.6

            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent

        onPositionChanged: (mouse) => {
            if (dragArea.pressed) {
                let p = root.orientation === Qt.Horizontal
                    ? Math.max(0, Math.min(1, mouse.x / root.width))
                    : Math.max(0, Math.min(1, 1 - (mouse.y / root.height)));
                root.value = root.from + p * (root.to - root.from);
                root.moved();
            }
        }

        onPressed: (mouse) => {
            let p = root.orientation === Qt.Horizontal
                ? Math.max(0, Math.min(1, mouse.x / root.width))
                : Math.max(0, Math.min(1, 1 - (mouse.y / root.height)));
            root.value = root.from + p * (root.to - root.from);
            root.moved();
        }
    }

    Behavior on value {
        enabled: !dragArea.pressed
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
}
