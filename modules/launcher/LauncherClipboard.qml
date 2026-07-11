import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ListView {
    id: clipboardList
    property string query: ""
    property var loadedData: []
    signal action()

    clip: true
    verticalLayoutDirection: ListView.TopToBottom
    readonly property int itemH: 64
    readonly property int maxItems: 6
    implicitHeight: Math.min(count, maxItems) * itemH
    spacing: 0
    currentIndex: 0
    onCountChanged: currentIndex = 0

    Process {
        running: true
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const result = [];
                for (const line of lines) {
                    if (line.trim().length > 0) {
                        const idx = line.indexOf("\t");
                        if (idx > -1) {
                            const idStr = line.substring(0, idx);
                            const content = line.substring(idx + 1);
                            const isImage = content.startsWith("[[ binary data");
                            result.push({ id: idStr, content: content, raw: line, isImage: isImage });
                        }
                    }
                }
                clipboardList.loadedData = result;
            }
        }
    }

    function fuzzyScore(content, q) {
        if (!content) return -1;
        const ql = q.toLowerCase();
        const cl = content.toLowerCase();

        if (cl === ql) return 1000;
        if (cl.startsWith(ql)) return 900;
        if (cl.includes(ql)) return 800;
        
        return -1;
    }

    model: {
        const q = clipboardList.query;
        if (!q) return clipboardList.loadedData;
        return clipboardList.loadedData.map(item => ({ item: item, score: fuzzyScore(item.content, q) }))
                  .filter(x => x.score >= 0)
                  .sort((x, y) => y.score - x.score)
                  .map(x => x.item);
    }

    function handleUp() { if (count > 0) { if (currentIndex <= 0) currentIndex = count - 1; else decrementCurrentIndex(); } }
    function handleDown() { if (count > 0) { if (currentIndex >= count - 1) currentIndex = 0; else incrementCurrentIndex(); } }
    function handleReturn() { const item = currentItem; if (item) item.activate(); }

    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#3b4261" } }
    highlight: Rectangle { radius: 8; color: Qt.rgba(0x7a/255, 0xa2/255, 0xf7/255, 0.12); width: clipboardList.width }
    highlightFollowsCurrentItem: true
    highlightMoveDuration: 80

    delegate: Item {
        id: delRoot
        required property var modelData
        required property int index
        width: clipboardList.width
        height: clipboardList.itemH

        property bool imageReady: false

        Process {
            id: decodeProc
            running: delRoot.modelData.isImage
            command: ["sh", "-c", "mkdir -p /tmp/hebi-cliphist && echo \"$1\" | cliphist decode > /tmp/hebi-cliphist/$2.png", "--", delRoot.modelData.raw, delRoot.modelData.id]
            onExited: {
                if (exitCode === 0) {
                    delRoot.imageReady = true;
                }
            }
        }

        function activate() {
            clipboardList.action();
            Quickshell.execDetached(["sh", "-c", "echo \"$1\" | cliphist decode | wl-copy", "--", modelData.raw]);
        }

        function deleteItem() {
            Quickshell.execDetached(["sh", "-c", "echo \"$1\" | cliphist delete", "--", modelData.raw]);
            const newData = clipboardList.loadedData.filter(item => item.id !== modelData.id);
            clipboardList.loadedData = newData;
        }

        HoverHandler { id: hoverHandler; cursorShape: Qt.PointingHandCursor }
        TapHandler { 
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onTapped: (eventPoint) => { 
                if (eventPoint.button === Qt.RightButton) {
                    delRoot.deleteItem();
                } else {
                    clipboardList.currentIndex = delRoot.index; 
                    delRoot.activate(); 
                }
            } 
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 14

            Item {
                width: 48
                height: 48
                Layout.alignment: Qt.AlignVCenter

                Text { 
                    anchors.centerIn: parent
                    text: delRoot.modelData.isImage ? "󰋩" : "󰅌"
                    color: "#565f89"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                    visible: !delRoot.imageReady
                }

                Image {
                    anchors.fill: parent
                    source: delRoot.imageReady ? "file:///tmp/hebi-cliphist/" + delRoot.modelData.id + ".png" : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: delRoot.imageReady
                    layer.enabled: true
                    layer.effect: ShaderEffect {
                        fragmentShader: "
                            varying highp vec2 qt_TexCoord0;
                            uniform sampler2D source;
                            void main() {
                                vec2 uv = qt_TexCoord0;
                                // simple rounded corners using distance
                                vec2 center = vec2(0.5, 0.5);
                                vec2 dist = abs(uv - center);
                                if (dist.x > 0.4 && dist.y > 0.4) {
                                    float cornerDist = length(dist - vec2(0.4, 0.4));
                                    if (cornerDist > 0.1) discard;
                                }
                                gl_FragColor = texture2D(source, qt_TexCoord0);
                            }
                        "
                    }
                }
                
                // Add a gentle border for images
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "#3b4261"
                    border.width: 1
                    radius: 4
                    visible: delRoot.imageReady
                }
            }

            Text { 
                text: delRoot.modelData.content; 
                color: (clipboardList.currentIndex === delRoot.index || hoverHandler.hovered) ? "#7aa2f7" : "#c0caf5"; 
                font.family: "Inter, JetBrainsMono Nerd Font"; 
                font.pixelSize: 13; 
                elide: Text.ElideRight; 
                Layout.fillWidth: true; 
                Layout.alignment: Qt.AlignVCenter 
            }
            Text { 
                text: delRoot.modelData.id; 
                color: "#565f89"; 
                font.family: "Inter"; 
                font.pixelSize: 11; 
                Layout.alignment: Qt.AlignVCenter 
            }
        }
    }
}
