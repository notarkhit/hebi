pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../components"
import "../../services"

Item {
    id: root

    required property bool panelVisible

    signal closeRequested

    readonly property real currentHeight: Math.min(600, col.implicitHeight + 64)
    readonly property real panelWidth: 412

    implicitWidth: panelWidth
    implicitHeight: currentHeight

    onPanelVisibleChanged: {
        Notifs.managerOpen = panelVisible;
        if (panelVisible)
            Notifs.clearPopups();
    }

    property real offsetScale: root.panelVisible ? 0 : 1
    Behavior on offsetScale {
        Anim {}
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 10
            Text {
                text: "Notifications"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.text
                Layout.fillWidth: true
            }
            Rectangle {
                visible: Notifs.history.length > 0
                implicitWidth: clearText.implicitWidth + 12
                implicitHeight: 20
                radius: 4
                color: clearHover.containsMouse ? "#22f7768e" : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear All"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: clearHover.containsMouse ? Theme.error : Theme.subtext
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clearHistory()
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(500, list.contentHeight)
            visible: Notifs.history.length > 0
            clip: true
            ListView {
                id: list
                width: parent.width
                implicitHeight: contentHeight
                spacing: 8
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                model: ScriptModel {
                    values: Notifs.history
                }
                delegate: NotifManagerCard {
                    width: ListView.view.width - 8
                    x: (ListView.view.width - width) / 2
                }
            }
        }

        Item {
            visible: Notifs.history.length === 0
            Layout.fillWidth: true
            implicitHeight: 84
            Text {
                anchors.centerIn: parent
                text: "No notifications"
                color: Theme.subtext
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
            }
        }

        Item {
            implicitHeight: 8
        }
    }
}
