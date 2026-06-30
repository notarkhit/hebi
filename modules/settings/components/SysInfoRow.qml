// Single row in the System Info pane: icon · label · value
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string iconText: ""
    property string label: ""
    property string value: ""
    // 0–100 fill for the subtle progress bar; -1 = hide bar
    property real   fillPercent: -1

    implicitHeight: 28
    Layout.fillWidth: true

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // Nerd-font icon
        Text {
            text: root.iconText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: "#7aa2f7"
            opacity: 0.85
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 18
        }

        // Label
        Text {
            text: root.label
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#a9b1d6"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }

        // Optional mini progress bar
        Item {
            visible: root.fillPercent >= 0
            implicitWidth: 48
            implicitHeight: 4
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: "#1e2235"
            }
            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, root.fillPercent)) / 100
                height: parent.height
                radius: 2
                color: root.fillPercent > 85 ? "#f7768e"
                     : root.fillPercent > 60 ? "#e0af68"
                     : "#7aa2f7"
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }

        // Value
        Text {
            text: root.value
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#c0caf5"
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 80
        }
    }
}
