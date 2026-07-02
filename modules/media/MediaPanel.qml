pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Hebi.Blobs
import Hebi.Services
import "../../services"

PanelWindow {
    id: root

    property bool panelVisible: false
    property bool showLyrics: false

    IpcHandler {
        target: "media"
        function toggle(): void {
            root.panelVisible = !root.panelVisible;
        }
        function open(): void {
            root.panelVisible = true;
        }
        function close(): void {
            root.panelVisible = false;
        }
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
            if (!Lyrics.loading && Lyrics.trackTitle !== "") {
                // Automatically open panel when fetching finishes (whether success or fail)
                root.showLyrics = true;
            }
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
        function onActiveChanged() { root.updateLyrics(); }
    }

    Component.onCompleted: root.updateLyrics()

    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: false

    // Window spans entire width and 800px height, but does NOT push windows (exclusiveZone: 0)
    implicitHeight: 800
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: panelVisible ? activeRegion : emptyRegion
    Region { id: emptyRegion }
    Region {
        id: activeRegion
        x: contentWrapper.x
        y: contentWrapper.y
        width: contentWrapper.width
        height: contentWrapper.height
    }

    BlobGroup {
        id: bgGroup
        color: Theme.surface
    }

    Item {
        id: container
        anchors.fill: parent

        BlobRect {
            id: panelBg
            group: bgGroup

            // Center of the Media widget from the right edge of the screen
            property real mediaCenterRight: Players.mediaCenterRightOffset

            property real closedW: 150
            property real closedH: 28
            property real closedX: root.width - mediaCenterRight - (closedW / 2)
            property real closedY: 0

            property real openW: 392
            // Height expands fully only when lyrics are fetched, otherwise just enough for the single line message
            property real openH: root.showLyrics ? (Lyrics.hasLyrics ? 620 : 320) : 260
            property real openX: root.width - mediaCenterRight - (openW / 2)
            property real openY: -20

            x: root.panelVisible ? openX : closedX
            y: root.panelVisible ? openY : closedY
            width: root.panelVisible ? openW : closedW
            height: root.panelVisible ? openH : closedH
            radius: root.panelVisible ? 20 : 10

            stiffness: 200
            damping: 18
            deformScale: 0.004

            opacity: root.panelVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on x { NumberAnimation { duration: 320; easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic } }
            Behavior on y { NumberAnimation { duration: 320; easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic } }
            Behavior on width { NumberAnimation { duration: 320; easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic } }
            Behavior on height { NumberAnimation { duration: 320; easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic } }
            Behavior on radius { NumberAnimation { duration: 320; easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic } }
        }



        Item {
            id: contentWrapper
            x: panelBg.x
            y: panelBg.y
            width: panelBg.width
            height: panelBg.height
            clip: true
            
            ColumnLayout {
                id: contentArea
                width: 360
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: 20
                anchors.topMargin: 32
                spacing: 20
                opacity: root.panelVisible ? 1 : 0
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: root.panelVisible ? 300 : 0
                        }
                        NumberAnimation {
                            duration: root.panelVisible ? 180 : 80
                            easing.type: Easing.OutCubic
                        }
                    }
                }


                // Album Art & Details
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
                }

                // Progress Bar
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
                        
                        Binding {
                            target: progressSlider
                            property: "value"
                            value: Players.active?.position ?? 0
                            when: !progressSlider.pressed
                        }
                        
                        background: Rectangle {
                            x: progressSlider.leftPadding
                            y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: progressSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#292e42"
                            
                            Rectangle {
                                width: progressSlider.visualPosition * parent.width
                                height: parent.height
                                color: "#7aa2f7"
                                radius: 2
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
                            if (Players.active) Players.active.position = value;
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
                            text: "󰒮"
                            color: hoverPrev.hovered ? "#bb9af7" : "#7aa2f7"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 24
                            opacity: Players.active?.canGoPrevious ? 1 : 0.5
                            HoverHandler { id: hoverPrev; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Players.active?.previous() }
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
                            HoverHandler { id: hoverPlay; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Players.active?.togglePlaying() }
                        }

                        Text {
                            text: "󰒭"
                            color: hoverNext.hovered ? "#bb9af7" : "#7aa2f7"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 24
                            opacity: Players.active?.canGoNext ? 1 : 0.5
                            HoverHandler { id: hoverNext; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Players.active?.next() }
                        }
                    }

                    // Lyrics toggle button
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰦨" // text icon
                        color: hoverLyrics.hovered || root.showLyrics ? "#bb9af7" : "#7aa2f7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 24 // Match size of other controls
                        opacity: Lyrics.hasLyrics ? 1 : 0.5
                        HoverHandler { id: hoverLyrics; cursorShape: Qt.PointingHandCursor }
                        TapHandler { 
                            onTapped: {
                                const p = Players.active;
                                if (!p) return;
                                
                                if (Lyrics.trackTitle === p.trackTitle && Lyrics.trackArtist === p.trackArtist && Lyrics.trackTitle !== "") {
                                    // Already fetched or attempted for this track, just toggle visibility
                                    root.showLyrics = !root.showLyrics;
                                } else {
                                    // First time clicking for this track, attempt to fetch!
                                    // The panel will auto-open when fetching finishes via onLoadingChanged
                                    root.updateLyrics();
                                }
                            } 
                        }
                    }
                }

                // Lyrics
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
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                            
                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Players.active) {
                                        Players.active.position = Lyrics.timeForIndex(index);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    function formatTime(microsecs: real): string {
        if (microsecs < 0) return "0:00";
        let secs = Math.floor(microsecs / 1000000);
        let mins = Math.floor(secs / 60);
        secs = secs % 60;
        return mins + ":" + secs.toString().padStart(2, '0');
    }
    
    Timer {
        running: Players.active?.isPlaying ?? false
        interval: 100
        repeat: true
        onTriggered: {
            if (Players.active) {
                // This triggers position binding updates
                Players.active.positionChanged();
            }
        }
    }
}
