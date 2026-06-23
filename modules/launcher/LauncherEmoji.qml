import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ListView {
    id: emojiList
    property string query: ""
    property var loadedData: []
    signal action()

    clip: true
    verticalLayoutDirection: ListView.BottomToTop
    readonly property int itemH: 48
    readonly property int maxItems: 8
    implicitHeight: Math.min(count, maxItems) * itemH
    spacing: 0
    currentIndex: 0
    onCountChanged: currentIndex = 0

    Process {
        running: true
        command: ["/home/notarkhit/.local/bin/hebi", "emoji"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const result = [];
                for (const line of lines) {
                    const parts = line.split(" ");
                    if (parts.length > 0) {
                        result.push({ e: parts[0], n: parts.slice(1).join(" "), k: parts.slice(1) });
                    }
                }
                emojiList.loadedData = result;
            }
        }
    }

    function fuzzyScore(name, keywords, q) {
        const ql = q.toLowerCase();
        if (!name) return -1;
        name = name.toLowerCase();

        if (name === ql) return 1000;
        if (name.startsWith(ql)) return 900;
        
        const words = name.split(/[\s\-_:]+/);
        if (words.includes(ql)) return 850;

        if (name.includes(ql)) return 800;

        const initials = words.map(w => w[0] || "").join("");
        if (initials.startsWith(ql)) return 750;
        if (initials.includes(ql)) return 700;

        let qi = 0;
        for (let i = 0; i < name.length && qi < ql.length; i++)
            if (name[i] === ql[qi]) qi++;
        if (qi === ql.length) return 600 - Math.min(name.length - ql.length, 99);

        if (keywords && keywords.some(kw => kw.toLowerCase() === ql)) return 550;
        if (keywords && keywords.some(kw => kw.toLowerCase().includes(ql))) return 500;
        
        return -1;
    }

    model: {
        const q = emojiList.query;
        if (!q) return emojiList.loadedData;
        return emojiList.loadedData.map(em => ({ em: em, score: fuzzyScore(em.n, em.k, q) }))
                  .filter(x => x.score >= 0)
                  .sort((x, y) => y.score - x.score)
                  .map(x => x.em);
    }

    function handleUp() { if (count > 0) { if (currentIndex >= count - 1) currentIndex = 0; else incrementCurrentIndex(); } }
    function handleDown() { if (count > 0) { if (currentIndex <= 0) currentIndex = count - 1; else decrementCurrentIndex(); } }
    function handleReturn() { const item = currentItem; if (item) item.activate(); }

    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#3b4261" } }
    highlight: Rectangle { radius: 8; color: Qt.rgba(0x7a/255, 0xa2/255, 0xf7/255, 0.12); width: emojiList.width }
    highlightFollowsCurrentItem: true
    highlightMoveDuration: 80

    delegate: Item {
        id: delRoot
        required property var modelData
        required property int index
        width: emojiList.width
        height: emojiList.itemH

        function activate() {
            emojiList.action();
            Quickshell.execDetached(["sh", "-c", "wl-copy \"$1\" && sleep 0.4 && wtype -M ctrl -M shift -k v -m shift -m ctrl", "--", modelData.e]);
        }

        HoverHandler { id: hoverHandler; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: { emojiList.currentIndex = delRoot.index; delRoot.activate(); } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 14

            Text { text: delRoot.modelData.e; font.pixelSize: 24; Layout.alignment: Qt.AlignVCenter; renderType: Text.NativeRendering }
            Text { text: delRoot.modelData.n; color: (emojiList.currentIndex === delRoot.index || hoverHandler.hovered) ? "#7aa2f7" : "#c0caf5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter }
            Text { text: "Type"; color: (emojiList.currentIndex === delRoot.index || hoverHandler.hovered) ? "#7aa2f7" : "#3b4261"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; Layout.alignment: Qt.AlignVCenter }
        }
    }
}
