pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../services"

// Single notification popup card.
// Slides in from the side; swipe horizontally to dismiss.
Item {
    id: root

    required property NotifData modelData

    // ── convenience aliases ───────────────────────────────────────────────────
    readonly property bool isCritical: modelData.urgency === NotificationUrgency.Critical
    readonly property bool isLow: modelData.urgency === NotificationUrgency.Low
    readonly property bool hasActions: modelData.actions.length > 0
    readonly property int bodyFmt: /[<*_`#\[\]]/.test(modelData.body) ? Text.MarkdownText : Text.PlainText

    // Progress value from hints: notify-send -h int:value:75
    readonly property int progressValue: {
        const v = modelData.hints?.value ?? -1;
        return (typeof v === "number") ? Math.max(-1, Math.min(100, Math.round(v))) : -1;
    }
    readonly property bool hasProgress: progressValue >= 0

    // Slide-in direction: "right" (default) or "left"
    property string slideFrom: "right"

    // Expand/collapse state - auto-expand when there are action buttons
    property bool expanded: hasActions

    // Smart resolvers for when apps use the wrong DBus fields
    readonly property string actualIconName: {
        if (modelData.appIcon.length > 0)
            return modelData.appIcon;
        if (modelData.image.length > 0 && !modelData.image.startsWith("/") && !modelData.image.includes("://"))
            return modelData.image;
        return "";
    }

    readonly property string actualImageUrl: {
        if (modelData.image.length > 0 && (modelData.image.startsWith("/") || modelData.image.includes("://")))
            return modelData.image;
        return "";
    }

    readonly property bool hasImage: actualImageUrl.length > 0
    readonly property bool hasIcon: actualIconName.length > 0 || hasImage

    // ── sizing ────────────────────────────────────────────────────────────────
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    // ── slide-in on appear ────────────────────────────────────────────────────
    Component.onCompleted: {
        slideIn.start();
        modelData.lock(root);
    }
    Component.onDestruction: modelData.unlock(root)

    SequentialAnimation {
        id: slideIn
        PropertyAction {
            target: card
            property: "x"
            value: slideFrom === "right" ? card.width + 20 : -(card.width + 20)
        }
        PropertyAction {
            target: card
            property: "opacity"
            value: 0
        }
        ParallelAnimation {
            NumberAnimation {
                target: card
                property: "x"
                to: 0
                duration: 280
                easing.type: Easing.OutQuint
            }
            NumberAnimation {
                target: card
                property: "opacity"
                to: 1
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    // ── card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        implicitWidth: 380
        implicitHeight: inner.implicitHeight + 20

        radius: 14
        color: root.isCritical ? "#1a0a0e" : "#1a1b26"
        border.color: root.isCritical ? "#f7768e" : root.isLow ? "#24283b" : "#3b4261"
        border.width: root.isCritical ? 1.5 : 1

        // Snap-back behavior after swipe drag
        Behavior on x {
            enabled: !drag.drag.active
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutElastic
                easing.amplitude: 0.8
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        // ── drag-to-dismiss area — declared FIRST so content layers above it ──
        MouseArea {
            id: drag

            anchors.fill: parent
            hoverEnabled: true
            // Do NOT set preventStealing=true — we need child MouseAreas to win
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton

            drag.target: card
            drag.axis: Drag.XAxis
            drag.minimumX: -(card.implicitWidth * 2)
            drag.maximumX: card.implicitWidth * 2

            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor

            onEntered: root.modelData.pauseTimer()
            onExited: {
                if (!pressed)
                    root.modelData.resumeTimer();
            }

            onPressed: event => {
                root.modelData.pauseTimer();
                if (event.button === Qt.MiddleButton)
                    root.modelData.dismiss();
            }

            onReleased: {
                const threshold = card.implicitWidth * 0.35;
                if (Math.abs(card.x) >= threshold) {
                    root.modelData.dismiss();
                } else {
                    card.x = 0;  // snap back via Behavior
                    if (!containsMouse)
                        root.modelData.resumeTimer();
                }
            }
        }

        // Left urgency accent bar — above drag area
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: parent.radius
            anchors.bottomMargin: parent.radius
            width: 3
            radius: 2
            visible: !root.isLow
            color: root.isCritical ? "#f7768e" : "#7aa2f7"
        }

        // ── contents — declared after drag so they are painted on top ──────────
        ColumnLayout {
            id: inner

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            anchors.leftMargin: 18 // account for accent bar
            spacing: 6

            // Header row: icon | app name + summary | time + expand + close
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // App icon / image
                Item {
                    id: iconBox
                    implicitWidth: 40
                    implicitHeight: 40

                    Image {
                        id: baseIcon
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        sourceSize: Qt.size(32, 32)
                        visible: root.actualIconName.length > 0 && overlayImage.status !== Image.Ready
                        source: root.actualIconName.length > 0 ? (root.actualIconName.startsWith("/") || root.actualIconName.includes("://") ? Qt.resolvedUrl(root.actualIconName) : Quickshell.iconPath(root.actualIconName)) : ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                    }

                    // Fallback: first letter of appName
                    Text {
                        anchors.centerIn: parent
                        visible: root.actualIconName.length === 0 && overlayImage.status !== Image.Ready
                        text: (root.modelData.appName || "?").charAt(0).toUpperCase()
                        color: root.isCritical ? "#f7768e" : "#7aa2f7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }

                    // Overlay: album art / arbitrary image
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

                // Text column: app name + summary
                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        width: parent.width
                        text: root.modelData.appName
                        color: root.isCritical ? "#ff9e64" : "#565f89"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.modelData.summary
                        color: root.isCritical ? "#f7768e" : "#c0caf5"
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

                    // Elapsed time
                    Text {
                        text: root.modelData.timeStr
                        color: "#3b4261"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Expand/collapse (only shown when there's meaningful body)
                    Rectangle {
                        id: expandBtn
                        visible: root.modelData.body.length > 0
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 4
                        color: expandHover.containsMouse ? "#3b426166" : "transparent"
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.expanded ? "▲" : "▼"
                            color: expandHover.containsMouse ? "#c0caf5" : "#565f89"
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
                        color: closeHover.containsMouse ? "#f7768e22" : "transparent"
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: closeHover.containsMouse ? "#f7768e" : "#565f89"
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
                            onClicked: root.modelData.dismiss()
                        }
                    }
                }
            }

            // Body text — shows a 1-line preview when collapsed, full text when expanded
            Text {
                id: bodyText
                visible: root.modelData.body.length > 0
                Layout.fillWidth: true
                Layout.leftMargin: 50  // align under summary (40px icon + 10px gap)
                text: root.modelData.body
                color: root.isCritical ? "#fca7b0" : root.isLow ? "#545c7e" : "#a9b1d6"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                textFormat: root.bodyFmt
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: root.expanded ? 20 : 2
                elide: root.expanded ? Text.ElideNone : Text.ElideRight

                Behavior on maximumLineCount {}

                onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
            }

            // Progress bar (linear) — shown when hints.value present
            Item {
                visible: root.hasProgress
                Layout.fillWidth: true
                Layout.leftMargin: 50
                implicitHeight: 20

                // Label: "75%"
                Text {
                    id: progressLabel
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${root.progressValue}%`
                    color: root.isCritical ? "#f7768e" : "#7aa2f7"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                }

                // Track
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: progressLabel.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 2
                    color: root.isCritical ? "#f7768e22" : "#7aa2f722"

                    // Fill
                    Rectangle {
                        width: parent.width * (root.progressValue / 100)
                        height: parent.height
                        radius: 2
                        color: root.isCritical ? "#f7768e" : "#7aa2f7"

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            // Action buttons
            Flow {
                visible: root.hasActions && root.expanded
                Layout.fillWidth: true
                Layout.leftMargin: 50
                spacing: 6

                Repeater {
                    model: root.modelData.actions

                    delegate: Rectangle {
                        required property var modelData

                        implicitHeight: 26
                        implicitWidth: Math.max(64, btnText.implicitWidth + 20)
                        radius: 6
                        color: btnHover.containsMouse ? (root.isCritical ? "#f7768e22" : "#7aa2f722") : (root.isCritical ? "#f7768e0d" : "#7aa2f70d")
                        border.color: root.isCritical ? "#f7768e55" : "#7aa2f755"
                        border.width: 1

                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }

                        Text {
                            id: btnText
                            anchors.centerIn: parent
                            text: modelData.text
                            color: root.isCritical ? "#f7768e" : "#7aa2f7"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }

                        // Button MouseArea — wins because it is painted above drag
                        MouseArea {
                            id: btnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modelData.invoke();
                                root.modelData.dismiss();
                            }
                        }
                    }
                }
            }

            // Bottom breathing room
            Item {
                implicitHeight: 2
            }
        }
    }
}
