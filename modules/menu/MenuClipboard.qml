pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: clipboardRoot
    property string query: ""
    property var loadedData: []
    signal action()

    readonly property int itemH: 48
    readonly property int maxItems: 8
    implicitHeight: maxItems * itemH
    
    Process {
        id: cliphistList
        command: ["cliphist", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const result = [];
                for (const line of lines) {
                    if (!line) continue;
                    const tabIdx = line.indexOf("\t");
                    if (tabIdx === -1) continue;
                    const id = line.slice(0, tabIdx);
                    const data = line.slice(tabIdx + 1);
                    const isImage = data.startsWith("[[ binary data") && data.includes("png");
                    result.push({ id, data, isImage });
                }
                clipboardRoot.loadedData = result;
                if (result.length > 0 && clipList.currentIndex >= result.length) {
                    clipList.currentIndex = 0;
                }
            }
        }
    }
    
    onVisibleChanged: {
        if (visible) {
            cliphistList.running = true;
        }
    }

    function fuzzyScore(name, q) {
        const ql = q.toLowerCase();
        if (!name) return -1;
        const nl = name.toLowerCase();

        if (nl === ql) return 1000;
        if (nl.startsWith(ql)) return 900;
        if (nl.includes(ql)) return 800;

        let qIdx = 0;
        let lastMatch = -1;
        let score = 0;
        for (let i = 0; i < nl.length && qIdx < ql.length; i++) {
            if (nl[i] === ql[qIdx]) {
                if (lastMatch === i - 1) score += 10;
                score += (100 - i);
                lastMatch = i;
                qIdx++;
            }
        }
        if (qIdx === ql.length) return 100 + score;
        return -1;
    }
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        ListView {
            id: clipList
            Layout.preferredWidth: parent.width * 0.35
            Layout.maximumWidth: parent.width * 0.35
            Layout.fillHeight: true
            clip: true
            verticalLayoutDirection: ListView.BottomToTop
            
            model: {
                const q = clipboardRoot.query;
                if (!q) return clipboardRoot.loadedData;
                return clipboardRoot.loadedData.map(c => ({ c: c, score: clipboardRoot.fuzzyScore(c.data, q) }))
                        .filter(x => x.score >= 0)
                        .sort((x, y) => y.score - x.score)
                        .map(x => x.c);
            }
            
            currentIndex: 0
            onCountChanged: currentIndex = 0
            
            onCurrentIndexChanged: {
                previewLoader.updatePreview();
            }

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 2; radius: 1; color: "#3b4261"; opacity: 0.6 } }
            highlight: Rectangle { radius: 8; color: Qt.rgba(0x7a/255, 0xa2/255, 0xf7/255, 0.12); width: clipList.width }
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 80

            delegate: Item {
                id: delRoot
                required property var modelData
                required property int index
                width: clipList.width
                height: clipboardRoot.itemH

                function activate() {
                    clipboardRoot.action();
                    Quickshell.execDetached(["sh", "-c", "echo -n '" + modelData.id + "' | cliphist decode | wl-copy"]);
                }

                HoverHandler { id: hoverHandler; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: { clipList.currentIndex = delRoot.index; delRoot.activate(); } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 14

                    Text { 
                        text: delRoot.modelData.isImage ? "" : "󱘢"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter 
                        color: (clipList.currentIndex === delRoot.index || hoverHandler.hovered) ? "#7aa2f7" : "#565f89"
                    }
                    Text { 
                        text: delRoot.modelData.data 
                        color: (clipList.currentIndex === delRoot.index || hoverHandler.hovered) ? "#7aa2f7" : "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                        clip: true
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter 
                    }
                }
            }
        }
        
        // Right side preview
        Rectangle {
            Layout.preferredWidth: parent.width * 0.65
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.2)
            
            Item {
                id: previewLoader
                anchors.fill: parent
                anchors.margins: 10
                
                property var currentItemData: clipList.count > 0 ? clipList.model[clipList.currentIndex] : null
                property string previewText: ""
                property string previewImage: ""
                
                onCurrentItemDataChanged: {
                    updatePreview();
                }
                
                function updatePreview() {
                    if (!currentItemData) {
                        previewText = "";
                        previewImage = "";
                        return;
                    }
                    
                    if (currentItemData.isImage) {
                        previewText = "";
                        imageDecodeProcess.command = ["sh", "-c", "echo -n '" + currentItemData.id + "' | cliphist decode > /tmp/hebi-cliphist-preview.png"];
                        imageDecodeProcess.running = true;
                    } else {
                        previewImage = "";
                        textDecodeProcess.command = ["sh", "-c", "echo -n '" + currentItemData.id + "' | cliphist decode"];
                        textDecodeProcess.running = true;
                    }
                }
                
                Process {
                    id: imageDecodeProcess
                    stdout: StdioCollector {
                        onStreamFinished: {
                            previewLoader.previewImage = "file:///tmp/hebi-cliphist-preview.png?t=" + Date.now();
                        }
                    }
                }
                
                Process {
                    id: textDecodeProcess
                    stdout: StdioCollector {
                        onStreamFinished: {
                            previewLoader.previewText = text;
                        }
                    }
                }
                
                ScrollView {
                    anchors.fill: parent
                    visible: previewLoader.currentItemData && !previewLoader.currentItemData.isImage
                    clip: true
                    TextArea {
                        text: previewLoader.previewText
                        readOnly: true
                        color: "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        background: null
                    }
                }
                
                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    visible: previewLoader.currentItemData && previewLoader.currentItemData.isImage
                    source: previewLoader.previewImage
                }
            }
        }
    }

    function handleUp() { if (clipList.count > 0) { if (clipList.currentIndex >= clipList.count - 1) clipList.currentIndex = 0; else clipList.incrementCurrentIndex(); } }
    function handleDown() { if (clipList.count > 0) { if (clipList.currentIndex <= 0) clipList.currentIndex = clipList.count - 1; else clipList.decrementCurrentIndex(); } }
    function handleReturn() { const item = clipList.currentItem; if (item) item.activate(); }
    
    function handleDelete() {
        if (clipList.count === 0) return;
        const id = clipList.model[clipList.currentIndex].id;
        Quickshell.execDetached(["sh", "-c", "echo -n '" + id + "' | cliphist delete"]);
        // slight delay to let cliphist delete before reloading
        refreshTimer.start();
    }
    
    Timer {
        id: refreshTimer
        interval: 100
        repeat: false
        onTriggered: cliphistList.running = true
    }
}
