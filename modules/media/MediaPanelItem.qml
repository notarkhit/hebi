pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Hebi.Blobs
import Hebi.Services
import "../../services"

Item {
    id: root

    required property bool panelVisible

    signal closeRequested

    property bool showLyrics: false
    readonly property real panelWidth: 392
    readonly property real currentHeight: implicitHeight

    implicitWidth: panelWidth
    implicitHeight: showLyrics ? (Lyrics.hasLyrics ? 620 : 320) : 260
    Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    onPanelVisibleChanged: { if (!panelVisible) showLyrics = false }

    function updateLyrics() {
        const p = Players.active
        if (p) Lyrics.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, p.length)
        else   Lyrics.clearTrack()
    }

    Connections {
        target: Lyrics
        function onLoadingChanged() { if (!Lyrics.loading && Lyrics.trackTitle !== "") root.showLyrics = true }
    }
    Connections {
        target: Players.active
        function onTrackArtistChanged() { root.showLyrics = false; Lyrics.clearTrack() }
        function onTrackTitleChanged()  { root.showLyrics = false; Lyrics.clearTrack() }
    }
    Connections { target: Players; function onActiveChanged() { root.updateLyrics() } }
    Component.onCompleted: root.updateLyrics()

    property real offsetScale: root.panelVisible ? 0 : 1
    Behavior on offsetScale {
        NumberAnimation { duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1] }
    }
    transform: Translate { y: (-root.implicitHeight - 5) * root.offsetScale }
    opacity: 1 - offsetScale

    BlobGroup { id: bgGroup; color: Theme.surface }
    BlobRect { group: bgGroup; anchors.fill: parent; radius: 20; stiffness: 200; damping: 18; deformScale: 0.006 }

    ColumnLayout {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 20; anchors.topMargin: 24; spacing: 20

        RowLayout {
            Layout.fillWidth: true; spacing: 16
            Rectangle {
                implicitWidth: 80; implicitHeight: 80; radius: 10; color: "#1a1b26"; clip: true
                Image { anchors.fill: parent; source: Players.active ? Players.getArtUrl(Players.active) : ""; fillMode: Image.PreserveAspectCrop; visible: source !== "" }
                Text { anchors.centerIn: parent; text: "󰎆"; color: "#565f89"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 32; visible: parent.children[0].source === "" }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                Text { text: Players.active?.trackTitle || "No Media Playing"; color: "#c0caf5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: Players.active?.trackArtist || "Unknown Artist"; color: "#9aa5ce"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: root.formatTime(Players.active?.position ?? 0); color: "#565f89"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
            Slider {
                id: progressSlider; Layout.fillWidth: true; from: 0; to: Math.max(1, Players.active?.length ?? 1); enabled: Players.active?.canSeek ?? false
                Binding { target: progressSlider; property: "value"; value: Players.active?.position ?? 0; when: !progressSlider.pressed }
                background: Rectangle { x: progressSlider.leftPadding; y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2; implicitWidth: 200; implicitHeight: 4; width: progressSlider.availableWidth; height: implicitHeight; radius: 2; color: "#292e42"; Rectangle { width: progressSlider.visualPosition * parent.width; height: parent.height; color: "#7aa2f7"; radius: 2 } }
                handle: Rectangle { x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width); y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2; implicitWidth: 12; implicitHeight: 12; radius: 6; color: progressSlider.pressed ? "#bb9af7" : "#7aa2f7" }
                onMoved: { if (Players.active) Players.active.position = value }
            }
            Text { text: root.formatTime(Players.active?.length ?? 0); color: "#565f89"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
        }

        Item {
            width: parent.width; implicitHeight: 48
            RowLayout {
                anchors.centerIn: parent; spacing: 24
                Text {
                    text: "󰒮"; color: hoverPrev.hovered ? "#bb9af7" : "#7aa2f7"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24
                    opacity: Players.active?.canGoPrevious ? 1 : 0.5
                    HoverHandler { id: hoverPrev; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Players.active?.previous() }
                }
                Rectangle {
                    implicitWidth: 48; implicitHeight: 48; radius: 24; color: hoverPlay.hovered ? "#bb9af7" : "#7aa2f7"
                    Text { anchors.centerIn: parent; text: Players.active?.isPlaying ? "󰏤" : "󰐊"; color: "#1a1b26"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28; anchors.horizontalCenterOffset: Players.active?.isPlaying ? 0 : 2 }
                    HoverHandler { id: hoverPlay; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Players.active?.togglePlaying() }
                }
                Text {
                    text: "󰒭"; color: hoverNext.hovered ? "#bb9af7" : "#7aa2f7"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24
                    opacity: Players.active?.canGoNext ? 1 : 0.5
                    HoverHandler { id: hoverNext; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Players.active?.next() }
                }
            }
            Text {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "󰦨"
                color: hoverLyrics.hovered || root.showLyrics ? "#bb9af7" : "#7aa2f7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24; opacity: Lyrics.hasLyrics ? 1 : 0.5
                HoverHandler { id: hoverLyrics; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: { const p = Players.active; if (!p) return; if (Lyrics.trackTitle === p.trackTitle && Lyrics.trackArtist === p.trackArtist && Lyrics.trackTitle !== "") root.showLyrics = !root.showLyrics; else root.updateLyrics() } }
            }
        }

        Rectangle {
            Layout.fillWidth: true; implicitHeight: Lyrics.hasLyrics ? 340 : 40; Layout.preferredHeight: Lyrics.hasLyrics ? 340 : 40
            color: "transparent"; radius: 10; clip: true; visible: root.showLyrics
            Text { anchors.centerIn: parent; text: Lyrics.loading ? "Loading lyrics..." : (Lyrics.hasLyrics ? "" : "No lyrics available"); color: "#565f89"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
            ListView {
                id: lyricsList; anchors.fill: parent; anchors.margins: 12; model: Lyrics.lyrics; spacing: 12; visible: Lyrics.hasLyrics
                Component.onCompleted: { currentIndex = Qt.binding(() => Lyrics.indexForTime(Players.active?.position ?? 0)) }
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Center)
                preferredHighlightBegin: height / 2 - 10; preferredHighlightEnd: height / 2 + 10
                highlightRangeMode: ListView.ApplyRange; highlightMoveDuration: 300
                delegate: Text {
                    width: lyricsList.width; text: modelData || ". . ."; color: ListView.isCurrentItem ? "#7aa2f7" : mouse.containsMouse ? "#c0caf5" : "#565f89"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: ListView.isCurrentItem ? 15 : 13; font.bold: ListView.isCurrentItem
                    wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (Players.active) Players.active.position = Lyrics.timeForIndex(index) } }
                }
            }
        }
    }

    function formatTime(microsecs: real): string {
        if (microsecs < 0) return "0:00"
        let secs = Math.floor(microsecs / 1000000); let mins = Math.floor(secs / 60); secs = secs % 60
        return mins + ":" + secs.toString().padStart(2, "0")
    }

    Timer { running: Players.active?.isPlaying ?? false; interval: 100; repeat: true; onTriggered: { if (Players.active) Players.active.positionChanged() } }
}
