pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../services"

// Notification manager card.
// Shows a historical notification from Notifs.history.
Item {
    id: root

    required property var modelData

    // ── convenience aliases ───────────────────────────────────────────────────
    readonly property bool isCritical: modelData.urgency === NotificationUrgency.Critical
    readonly property bool isLow: modelData.urgency === NotificationUrgency.Low
    readonly property int bodyFmt: /[<*_`#\[\]]/.test(modelData.body) ? Text.MarkdownText : Text.PlainText

    property bool expanded: false

    readonly property string actualIconName: {
        if (modelData.appIcon && modelData.appIcon.length > 0)
            return modelData.appIcon;
        if (modelData.image && modelData.image.length > 0 && !modelData.image.startsWith("/") && !modelData.image.includes("://"))
            return modelData.image;
        return "";
    }

    readonly property string actualImageUrl: {
        if (modelData.image && modelData.image.length > 0 && (modelData.image.startsWith("/") || modelData.image.includes("://")))
            return modelData.image;
        return "";
    }

    readonly property bool hasImage: actualImageUrl.length > 0
    readonly property bool hasIcon: actualIconName.length > 0 || hasImage

    // ── sizing ────────────────────────────────────────────────────────────────
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    // ── card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        implicitWidth: 360
        implicitHeight: inner.implicitHeight + 20

        radius: 14
        color: "#441a1b26"
        border.color: root.isCritical ? Theme.error : root.isLow ? Theme.surfaceHex : Theme.surfaceVariant
        border.width: 1

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: root.isCritical
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.alpha(Theme.error, 0.25) }
                GradientStop { position: 0.4; color: Qt.alpha(Theme.error, 0.05) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        // Left urgency accent bar
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: parent.radius
            anchors.bottomMargin: parent.radius
            width: root.isCritical ? 4 : 3
            radius: 2
            visible: !root.isLow
            color: root.isCritical ? Theme.error : Theme.accent
        }

        // ── contents ──────────
        ColumnLayout {
            id: inner

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            anchors.leftMargin: 18 // account for accent bar
            spacing: 6

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // App icon / image
                Item {
                    id: iconBox
                    implicitWidth: 32
                    implicitHeight: 32

                    Image {
                        id: baseIcon
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        sourceSize: Qt.size(24, 24)
                        visible: root.actualIconName.length > 0 && overlayImage.status !== Image.Ready
                        source: root.actualIconName.length > 0 ? (root.actualIconName.startsWith("/") || root.actualIconName.includes("://") ? Qt.resolvedUrl(root.actualIconName) : Quickshell.iconPath(root.actualIconName)) : ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                    }

                    // Fallback
                    Text {
                        anchors.centerIn: parent
                        visible: root.actualIconName.length === 0 && overlayImage.status !== Image.Ready
                        text: (root.modelData.appName || "?").charAt(0).toUpperCase()
                        color: Theme.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    // Overlay
                    Image {
                        id: overlayImage
                        anchors.fill: parent
                        visible: status === Image.Ready
                        source: root.actualImageUrl.length > 0 ? Qt.resolvedUrl(root.actualImageUrl) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: null
                    }
                }

                // Text column
                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        width: parent.width
                        text: root.modelData.appName || "Notification"
                        color: Theme.subtext
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.modelData.summary || ""
                        color: Theme.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }

                // Time + expand + close cluster
                RowLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 4

                    // Expand/collapse (only shown when there's meaningful body)
                    Rectangle {
                        id: expandBtn
                        visible: (root.modelData.body || "").length > 0
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 4
                        color: expandHover.containsMouse ? "#663b4261" : "transparent"
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.expanded ? "▲" : "▼"
                            color: expandHover.containsMouse ? Theme.text : Theme.subtext
                            font.pixelSize: 8

                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }
                        }

                        MouseArea {
                            id: expandHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.expanded = !root.expanded
                        }
                    }

                    // Close button
                    Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 4
                        color: closeHover.containsMouse ? "#22f7768e" : "transparent"
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: closeHover.containsMouse ? Theme.error : Theme.subtext
                            font.pixelSize: 16
                            topPadding: -1

                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }
                        }

                        MouseArea {
                            id: closeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.removeHistoryItem(root.modelData)
                        }
                    }
                }
            }

            // Body text
            Text {
                id: bodyText
                visible: (root.modelData.body || "").length > 0
                Layout.fillWidth: true
                Layout.leftMargin: 42
                text: root.modelData.body || ""
                color: root.isLow ? Theme.subtext : Theme.secondary
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                textFormat: root.bodyFmt
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: root.expanded ? 20 : 2
                elide: root.expanded ? Text.ElideNone : Text.ElideRight

                Behavior on maximumLineCount {}

                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            // Bottom breathing room
            Item {
                implicitHeight: 2
            }
        }
    }
}
