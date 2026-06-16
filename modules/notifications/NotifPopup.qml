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
    readonly property bool isLow:      modelData.urgency === NotificationUrgency.Low
    readonly property bool hasActions: modelData.actions.length > 0
    readonly property int  bodyFmt:    /[<*_`#\[\]]/.test(modelData.body)
                                            ? Text.MarkdownText : Text.PlainText

    // Slide-in direction: "right" (default) or "left"
    // Set by Notifications.qml based on which side the stack is on.
    property string slideFrom: "right"

    // Smart resolvers for when apps use the wrong DBus fields (e.g. notify-send using image-path for icons)
    readonly property string actualIconName: {
        if (modelData.appIcon.length > 0) return modelData.appIcon;
        if (modelData.image.length > 0 && !modelData.image.startsWith("/") && !modelData.image.includes("://")) return modelData.image;
        if (modelData.appName.length > 0) return modelData.appName.toLowerCase();
        return "dialog-information";
    }

    readonly property string actualImageUrl: {
        if (modelData.image.length > 0 && (modelData.image.startsWith("/") || modelData.image.includes("://"))) return modelData.image;
        return "";
    }

    readonly property bool hasIcon: actualIconName !== "dialog-information" || actualImageUrl.length > 0

    // ── sizing ────────────────────────────────────────────────────────────────
    implicitWidth:  card.implicitWidth
    implicitHeight: card.implicitHeight

    // ── slide-in on appear ────────────────────────────────────────────────────
    Component.onCompleted: {
        slideIn.start()
        modelData.lock(root)
    }
    Component.onDestruction: modelData.unlock(root)

    SequentialAnimation {
        id: slideIn
        // Start fully off-screen
        PropertyAction  { target: card; property: "x"; value: slideFrom === "right" ? card.width + 20 : -(card.width + 20) }
        PropertyAction  { target: card; property: "opacity"; value: 0 }
        ParallelAnimation {
            NumberAnimation { target: card; property: "x";       to: 0;   duration: 280; easing.type: Easing.OutQuint }
            NumberAnimation { target: card; property: "opacity"; to: 1;   duration: 180; easing.type: Easing.OutCubic }
        }
    }

    // ── card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        implicitWidth:  380
        implicitHeight: inner.implicitHeight + 20

        radius: 12
        color: root.isCritical ? "#2d1017" : "#1a1b26"
        border.color: root.isCritical ? "#f7768e" : root.isLow ? "#24283b" : "#3b4261"
        border.width: 1

        // Snap-back behavior after swipe drag
        Behavior on x {
            enabled: !drag.drag.active
            NumberAnimation { duration: 300; easing.type: Easing.OutElastic; easing.amplitude: 0.8 }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        // ── contents ──────────────────────────────────────────────────────────
        ColumnLayout {
            id: inner

            anchors.left:    parent.left
            anchors.right:   parent.right
            anchors.top:     parent.top
            anchors.margins: 14
            spacing: 6

            // Header row: icon | app name + summary | time + close
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // App icon / image
                Item {
                    implicitWidth:  36
                    implicitHeight: 36

                    Image {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        sourceSize: Qt.size(22, 22)
                        // Hide this base icon if an overlay image is taking its place
                        visible: root.actualImageUrl.length === 0
                        source: root.actualIconName.startsWith("/") || root.actualIconName.includes("://") 
                                ? Qt.resolvedUrl(root.actualIconName)
                                : "image://icon/" + root.actualIconName
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                    }

                    // Overlay app image (e.g. album art)
                    Image {
                        anchors.fill: parent
                        visible: root.actualImageUrl.length > 0
                        source: root.actualImageUrl.length > 0 ? Qt.resolvedUrl(root.actualImageUrl) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: null // clip via parent Item clipping
                    }
                }

                // Text column: app name + summary
                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        width: parent.width
                        text:  root.modelData.appName
                        color: root.isCritical ? "#ff9e64" : "#565f89"
                        font.family: "FiraMono Nerd Font"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text:  root.modelData.summary
                        color: root.isCritical ? "#f7768e" : "#c0caf5"
                        font.family: "FiraMono Nerd Font"
                        font.pixelSize: 13
                        font.weight:    Font.DemiBold
                        elide: Text.ElideRight
                    }
                }

                // Close button
                Text {
                    text:  "×"
                    color: closeHover.containsMouse ? "#c0caf5" : "#565f89"
                    font.pixelSize: 20
                    Layout.alignment: Qt.AlignTop
                    topPadding: -3

                    Behavior on color { ColorAnimation { duration: 80 } }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: root.modelData.dismiss()
                    }
                }
            }

            // Body text
            Text {
                visible: root.modelData.body.length > 0
                Layout.fillWidth: true
                Layout.leftMargin: 46  // align under summary (36px icon + 10px gap)
                text:        root.modelData.body
                color:       root.isCritical ? "#fca7b0" : root.isLow ? "#545c7e" : "#a9b1d6"
                font.family: "FiraMono Nerd Font"
                font.pixelSize: 11
                textFormat:  root.bodyFmt
                wrapMode:    Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 4
                elide:       Text.ElideRight

                onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
            }

            // Action buttons
            Flow {
                visible: root.hasActions
                Layout.fillWidth: true
                Layout.leftMargin: 46
                spacing: 6

                Repeater {
                    model: root.modelData.actions

                    delegate: Rectangle {
                        required property var modelData

                        implicitHeight: 26
                        implicitWidth:  Math.max(64, btnText.implicitWidth + 20)
                        radius: 6
                        color:  btnHover.containsMouse
                                    ? (root.isCritical ? "#f7768e22" : "#7aa2f722")
                                    : (root.isCritical ? "#f7768e0d" : "#7aa2f70d")
                        border.color: root.isCritical ? "#f7768e55" : "#7aa2f755"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 80 } }

                        Text {
                            id: btnText
                            anchors.centerIn: parent
                            text:        modelData.text
                            color:       root.isCritical ? "#f7768e" : "#7aa2f7"
                            font.family: "FiraMono Nerd Font"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: btnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                modelData.invoke()
                                root.modelData.dismiss()
                            }
                        }
                    }
                }
            }

            // Bottom breathing room
            Item { implicitHeight: 2 }
        }
    }

    // ── hover + swipe-to-dismiss ──────────────────────────────────────────────
    MouseArea {
        id: drag

        anchors.fill: card
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        drag.target:   card
        drag.axis:     Drag.XAxis
        drag.minimumX: -(card.implicitWidth * 2)
        drag.maximumX:  card.implicitWidth * 2

        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor

        onEntered: root.modelData.pauseTimer()
        onExited:  { if (!pressed) root.modelData.resumeTimer() }

        onPressed: event => {
            root.modelData.pauseTimer()
            if (event.button === Qt.MiddleButton) root.modelData.dismiss()
        }

        onReleased: {
            const threshold = card.implicitWidth * 0.35
            if (Math.abs(card.x) >= threshold) {
                root.modelData.dismiss()
            } else {
                card.x = 0  // snap back via Behavior
                if (!containsMouse) root.modelData.resumeTimer()
            }
        }
    }
}
