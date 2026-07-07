pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../components"
import Hebi.Services
import QtQml
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
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    onPanelVisibleChanged: {
        if (!panelVisible)
            showLyrics = false;
    }

    function updateLyrics() {
        const p = Players.active;
        if (p)
            Lyrics.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, p.length);
        else
            Lyrics.clearTrack();
    }

    Connections {
        target: Lyrics
        function onLoadingChanged() {
            if (!Lyrics.loading && Lyrics.trackTitle !== "")
                root.showLyrics = true;
        }
    }
    Connections {
        target: Players.active
        function onTrackArtistChanged() {
            root.showLyrics = false;
            Lyrics.clearTrack();
        }
        function onTrackTitleChanged() {
            root.showLyrics = false;
            Lyrics.clearTrack();
        }
    }
    Connections {
        target: Players
        function onActiveChanged() {
            root.updateLyrics();
        }
    }
    Component.onCompleted: root.updateLyrics()

    property real offsetScale: root.panelVisible ? 0 : 1
    Behavior on offsetScale {
        Anim {}
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        onClicked: {
            if (playerDropdown.visible) {
                playerDropdown.visible = false;
            }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        anchors.topMargin: 24
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Rectangle {
                implicitWidth: 80
                implicitHeight: 80
                radius: 10
                color: "#1a1b26"
                clip: true
                Image {
                    anchors.fill: parent
                    source: Players.active ? Players.getArtUrl(Players.active) : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== ""
                }
                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    color: "#565f89"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 32
                    visible: parent.children[0].source === ""
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: Players.active?.trackTitle || "No Media Playing"
                    color: "#c0caf5"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: Players.active?.trackArtist || "Unknown Artist"
                    color: "#9aa5ce"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            Item {
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                implicitWidth: playerBtn.implicitWidth + 20
                implicitHeight: 28
                visible: Players.list.length > 0
                z: 100
                
                Button {
                    id: playerBtn
                    anchors.fill: parent
                    text: Players.active ? Players.getIdentity(Players.active) : "No Players"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    background: Rectangle {
                        color: "#1a1b26"
                        radius: 6
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#7aa2f7"
                        font: parent.font
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: playerDropdown.visible = !playerDropdown.visible
                }
                
                Rectangle {
                    id: playerDropdown
                    visible: false
                    anchors.top: playerBtn.bottom
                    anchors.topMargin: 8
                    anchors.right: playerBtn.right
                    width: Math.max(120, playerBtn.width)
                    implicitHeight: contentCol.implicitHeight + 8
                    color: "#1a1b26"
                    radius: 6
                    border.color: "#292e42"
                    border.width: 1
                    
                    ColumnLayout {
                        id: contentCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 4
                        spacing: 2
                        
                        Repeater {
                            model: Players.list
                            Rectangle {
                                required property var modelData
                                
                                Layout.fillWidth: true
                                implicitHeight: 28
                                color: playerHover.hovered ? "#292e42" : "transparent"
                                radius: 4
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: Players.getIdentity(modelData)
                                    color: Players.active === modelData ? "#bb9af7" : "#c0caf5"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }
                                
                                HoverHandler { id: playerHover }
                                TapHandler {
                                    onTapped: {
                                        Players.manualActive = modelData;
                                        playerDropdown.visible = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: root.formatTime(Players.active?.position ?? 0)
                color: "#565f89"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
            }
            Slider {
                id: progressSlider
                Layout.fillWidth: true
                from: 0
                to: Math.max(1, Players.active?.length ?? 1)
                enabled: Players.active?.canSeek ?? false
                property real phase: 0
                NumberAnimation on phase {
                    running: Players.active?.isPlaying ?? false
                    loops: Animation.Infinite
                    from: 0
                    to: Math.PI * 2
                    duration: 1000
                }
                Binding {
                    target: progressSlider
                    property: "value"
                    value: Players.active?.position ?? 0
                    when: !progressSlider.pressed
                }
                background: Item {
                    x: progressSlider.leftPadding
                    y: progressSlider.topPadding
                    width: progressSlider.availableWidth
                    height: progressSlider.availableHeight
                    Canvas {
                        id: canvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var filledWidth = width * progressSlider.visualPosition;
                            
                            ctx.beginPath();
                            ctx.lineWidth = 4;
                            ctx.strokeStyle = "#7aa2f7";
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            
                            var amp = 4;
                            var freq = 0.1;
                            for (var x = 0; x <= filledWidth; x += 2) {
                                var y = height / 2 + Math.sin(x * freq - progressSlider.phase) * amp;
                                if (x === 0) ctx.moveTo(x, y);
                                else ctx.lineTo(x, y);
                            }
                            ctx.stroke();

                            if (filledWidth < width) {
                                ctx.beginPath();
                                ctx.lineWidth = 4;
                                ctx.strokeStyle = "#292e42";
                                ctx.moveTo(filledWidth, height / 2);
                                ctx.lineTo(width, height / 2);
                                ctx.stroke();
                            }
                        }
                        Connections {
                            target: progressSlider
                            function onPhaseChanged() { canvas.requestPaint(); }
                            function onVisualPositionChanged() { canvas.requestPaint(); }
                        }
                    }
                }
                handle: Rectangle {
                    x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                    y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: 6
                    color: progressSlider.pressed ? "#bb9af7" : "#7aa2f7"
                }
                onMoved: {
                    if (Players.active)
                        Players.active.position = value;
                }
            }
            Text {
                text: root.formatTime(Players.active?.length ?? 0)
                color: "#565f89"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
            }
        }

        Item {
            width: parent.width
            implicitHeight: 48
            RowLayout {
                anchors.centerIn: parent
                spacing: 24
                Text {
                    text: "󰒝"
                    color: Players.active?.shuffle ? "#bb9af7" : (hoverShuffle.hovered ? "#c0caf5" : "#7aa2f7")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 20
                    opacity: Players.active?.shuffleSupported ? 1 : 0.5
                    HoverHandler {
                        id: hoverShuffle
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            if (Players.active && Players.active.shuffleSupported)
                                Players.active.shuffle = !Players.active.shuffle;
                        }
                    }
                }
                Text {
                    text: "󰒮"
                    color: hoverPrev.hovered ? "#bb9af7" : "#7aa2f7"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 24
                    opacity: Players.active?.canGoPrevious ? 1 : 0.5
                    HoverHandler {
                        id: hoverPrev
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: Players.active?.previous()
                    }
                }
                Rectangle {
                    implicitWidth: 48
                    implicitHeight: 48
                    radius: 24
                    color: hoverPlay.hovered ? "#bb9af7" : "#7aa2f7"
                    Text {
                        anchors.centerIn: parent
                        text: Players.active?.isPlaying ? "󰏤" : "󰐊"
                        color: "#1a1b26"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 28
                        anchors.horizontalCenterOffset: Players.active?.isPlaying ? 0 : 2
                    }
                    HoverHandler {
                        id: hoverPlay
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: Players.active?.togglePlaying()
                    }
                }
                Text {
                    text: "󰒭"
                    color: hoverNext.hovered ? "#bb9af7" : "#7aa2f7"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 24
                    opacity: Players.active?.canGoNext ? 1 : 0.5
                    HoverHandler {
                        id: hoverNext
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: Players.active?.next()
                    }
                }
                Text {
                    text: Players.active?.loopState === 1 ? "󰑘" : "󰑖"
                    color: Players.active?.loopState !== 0 ? "#bb9af7" : (hoverLoop.hovered ? "#c0caf5" : "#7aa2f7")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 20
                    opacity: Players.active?.loopSupported ? 1 : 0.5
                    HoverHandler {
                        id: hoverLoop
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            if (!Players.active || !Players.active.loopSupported) return;
                            const s = Players.active.loopState;
                            Players.active.loopState = s === 0 ? 2 : (s === 2 ? 1 : 0);
                        }
                    }
                }
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "󰦨"
                color: hoverLyrics.hovered || root.showLyrics ? "#bb9af7" : "#7aa2f7"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 24
                opacity: Lyrics.hasLyrics ? 1 : 0.5
                HoverHandler {
                    id: hoverLyrics
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: {
                        const p = Players.active;
                        if (!p)
                            return;
                        if (Lyrics.trackTitle === p.trackTitle && Lyrics.trackArtist === p.trackArtist && Lyrics.trackTitle !== "")
                            root.showLyrics = !root.showLyrics;
                        else
                            root.updateLyrics();
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Lyrics.hasLyrics ? 340 : 40
            Layout.preferredHeight: Lyrics.hasLyrics ? 340 : 40
            color: "transparent"
            radius: 10
            clip: true
            visible: root.showLyrics
            Text {
                anchors.centerIn: parent
                text: Lyrics.loading ? "Loading lyrics..." : (Lyrics.hasLyrics ? "" : "No lyrics available")
                color: "#565f89"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }
            ListView {
                id: lyricsList
                anchors.fill: parent
                anchors.margins: 12
                model: Lyrics.lyrics
                spacing: 12
                visible: Lyrics.hasLyrics
                Component.onCompleted: {
                    currentIndex = Qt.binding(() => Lyrics.indexForTime(Players.active?.position ?? 0));
                }
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Center)
                preferredHighlightBegin: height / 2 - 10
                preferredHighlightEnd: height / 2 + 10
                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: 300
                delegate: Text {
                    width: lyricsList.width
                    text: modelData || ". . ."
                    color: ListView.isCurrentItem ? "#7aa2f7" : mouse.containsMouse ? "#c0caf5" : "#565f89"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: ListView.isCurrentItem ? 15 : 13
                    font.bold: ListView.isCurrentItem
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on font.pixelSize {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Players.active)
                                Players.active.position = Lyrics.timeForIndex(index);
                        }
                    }
                }
            }
        }
    }

    function formatTime(microsecs: real): string {
        if (microsecs < 0)
            return "0:00";
        let secs = Math.floor(microsecs / 1000000);
        let mins = Math.floor(secs / 60);
        secs = secs % 60;
        return mins + ":" + secs.toString().padStart(2, "0");
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: 100
        repeat: true
        onTriggered: {
            if (Players.active)
                Players.active.positionChanged();
        }
    }
}
