// Reusable slider row: icon + slider track
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string iconText: ""
    property real value: 0.5        // 0.0–1.0
    property real maxValue: 1.0
    property bool showArrow: false      // right-side action button

    signal changed(real newValue)
    signal arrowClicked

    implicitHeight: 32
    Layout.fillWidth: true

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // Icon
        Text {
            text: root.iconText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter
            color: "#7aa2f7"
            opacity: 0.9
        }

        // Track + fill
        Item {
            Layout.fillWidth: true
            implicitHeight: 6
            Layout.alignment: Qt.AlignVCenter

            // Track background
            Rectangle {
                anchors.fill: parent
                radius: 3
                color: "#2a2e45"
            }

            // Fill
            Rectangle {
                width: parent.width * Math.min(1, root.value / root.maxValue)
                height: parent.height
                radius: 3
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "#5d7fcc"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#7aa2f7"
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Thumb
            Rectangle {
                x: parent.width * Math.min(1, root.value / root.maxValue) - width / 2
                y: (parent.height - height) / 2
                width: 14
                height: 14
                radius: 7
                color: "#ffffff"
                layer.enabled: true
                layer.effect: null // just white for now
                Behavior on x {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Drag handler
            MouseArea {
                anchors.fill: parent
                anchors.margins: -10
                function updateFromMouse(mx) {
                    const clamped = Math.max(0, Math.min(parent.width, mx));
                    const v = (clamped / parent.width) * root.maxValue;
                    root.changed(v);
                }
                onPressed: mouse => updateFromMouse(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        updateFromMouse(mouse.x);
                }
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Arrow button
        Rectangle {
            visible: root.showArrow
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: arrowHover.containsMouse ? "#3b4261" : "transparent"
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Text {
                anchors.centerIn: parent
                text: "›"
                color: arrowHover.containsMouse ? "#ffffff" : "#7aa2f7"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            MouseArea {
                id: arrowHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.arrowClicked()
            }
        }
    }
}
