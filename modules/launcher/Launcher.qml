pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

// App launcher — toggle via: qs ipc -p ~/.config/hebi call launcher toggle
// Modes:
//   (default)        → fuzzy app search
//   =<expression>    → calculator  (copies result on Enter)
//   :<query>         → emoji picker (copies emoji on Enter/click)
Scope {
    id: root

    property bool launcherVisible: false
    property bool windowVisible: false

    onLauncherVisibleChanged: {
        if (launcherVisible)
            windowVisible = true;
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.launcherVisible = !root.launcherVisible;
        }
    }

    Loader {
        id: loader
        active: root.windowVisible
        sourceComponent: Component {
            PanelWindow {
                id: overlay

                Connections {
                    target: root
                    function onLauncherVisibleChanged() {
                        if (!root.launcherVisible)
                            closeTimer.restart();
                    }
                }

                Timer {
                    id: closeTimer
                    interval: 280
                    onTriggered: root.windowVisible = false
                }

                readonly property string font: "FiraMono Nerd Font"

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                color: "transparent"

                visible: root.windowVisible
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: root.launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                onVisibleChanged: {
                    if (visible) {
                        searchField.text = "";
                        searchField.forceActiveFocus();
                    }
                }

                // Click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.launcherVisible = false
                }

                // ── launcher card ──────────────────────────────────────────────
                Item {
                    id: card

                    width: 560
                    readonly property int fullHeight: listView.implicitHeight + 56
                    height: fullHeight

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12

                    property real clipHeight: 0

                    Component.onCompleted: {
                        clipHeight = Qt.binding(function () {
                            return root.launcherVisible ? card.fullHeight : 0;
                        });
                    }

                    Behavior on clipHeight {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutQuint
                        }
                    }

                    Item {
                        id: clipMask
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: card.clipHeight
                        clip: true

                        MouseArea {
                            anchors.fill: parent
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: card.fullHeight
                            radius: 14
                            color: Qt.rgba(0x1a / 255, 0x1b / 255, 0x26 / 255, 0.97)
                            border.color: "#3b4261"
                            border.width: 1
                            layer.enabled: true
                        }

                        // ── search row ─────────────────────────────────────────
                        RowLayout {
                            id: searchRow

                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 14
                            implicitHeight: 46
                            spacing: 10

                            // Mode icon
                            Text {
                                text: {
                                    if (listView.mode === "calc")
                                        return "";
                                    if (listView.mode === "emoji")
                                        return "😀";
                                    return "";
                                }
                                color: "#7aa2f7"
                                font.family: overlay.font
                                font.pixelSize: 16
                                verticalAlignment: Text.AlignVCenter
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on text {}
                            }

                            TextInput {
                                id: searchField

                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                color: "#c0caf5"
                                font.family: overlay.font
                                font.pixelSize: 14
                                clip: true

                                Text {
                                    anchors.fill: parent
                                    text: "Search apps…  ·  =calc  ·  :emoji"
                                    color: "#565f89"
                                    font.family: overlay.font
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                    visible: !searchField.text
                                }

                                Keys.onEscapePressed: {
                                    root.launcherVisible = false;
                                    text = "";
                                }

                                // BottomToTop: index 0 is at bottom (best match).
                                // Visually UP → higher index. DOWN → lower index.
                                Keys.onUpPressed: {
                                    if (listView.count === 0)
                                        return;
                                    if (listView.currentIndex >= listView.count - 1)
                                        listView.currentIndex = 0;
                                    else
                                        listView.incrementCurrentIndex();
                                }
                                Keys.onDownPressed: {
                                    if (listView.count === 0)
                                        return;
                                    if (listView.currentIndex <= 0)
                                        listView.currentIndex = listView.count - 1;
                                    else
                                        listView.decrementCurrentIndex();
                                }
                                Keys.onReturnPressed: {
                                    const item = listView.currentItem;
                                    if (item)
                                        item.activate();
                                }
                            }

                            Text {
                                text: ""
                                color: "#565f89"
                                font.family: overlay.font
                                font.pixelSize: 14
                                visible: searchField.text.length > 0
                                Layout.alignment: Qt.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: searchField.text = ""
                                }
                            }
                        }

                        // ── list ───────────────────────────────────────────────
                        ListView {
                            id: listView

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: searchRow.top
                            anchors.bottomMargin: 8
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6

                            clip: true
                            verticalLayoutDirection: ListView.BottomToTop

                            readonly property int itemH: 48
                            readonly property int maxItems: 8
                            implicitHeight: Math.min(count, maxItems) * itemH

                            spacing: 0
                            currentIndex: 0
                            onCountChanged: currentIndex = 0

                            // ── mode detection ─────────────────────────────────
                            readonly property string mode: {
                                const t = searchField.text;
                                if (t.startsWith("="))
                                    return "calc";
                                if (t.startsWith(":"))
                                    return "emoji";
                                return "apps";
                            }

                            // ── calculator ─────────────────────────────────────
                            property string calcResult: "…"
                            property string calcExpr: ""
                            property bool calcError: false

                            onModeChanged: {
                                if (mode !== "calc") {
                                    calcResult = "…";
                                    calcError = false;
                                }
                            }

                            Process {
                                id: calcProcess
                                running: false
                                command: ["qalc", "-t", listView.calcExpr]

                                stdout: SplitParser {
                                    onRead: line => {
                                        const t = line.trim();
                                        if (t) {
                                            listView.calcResult = t;
                                            listView.calcError = false;
                                        }
                                    }
                                }
                                stderr: SplitParser {
                                    onRead: line => {
                                        const t = line.trim();
                                        if (t && listView.calcResult === "…") {
                                            listView.calcResult = t;
                                            listView.calcError = true;
                                        }
                                    }
                                }
                            }

                            Timer {
                                id: calcDebounce
                                interval: 300
                                onTriggered: {
                                    const expr = searchField.text.slice(1).trim();
                                    if (expr) {
                                        listView.calcExpr = expr;
                                        listView.calcResult = "…";
                                        listView.calcError = false;
                                        calcProcess.running = false;
                                        calcProcess.running = true;
                                    } else {
                                        listView.calcResult = "…";
                                    }
                                }
                            }

                            Connections {
                                target: searchField
                                function onTextChanged() {
                                    if (listView.mode === "calc")
                                        calcDebounce.restart();
                                }
                            }

                            // ── emoji data ─────────────────────────────────────
                            property var loadedEmojis: []

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
                                                const e = parts[0];
                                                const k = parts.slice(1);
                                                const n = k.join(" ");
                                                result.push({
                                                    e: e,
                                                    n: n,
                                                    k: k
                                                });
                                            }
                                        }
                                        console.log("Loaded emojis count:", result.length);
                                        listView.loadedEmojis = result;
                                    }
                                }
                            }

                            // ── fuzzy app scorer ───────────────────────────────
                            function fuzzyScore(app, query) {
                                const q = query.toLowerCase();
                                const name = (app.name || "").toLowerCase();
                                const generic = (app.genericName || "").toLowerCase();
                                const comment = (app.comment || "").toLowerCase();

                                if (name === q)
                                    return 1000;
                                if (name.startsWith(q))
                                    return 900;
                                if (name.includes(q))
                                    return 800;

                                const initials = name.split(/[\s\-_]+/).map(w => w[0] || "").join("");
                                if (initials.startsWith(q))
                                    return 750;
                                if (initials.includes(q))
                                    return 700;

                                let qi = 0;
                                for (let i = 0; i < name.length && qi < q.length; i++)
                                    if (name[i] === q[qi])
                                        qi++;
                                if (qi === q.length)
                                    return 600 - Math.min(name.length - q.length, 99);

                                if (generic.includes(q) || comment.includes(q))
                                    return 500;

                                const combined = name + " " + generic;
                                let qi2 = 0;
                                for (let i = 0; i < combined.length && qi2 < q.length; i++)
                                    if (combined[i] === q[qi2])
                                        qi2++;
                                if (qi2 === q.length)
                                    return 400;

                                return -1;
                            }

                            // ── model ──────────────────────────────────────────
                            model: {
                                if (mode === "calc")
                                    return [0];

                                if (mode === "emoji") {
                                    const q = searchField.text.slice(1).toLowerCase().trim();
                                    if (!q)
                                        return listView.loadedEmojis;
                                    return listView.loadedEmojis.filter(em => em.n.includes(q) || (em.k && em.k.some(kw => kw.includes(q))));
                                }

                                // apps mode
                                const q = searchField.text.trim();
                                const all = DesktopEntries.applications.values;
                                if (!q)
                                    return [...all].sort((a, b) => a.name.localeCompare(b.name));

                                return all.map(a => ({
                                            app: a,
                                            score: fuzzyScore(a, q)
                                        })).filter(x => x.score >= 0).sort((x, y) => y.score !== x.score ? y.score - x.score : x.app.name.localeCompare(y.app.name)).map(x => x.app);
                            }

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle {
                                    implicitWidth: 4
                                    radius: 2
                                    color: "#3b4261"
                                }
                            }

                            highlight: Rectangle {
                                radius: 8
                                color: Qt.rgba(0x7a / 255, 0xa2 / 255, 0xf7 / 255, 0.12)
                                width: listView.width
                            }
                            highlightFollowsCurrentItem: true
                            highlightMoveDuration: 80
                            highlightResizeDuration: 0

                            add: Transition {
                                NumberAnimation {
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: 80
                                }
                            }
                            displaced: Transition {
                                NumberAnimation {
                                    property: "y"
                                    duration: 100
                                    easing.type: Easing.OutCubic
                                }
                            }

                            // ── delegate ───────────────────────────────────────
                            delegate: Item {
                                id: delRoot

                                required property var modelData
                                required property int index

                                width: listView.width
                                height: listView.itemH

                                readonly property string _mode: listView.mode

                                // Called by keyboard Enter and tap
                                function activate(): void {
                                    const mode = _mode;
                                    const emoji = modelData ? modelData.e : "";
                                    const cmd = modelData ? modelData.command : null;
                                    const r = listView.calcResult;

                                    root.launcherVisible = false;
                                    searchField.text = "";

                                    if (mode === "calc") {
                                        if (r && r !== "…" && !listView.calcError)
                                            Quickshell.execDetached(["wl-copy", r]);
                                    } else if (mode === "emoji") {
                                        Quickshell.execDetached(["sh", "-c", "wl-copy \"$1\" && sleep 0.4 && wtype -M ctrl -M shift -k v -m shift -m ctrl", "--", emoji]);
                                    } else {
                                        if (cmd)
                                            Quickshell.execDetached({ command: cmd });
                                    }
                                }

                                HoverHandler {
                                    id: hoverHandler
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: {
                                        listView.currentIndex = delRoot.index;
                                        delRoot.activate();
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: hoverHandler.hovered || listView.currentIndex === delRoot.index ? Qt.rgba(0x7a / 255, 0xa2 / 255, 0xf7 / 255, 0.10) : "transparent"
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 80
                                        }
                                    }
                                }

                                // ── App item ────────────────────────────────────
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 12
                                    visible: delRoot._mode === "apps"

                                    IconImage {
                                        implicitSize: 28
                                        source: delRoot.modelData && delRoot._mode === "apps" ? Quickshell.iconPath(delRoot.modelData.icon, "application-x-executable") : ""
                                        asynchronous: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        Text {
                                            text: delRoot._mode === "apps" ? (delRoot.modelData?.name ?? "") : ""
                                            color: (listView.currentIndex === delRoot.index || hoverHandler.hovered) ? "#7aa2f7" : "#c0caf5"
                                            font.family: overlay.font
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                            width: parent.width
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 100
                                                }
                                            }
                                        }

                                        Text {
                                            visible: delRoot._mode === "apps" && !!text
                                            text: delRoot._mode === "apps" ? (delRoot.modelData?.comment ?? delRoot.modelData?.genericName ?? "") : ""
                                            color: "#565f89"
                                            font.family: overlay.font
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                    }

                                    Text {
                                        visible: delRoot._mode === "apps" && (delRoot.modelData?.runInTerminal ?? false)
                                        text: ""
                                        color: "#9ece6a"
                                        font.family: overlay.font
                                        font.pixelSize: 12
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                // ── Calc item ───────────────────────────────────
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 14
                                    visible: delRoot._mode === "calc"

                                    Text {
                                        text: "󰃬"
                                        color: "#bb9af7"
                                        font.family: "FiraMono Nerd Font"
                                        font.pixelSize: 20
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 1

                                        Text {
                                            text: searchField.text.slice(1).trim() || "Type an expression…"
                                            color: searchField.text.length > 1 ? "#c0caf5" : "#565f89"
                                            font.family: overlay.font
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            text: {
                                                if (!searchField.text || searchField.text === "=")
                                                    return "Enter an expression after =";
                                                return listView.calcResult;
                                            }
                                            color: {
                                                if (listView.calcError)
                                                    return "#f7768e";
                                                if (listView.calcResult === "…")
                                                    return "#565f89";
                                                return "#9ece6a";
                                            }
                                            font.family: overlay.font
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                            width: parent.width

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        visible: listView.calcResult !== "…" && !listView.calcError
                                        text: "Copy"
                                        color: hoverHandler.hovered || listView.currentIndex === delRoot.index ? "#7aa2f7" : "#3b4261"
                                        font.family: overlay.font
                                        font.pixelSize: 11
                                        Layout.alignment: Qt.AlignVCenter

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 100
                                            }
                                        }
                                    }
                                }

                                // ── Emoji item ──────────────────────────────────
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 14
                                    visible: delRoot._mode === "emoji"

                                    Text {
                                        text: delRoot._mode === "emoji" ? (delRoot.modelData?.e ?? "") : ""
                                        font.pixelSize: 24
                                        Layout.alignment: Qt.AlignVCenter
                                        renderType: Text.NativeRendering
                                    }

                                    Text {
                                        text: delRoot._mode === "emoji" ? (delRoot.modelData?.n ?? "") : ""
                                        color: listView.currentIndex === delRoot.index || hoverHandler.hovered ? "#7aa2f7" : "#c0caf5"
                                        font.family: overlay.font
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 100
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Type"
                                        color: listView.currentIndex === delRoot.index || hoverHandler.hovered ? "#7aa2f7" : "#3b4261"
                                        font.family: overlay.font
                                        font.pixelSize: 11
                                        Layout.alignment: Qt.AlignVCenter

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 100
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
