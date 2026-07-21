pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import "../../services"

Item {
    id: root

    required property bool panelVisible

    signal closeRequested

    readonly property real panelWidth: col.implicitWidth + 32

    implicitWidth: panelWidth
    implicitHeight: col.implicitHeight + 32

    // ── animation ─────────────────────────────────────────────────────────────
    property real offsetScale: root.panelVisible ? 0 : 1
    Behavior on offsetScale { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

    // ── context menu data ─────────────────────────────────────────────────────
    QsMenuOpener {
        id: menuOpener
        menu: root.panelVisible ? TrayMenuState.menuHandle : null
    }

    // ── content ───────────────────────────────────────────────────────────────
    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        spacing: 4

        Repeater {
            model: menuOpener.children

            Item {
                id: menuRow
                required property QsMenuEntry modelData

                // Determine row width from label width + padding
                implicitWidth: menuRow.modelData.isSeparator ? 160 : Math.max(160, rowLabel.implicitWidth + 32)
                implicitHeight: menuRow.modelData.isSeparator ? 9   : 30

                // Separator
                Rectangle {
                    visible: menuRow.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 16
                    height: 1
                    color: Theme.surfaceVariant
                }

                // Menu Item
                Rectangle {
                    visible: !menuRow.modelData.isSeparator
                    anchors.fill: parent
                    radius: 6
                    color: rowHover.containsMouse && menuRow.modelData.enabled
                           ? Theme.surfaceVariant : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    HoverHandler { id: rowHover }

                    TapHandler {
                        enabled: menuRow.modelData.enabled && !menuRow.modelData.isSeparator
                        onTapped: {
                            menuRow.modelData.triggered()
                            root.closeRequested()
                        }
                    }

                    Text {
                        id: rowLabel
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: menuRow.modelData.hasChildren ? 24 : 12
                        text: menuRow.modelData.text
                        color: menuRow.modelData.enabled ? Theme.text : Theme.subtext
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    // Chevron for submenus
                    Text {
                        visible: menuRow.modelData.hasChildren
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        text: "󰅀"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        rotation: -90
                        color: Theme.subtext
                    }
                }
            }
        }
    }
}
