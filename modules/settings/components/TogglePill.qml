// Rounded toggle pill button with icon + label + optional chevron
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string iconSource: ""
    property string label:      ""
    property string sublabel:   ""         // secondary text (e.g. SSID)
    property bool   active:     false
    property bool   showChevron: false

    signal clicked()
    signal chevronClicked()

    implicitHeight: 56
    radius:         28

    color: {
        if (active)             return hov.containsMouse ? "#4a6fa8" : "#3d5a8a"
        return hov.containsMouse ? "#2a2d3e" : "#1e2030"
    }

    Behavior on color { ColorAnimation { duration: 120 } }

    // Border for inactive state
    Rectangle {
        anchors.fill: parent
        radius:       parent.radius
        color:        "transparent"
        border.color: root.active ? "transparent" : "#3b4261"
        border.width: 1
    }

    RowLayout {
        anchors.fill:    parent
        anchors.margins: 16
        spacing:         10

        // Icon
        Image {
            sourceSize:     Qt.size(18, 18)
            source:         root.iconSource
            fillMode:       Image.PreserveAspectFit
            Layout.alignment: Qt.AlignVCenter
            opacity:        root.active ? 1 : 0.6
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        // Label block
        Column {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text:         root.label
                color:        root.active ? "#c0caf5" : "#a9b1d6"
                font.family:  "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.weight:  root.active ? Font.Medium : Font.Normal
                elide:        Text.ElideRight
                width:        parent.width
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
                visible:      root.sublabel.length > 0
                text:         root.sublabel
                color:        "#565f89"
                font.family:  "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                elide:        Text.ElideRight
                width:        parent.width
            }
        }

        // Chevron
        Text {
            visible:        root.showChevron
            text:           "›"
            color:          root.active ? "#c0caf5" : "#545c7e"
            font.pixelSize: 18
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill:  parent
                anchors.margins: -6
                cursorShape:   Qt.PointingHandCursor
                onClicked:     root.chevronClicked()
            }
        }
    }

    MouseArea {
        id: hov
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
