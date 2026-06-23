import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

ListView {
    id: appsList
    property string query: ""
    signal action()

    clip: true
    verticalLayoutDirection: ListView.BottomToTop

    readonly property int itemH: 48
    readonly property int maxItems: 8
    implicitHeight: Math.min(count, maxItems) * itemH

    spacing: 0
    currentIndex: 0
    onCountChanged: currentIndex = 0

    function fuzzyScore(app, q) {
        const ql = q.toLowerCase();
        const name = (app.name || "").toLowerCase();
        const generic = (app.genericName || "").toLowerCase();
        const comment = (app.comment || "").toLowerCase();

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

        if (generic.split(/[\s\-_:]+/).includes(ql) || comment.split(/[\s\-_:]+/).includes(ql)) return 550;
        if (generic.includes(ql) || comment.includes(ql)) return 500;
        return -1;
    }

    model: {
        const q = appsList.query;
        const all = DesktopEntries.applications.values;
        if (!q) return [...all].sort((a, b) => a.name.localeCompare(b.name));
        return all.map(a => ({ app: a, score: fuzzyScore(a, q) }))
                  .filter(x => x.score >= 0)
                  .sort((x, y) => y.score !== x.score ? y.score - x.score : x.app.name.localeCompare(y.app.name))
                  .map(x => x.app);
    }

    function handleUp() {
        if (count === 0) return;
        if (currentIndex >= count - 1) currentIndex = 0;
        else incrementCurrentIndex();
    }

    function handleDown() {
        if (count === 0) return;
        if (currentIndex <= 0) currentIndex = count - 1;
        else decrementCurrentIndex();
    }

    function handleReturn() {
        const item = currentItem;
        if (item) item.activate();
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#3b4261" }
    }

    highlight: Rectangle { radius: 8; color: Qt.rgba(0x7a/255, 0xa2/255, 0xf7/255, 0.12); width: appsList.width }
    highlightFollowsCurrentItem: true
    highlightMoveDuration: 80

    delegate: Item {
        id: delRoot
        required property var modelData
        required property int index
        width: appsList.width
        height: appsList.itemH

        function activate() {
            appsList.action();
            Quickshell.execDetached({ command: modelData.command });
        }

        HoverHandler { id: hoverHandler; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: { appsList.currentIndex = delRoot.index; delRoot.activate(); } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            IconImage {
                implicitSize: 28
                source: delRoot.modelData ? Quickshell.iconPath(delRoot.modelData.icon, "application-x-executable") : ""
                asynchronous: true
                Layout.alignment: Qt.AlignVCenter
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Text {
                    text: delRoot.modelData?.name ?? ""
                    color: (appsList.currentIndex === delRoot.index || hoverHandler.hovered) ? "#7aa2f7" : "#c0caf5"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    visible: !!text
                    text: delRoot.modelData?.comment ?? delRoot.modelData?.genericName ?? ""
                    color: "#565f89"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Text {
                visible: delRoot.modelData?.runInTerminal ?? false
                text: ""
                color: "#9ece6a"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
