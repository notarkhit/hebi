pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
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
    property bool showBongoCat: false
    readonly property real panelWidth: 440
    readonly property real currentHeight: implicitHeight

    implicitWidth: panelWidth
    implicitHeight: Players.active ? (showLyrics ? (Lyrics.hasLyrics ? 620 : 320) : 260) : 260
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

    property var _lyricsUpdater: {
        const p = Players.active;
        if (p) {
            Lyrics.setTrack(p.trackArtist || "", p.trackTitle || "", p.trackAlbum || "", p.length || 0);
        } else {
            Lyrics.clearTrack();
        }
        return null;
    }

    Connections {
        target: Lyrics
        function onLoadingChanged() {
            if (!Lyrics.loading && Lyrics.trackTitle !== "" && Lyrics.hasLyrics) {
                root.showLyrics = true;
            }
        }
    }

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
        id: contentLayout
        opacity: Players.active ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        anchors.topMargin: 24
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Item {
                width: 176
                height: 176
                Layout.preferredWidth: 176
                Layout.preferredHeight: 176

                CavaProvider {
                    id: cava
                    bars: 40
                }

                ServiceRef {
                    service: cava
                }

                Shape {
                    id: visualizerShape
                    anchors.fill: parent
                    asynchronous: true
                    preferredRendererType: Shape.CurveRenderer
                    data: bars.instances
                }

                Variants {
                    id: bars
                    model: Array.from({
                        length: cava.bars
                    }, (_, i) => i)

                    ShapePath {
                        id: barShape
                        required property int modelData

                        readonly property var vals: cava.values
                        readonly property real rawVal: vals[modelData] !== undefined ? vals[modelData] : 0.0
                        readonly property real value: Math.max(0.01, Math.min(1.0, rawVal))
                        readonly property real punchyValue: Math.pow(value, 0.6) // Boosts smaller values for a more aggressive look
                        readonly property real angle: modelData * 2 * Math.PI / cava.bars

                        readonly property real coverRadius: 56
                        readonly property real barDistance: coverRadius + 4
                        readonly property real barHeight: punchyValue * 24 // Doubled the max height

                        readonly property real cosA: Math.cos(angle)
                        readonly property real sinA: Math.sin(angle)

                        strokeColor: Theme.warning
                        strokeWidth: 3
                        capStyle: ShapePath.RoundCap

                        startX: visualizerShape.width / 2 + barDistance * cosA
                        startY: visualizerShape.height / 2 + barDistance * sinA

                        PathLine {
                            x: visualizerShape.width / 2 + (barDistance + barHeight) * cosA
                            y: visualizerShape.height / 2 + (barDistance + barHeight) * sinA
                        }
                    }
                }

                Rectangle {
                    id: coverMask
                    width: 112
                    height: 112
                    radius: 56
                    visible: false
                    layer.enabled: true
                }

                Image {
                    id: cover
                    anchors.centerIn: parent
                    width: 112
                    height: 112
                    source: Players.active ? Players.getArtUrl(Players.active) : ""
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: coverMask
                    }
                    opacity: root.showBongoCat ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    color: Theme.subtext
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 32
                    visible: cover.source === ""
                    opacity: root.showBongoCat ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                        }
                    }
                }

                AnimatedImage {
                    id: bongocat
                    anchors.centerIn: parent
                    width: 112
                    height: 112
                    playing: Players.active?.isPlaying ?? false
                    source: "file://" + Quickshell.env("HOME") + "/.config/hebi/assets/bongocat.gif"
                    fillMode: AnimatedImage.PreserveAspectFit
                    opacity: root.showBongoCat ? (Players.active ? 1 : 0.5) : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                        }
                    }
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: coverMask
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showBongoCat = !root.showBongoCat
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 20
                    clip: true
                    Text {
                        id: titleText
                        text: Players.active?.trackTitle || "No Media Playing"
                        color: Theme.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.bold: true

                        anchors.verticalCenter: parent.verticalCenter
                        x: implicitWidth > parent.width ? marqueeAnimTitle.xPos : (parent.width - implicitWidth) / 2

                        SequentialAnimation {
                            id: marqueeAnimTitle
                            property real xPos: 0
                            running: titleText.implicitWidth > titleText.parent.width
                            loops: Animation.Infinite

                            PauseAnimation {
                                duration: 1500
                            }
                            NumberAnimation {
                                target: marqueeAnimTitle
                                property: "xPos"
                                from: 0
                                to: Math.min(0, -(titleText.implicitWidth - titleText.parent.width))
                                duration: Math.max(1, titleText.implicitWidth - titleText.parent.width) * 30
                            }
                            PauseAnimation {
                                duration: 1500
                            }
                            NumberAnimation {
                                target: marqueeAnimTitle
                                property: "xPos"
                                to: 0
                                duration: Math.max(1, titleText.implicitWidth - titleText.parent.width) * 30
                            }
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 18
                    clip: true
                    Text {
                        id: artistText
                        text: Players.active?.trackArtist || "Unknown Artist"
                        color: Theme.secondary
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13

                        anchors.verticalCenter: parent.verticalCenter
                        x: implicitWidth > parent.width ? marqueeAnimArtist.xPos : (parent.width - implicitWidth) / 2

                        SequentialAnimation {
                            id: marqueeAnimArtist
                            property real xPos: 0
                            running: artistText.implicitWidth > artistText.parent.width
                            loops: Animation.Infinite

                            PauseAnimation {
                                duration: 1500
                            }
                            NumberAnimation {
                                target: marqueeAnimArtist
                                property: "xPos"
                                from: 0
                                to: Math.min(0, -(artistText.implicitWidth - artistText.parent.width))
                                duration: Math.max(1, artistText.implicitWidth - artistText.parent.width) * 30
                            }
                            PauseAnimation {
                                duration: 1500
                            }
                            NumberAnimation {
                                target: marqueeAnimArtist
                                property: "xPos"
                                to: 0
                                duration: Math.max(1, artistText.implicitWidth - artistText.parent.width) * 30
                            }
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 24
                        Text {
                            text: "󰒮"
                            color: hoverPrev.hovered ? Theme.warning : Theme.accent
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
                            color: hoverPlay.hovered ? Theme.warning : Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: Players.active?.isPlaying ? "󰏤" : "󰐊"
                                color: Theme.surfaceHex
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
                            color: hoverNext.hovered ? Theme.warning : Theme.accent
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
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: root.formatTime(Players.active?.position ?? 0)
                        color: Theme.subtext
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
                                    ctx.strokeStyle = Theme.accent;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";

                                    var amp = 4;
                                    var freq = 0.1;
                                    for (var x = 0; x <= filledWidth; x += 2) {
                                        var y = height / 2 + Math.sin(x * freq - progressSlider.phase) * amp;
                                        if (x === 0)
                                            ctx.moveTo(x, y);
                                        else
                                            ctx.lineTo(x, y);
                                    }
                                    ctx.stroke();

                                    if (filledWidth < width) {
                                        ctx.beginPath();
                                        ctx.lineWidth = 4;
                                        ctx.strokeStyle = Theme.surfaceVariant;
                                        ctx.moveTo(filledWidth, height / 2);
                                        ctx.lineTo(width, height / 2);
                                        ctx.stroke();
                                    }
                                }
                                Connections {
                                    target: progressSlider
                                    function onPhaseChanged() {
                                        canvas.requestPaint();
                                    }
                                    function onVisualPositionChanged() {
                                        canvas.requestPaint();
                                    }
                                }
                            }
                        }
                        handle: Rectangle {
                            x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                            y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                            implicitWidth: 12
                            implicitHeight: 12
                            radius: 6
                            color: progressSlider.pressed ? Theme.warning : Theme.accent
                        }
                        onMoved: {
                            if (Players.active)
                                Players.active.position = value;
                        }
                    }
                    Text {
                        text: root.formatTime(Players.active?.length ?? 0)
                        color: Theme.subtext
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    z: 100
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 16

                        // Shuffle
                        Text {
                            text: "󰒝"
                            color: Players.active?.shuffle ? Theme.warning : (hoverShuffle.hovered ? Theme.text : Theme.accent)
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

                        // Lyrics
                        Text {
                            text: "󰦨"
                            font.pixelSize: 24
                            opacity: Lyrics.hasLyrics ? 1 : 0.5
                            HoverHandler {
                                id: hoverLyrics
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: root.showLyrics = !root.showLyrics
                            }
                        }

                        // Player Pill
                        Item {
                            id: playerSwitcherItem
                            implicitWidth: playerBtn.implicitWidth
                            implicitHeight: 28
                            visible: Players.list.length > 0
                            z: 100

                            property bool dropdownVisible: false

                            Row {
                                id: playerBtn
                                anchors.centerIn: parent
                                spacing: 1 // Tiny gap to look like a single button

                                Rectangle {
                                    id: leftPill
                                    width: textRow.implicitWidth + 24
                                    height: 28
                                    color: hoverBtn.hovered ? Theme.surfaceVariant : Theme.surfaceHex
                                    radius: 14
                                    topRightRadius: 2 // Joined inner radius
                                    bottomRightRadius: 2

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    RowLayout {
                                        id: textRow
                                        anchors.centerIn: parent
                                        anchors.horizontalCenterOffset: 2
                                        spacing: 6
                                        Text {
                                            text: Players.active ? "󰎆" : "󰝛"
                                            color: Theme.accent
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 14
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                        Text {
                                            text: Players.active ? Players.getIdentity(Players.active) : "No Players"
                                            color: Theme.accent
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 12
                                            font.bold: true
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.maximumWidth: 100
                                            elide: Text.ElideRight
                                        }
                                    }

                                    HoverHandler {
                                        id: hoverBtn
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    TapHandler {
                                        onTapped: {
                                            if (playerSwitcherItem.dropdownVisible) {
                                                playerSwitcherItem.dropdownVisible = false;
                                            }
                                            const list = Players.list;
                                            if (list.length > 1) {
                                                const idx = list.indexOf(Players.active);
                                                const nextIdx = (idx + 1) % list.length;
                                                Players.manualActive = list[nextIdx];
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: rightPill
                                    width: 32
                                    height: 28
                                    color: hoverExpand.hovered ? Theme.surfaceVariant : Theme.surfaceHex
                                    radius: 14
                                    // Animate to full radius when clicked to visually "split" the button!
                                    topLeftRadius: playerSwitcherItem.dropdownVisible ? 14 : 2
                                    bottomLeftRadius: playerSwitcherItem.dropdownVisible ? 14 : 2

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on topLeftRadius {
                                        NumberAnimation {
                                            duration: 250
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on bottomLeftRadius {
                                        NumberAnimation {
                                            duration: 250
                                            easing.type: Easing.OutBack
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀" // mdi-chevron-down
                                        color: Theme.accent
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 16
                                        rotation: playerSwitcherItem.dropdownVisible ? 180 : 0
                                        Behavior on rotation {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.OutQuint
                                            }
                                        }
                                    }

                                    HoverHandler {
                                        id: hoverExpand
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    TapHandler {
                                        onTapped: {
                                            if (playerSwitcherItem.dropdownVisible) {
                                                playerSwitcherItem.dropdownVisible = false;
                                            } else {
                                                const mappedPos = rightPill.mapToItem(globalClickCatcher, 0, 0);
                                                // Attach to the expand button like in env/shell
                                                playerDropdown.x = mappedPos.x - (playerDropdown.width - rightPill.width);
                                                playerDropdown.y = mappedPos.y + rightPill.height + 6;
                                                playerSwitcherItem.dropdownVisible = true;
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: globalClickCatcher
                                parent: QsWindow.window ? QsWindow.window.contentItem : root
                                anchors.fill: parent
                                enabled: playerSwitcherItem.dropdownVisible
                                visible: playerSwitcherItem.dropdownVisible
                                hoverEnabled: true
                                onClicked: playerSwitcherItem.dropdownVisible = false
                                z: 999

                                Rectangle {
                                    id: playerDropdown

                                    width: Math.max(140, playerBtn.width)
                                    height: contentCol.implicitHeight + 16

                                    opacity: playerSwitcherItem.dropdownVisible ? 1 : 0

                                    transform: Scale {
                                        origin.y: 0
                                        yScale: playerSwitcherItem.dropdownVisible ? 1 : 0.1
                                        Behavior on yScale {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.OutQuint
                                            }
                                        }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }

                                    color: Theme.surfaceHex
                                    radius: 12
                                    border.color: Theme.surfaceVariant
                                    border.width: 1

                                    // Prevent closing when clicking inside the dropdown menu itself
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {}
                                    }

                                    ColumnLayout {
                                        id: contentCol
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: 8
                                        spacing: 4

                                        Repeater {
                                            model: Players.list
                                            Rectangle {
                                                id: playerRectItem
                                                required property var modelData
                                                readonly property bool isActive: Players.active === modelData
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 36
                                                color: playerHoverItem.hovered ? Theme.surfaceVariant : (isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1) : "transparent")
                                                radius: 8

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 12
                                                    spacing: 12

                                                    Text {
                                                        text: playerRectItem.isActive ? "󰄬" : ""
                                                        color: playerRectItem.isActive ? Theme.accent : Theme.subtext
                                                        font.family: "JetBrainsMono Nerd Font"
                                                        font.pixelSize: 16
                                                        Layout.preferredWidth: 16
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }

                                                    Text {
                                                        text: Players.getIdentity(playerRectItem.modelData)
                                                        color: playerRectItem.isActive ? Theme.accent : Theme.secondary
                                                        font.family: "JetBrainsMono Nerd Font"
                                                        font.pixelSize: 13
                                                        Layout.fillWidth: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                        elide: Text.ElideRight
                                                    }
                                                }

                                                HoverHandler {
                                                    id: playerHoverItem
                                                    cursorShape: Qt.PointingHandCursor
                                                }
                                                TapHandler {
                                                    onTapped: {
                                                        Players.manualActive = playerRectItem.modelData;
                                                        playerSwitcherItem.dropdownVisible = false;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Loop
                        Text {
                            text: Players.active?.loopState === 1 ? "󰑘" : "󰑖"
                            color: Players.active?.loopState !== 0 ? Theme.warning : (hoverLoop.hovered ? Theme.text : Theme.accent)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 20
                            opacity: Players.active?.loopSupported ? 1 : 0.5
                            HoverHandler {
                                id: hoverLoop
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: {
                                    if (!Players.active || !Players.active.loopSupported)
                                        return;
                                    const s = Players.active.loopState;
                                    Players.active.loopState = s === 0 ? 2 : (s === 2 ? 1 : 0);
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: lyricsContainer
            Layout.fillWidth: true
            implicitHeight: Lyrics.hasLyrics ? 340 : 40
            Layout.preferredHeight: Lyrics.hasLyrics ? 340 : 40
            color: "transparent"
            radius: 10
            clip: true
            visible: root.showLyrics

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            state: Lyrics.hasLyrics ? "lyrics" : (Lyrics.loading ? "loading" : "empty")

            Text {
                anchors.centerIn: parent
                text: Lyrics.loading ? "Loading lyrics..." : "No lyrics available"
                color: Theme.subtext
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                opacity: (parent.state === "lyrics") ? 0 : 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }
                }
            }
            Rectangle {
                id: lyricsMask
                visible: false
                layer.enabled: true
                width: lyricsList.width
                height: lyricsList.height
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 0.15
                        color: "black"
                    }
                    GradientStop {
                        position: 0.85
                        color: "black"
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }

            ListView {
                id: lyricsList
                anchors.fill: parent
                anchors.margins: 12

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSpreadAtMin: 1
                    maskThresholdMin: 0.5
                    maskSource: lyricsMask
                }

                model: Lyrics.lyrics
                spacing: 12
                opacity: parent.state === "lyrics" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }
                }

                Component.onCompleted: {
                    currentIndex = Qt.binding(() => Lyrics.indexForTime(Players.active?.position || 0));
                }
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Center)
                preferredHighlightBegin: height / 2 - 10
                preferredHighlightEnd: height / 2 + 10
                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: 300
                delegate: Text {
                    width: lyricsList.width
                    text: modelData || ". . ."
                    color: ListView.isCurrentItem ? Theme.accent : mouse.containsMouse ? Theme.text : Theme.subtext
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

    ColumnLayout {
        id: emptyContainer
        anchors.centerIn: parent
        opacity: Players.active ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
        spacing: 12
        Text {
            text: "󰝚"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 64
            color: Theme.accent
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: "Nothing playing"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            color: Theme.text
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: "Play some music to see it here"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: Theme.subtext
            Layout.alignment: Qt.AlignHCenter
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
