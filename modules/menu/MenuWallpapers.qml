pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"

// Horizontal wallpaper picker carousel.
// Mirrors env/shell's WallpaperList/WallpaperItem pattern:
//  - PathView so center item is full-scale, flanking items are scaled down
//  - Navigating previews colors; Enter applies.
PathView {
    id: root

    signal action

    // ── Sizing ─────────────────────────────────────────────────────────────
    // Each thumbnail card is 16:9, plus label below
    readonly property int thumbW: 200
    readonly property int thumbH: thumbW * 9 / 16   // 112
    readonly property int cardH: thumbH + 28 + 12   // thumb + label + padding

    // Show as many items as fit, odd numbers only (to keep a clear center)
    readonly property int visibleCount: {
        const n = Math.min(Wallpapers.list.length, 5);
        return n % 2 === 0 ? Math.max(1, n - 1) : n;
    }

    implicitWidth: 1080
    implicitHeight: cardH + 16

    // ── Model ──────────────────────────────────────────────────────────────
    model: Wallpapers.list

    // Start on current wallpaper
    Component.onCompleted: {
        const idx = Wallpapers.list.findIndex(e => e.path === Wallpapers.currentPath);
        currentIndex = idx >= 0 ? idx : 0;
    }

    Component.onDestruction: Wallpapers.stopPreview()

    onCurrentItemChanged: {
        if (currentItem)
            Wallpapers.preview(currentItem.entryPath);
    }

    // ── PathView config ────────────────────────────────────────────────────
    pathItemCount: visibleCount
    cacheItemCount: 3

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    path: Path {
        startX: 0
        startY: root.height / 2
        PathLine {
            x: root.width
            y: root.height / 2
        }
    }

    // ── Keyboard nav ───────────────────────────────────────────────────────
    function handleLeft() {
        decrementCurrentIndex();
    }
    function handleRight() {
        incrementCurrentIndex();
    }
    // Up/Down scroll through as well (since MenuItem uses Up/Down)
    function handleUp() {
        decrementCurrentIndex();
    }
    function handleDown() {
        incrementCurrentIndex();
    }
    function handleReturn() {
        if (currentItem) {
            Wallpapers.apply(currentItem.entryPath);
            root.action();
        }
    }

    // ── Delegate ───────────────────────────────────────────────────────────
    delegate: Item {
        id: card
        required property var modelData

        // Expose path for parent to read via currentItem
        readonly property string entryPath: modelData.path
        readonly property bool isCurrent: modelData.path === Wallpapers.currentPath

        implicitWidth: root.thumbW + 16
        implicitHeight: root.cardH

        scale: PathView.isCurrentItem ? 1.0 : (PathView.onPath ? 0.82 : 0)
        opacity: PathView.onPath ? 1 : 0

        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        // Click to apply
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.currentIndex = card.PathView.view.indexOf(card);
                Wallpapers.apply(card.entryPath);
                root.action();
            }
        }

        // ── Thumbnail ──────────────────────────────────────────────────────
        Rectangle {
            id: thumb
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            width: root.thumbW
            height: root.thumbH
            radius: 10
            color: Theme.surfaceVariant
            clip: true

            Image {
                anchors.fill: parent
                source: "file://" + card.entryPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: root.thumbW * 2
                sourceSize.height: root.thumbH * 2
                smooth: !root.moving
            }

            // Accent ring on current item
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: Theme.accent
                border.width: card.PathView.isCurrentItem ? 2 : 0
            }

            // "Applied" indicator
            Rectangle {
                visible: card.isCurrent
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                width: 8; height: 8; radius: 4
                color: Theme.success
            }

            // Shadow/elevation under selected item
            layer.enabled: card.PathView.isCurrentItem
            layer.effect: null  // basic layer, no shader needed for now
        }

        // ── Filename label ─────────────────────────────────────────────────
        Text {
            anchors.top: thumb.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.thumbW
            text: modelData.name
            color: card.PathView.isCurrentItem ? Theme.accent : Theme.subtext
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
