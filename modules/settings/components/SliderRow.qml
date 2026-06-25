// Reusable slider row: icon + slider track
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string iconSource: ""
    property real   value:      0.5        // 0.0–1.0
    property real   maxValue:   1.0
    property bool   showArrow:  false      // right-side action button

    signal changed(real newValue)
    signal arrowClicked()

    implicitHeight: 28
    Layout.fillWidth: true

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // Icon
        Image {
            sourceSize: Qt.size(16, 16)
            source:     root.iconSource
            fillMode:   Image.PreserveAspectFit
            Layout.alignment: Qt.AlignVCenter
            opacity: 0.7
        }

        // Track + fill
        Item {
            Layout.fillWidth: true
            implicitHeight:   4
            Layout.alignment: Qt.AlignVCenter

            // Track background
            Rectangle {
                anchors.fill: parent
                radius: 2
                color: "#292e42"
            }

            // Fill
            Rectangle {
                width:  parent.width * Math.min(1, root.value / root.maxValue)
                height: parent.height
                radius: 2
                color:  "#7aa2f7"
                Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }

            // Thumb
            Rectangle {
                x:      parent.width * Math.min(1, root.value / root.maxValue) - width / 2
                y:      (parent.height - height) / 2
                width:  12; height: 12
                radius: 6
                color:  "#c0caf5"
                Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }

            // Drag handler
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                function updateFromMouse(mx) {
                    const clamped = Math.max(0, Math.min(parent.width, mx))
                    const v = (clamped / parent.width) * root.maxValue
                    root.changed(v)
                }
                onPressed:       mouse => updateFromMouse(mouse.x)
                onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse.x) }
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Optional arrow button (e.g. open pavucontrol)
        Rectangle {
            visible:       root.showArrow
            implicitWidth: 24; implicitHeight: 24
            radius:        12
            color:         arrowHover.containsMouse ? "#3b4261" : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                anchors.centerIn: parent
                text: "›"
                color: "#7aa2f7"
                font.pixelSize: 18
            }

            MouseArea {
                id: arrowHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    root.arrowClicked()
            }
        }
    }
}
