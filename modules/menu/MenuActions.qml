import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../../services"

ListView {
    id: actionsList
    property string query: ""
    signal action
    signal autocomplete(string text)

    clip: true
    verticalLayoutDirection: ListView.BottomToTop

    readonly property int itemH: 48
    readonly property int maxItems: 8
    implicitHeight: Math.min(count, maxItems) * itemH

    spacing: 0
    currentIndex: 0
    onCountChanged: currentIndex = 0

    function fuzzyScore(name, q) {
        const ql = q.toLowerCase();
        const n = name.toLowerCase();

        if (n === ql)
            return 1000;
        if (n.startsWith(ql))
            return 900;

        const words = n.split(/[\s\-_:]+/);
        if (words.includes(ql))
            return 850;

        if (n.includes(ql))
            return 800;
        return -1;
    }

    property string activeMenu: "root"

    onQueryChanged: {
        updateMenuState();
    }

    onVisibleChanged: {
        if (visible)
            updateMenuState();
    }

    function updateMenuState() {
        const q = query.toLowerCase();
        if (q.startsWith("system ")) {
            activeMenu = "system";
        } else if (q.startsWith("scheme ")) {
            activeMenu = "scheme";
        } else if (q.length === 0 && !visible) {
            // keep state until visible
        } else if (q.length === 0 && visible) {
            activeMenu = "root";
        }
    }

    property var rootActions: [
        {
            name: "Scheme",
            desc: "Change the colour scheme",
            icon: "",
            type: "submenu",
            target: "scheme"
        },
        {
            name: "System",
            desc: "System power actions",
            icon: "",
            type: "submenu",
            target: "system"
        },
        {
            name: "Calculator",
            desc: "Open Calculator",
            icon: "󰃬",
            type: "autocomplete",
            target: "="
        },
        {
            name: "Clipboard",
            desc: "Clipboard History",
            icon: "󱘢",
            type: "autocomplete",
            target: "@"
        }
    ]

    property var systemActions: [
        {
            name: "Shutdown",
            desc: "Power off the system",
            icon: "",
            cmd: ["systemctl", "poweroff"]
        },
        {
            name: "Reboot",
            desc: "Restart the system",
            icon: "󰑐",
            cmd: ["systemctl", "reboot"]
        },
        {
            name: "Suspend",
            desc: "Suspend the system to RAM",
            icon: "󰤄",
            cmd: ["systemctl", "suspend"]
        },
        {
            name: "Lock",
            desc: "Lock the current session",
            icon: "󰌾",
            cmd: ["loginctl", "lock-session"]
        },
        {
            name: "Logout",
            desc: "Exit the compositor",
            icon: "󰍃",
            cmd: ["hyprctl", "dispatch", "exit"]
        }
    ]

    property var schemesData: []
    property string currentScheme: ""

    Process {
        id: getSchemes
        command: ["sh", "-c", "$HOME/.local/bin/hebi scheme list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const schemeData = JSON.parse(text);
                    const list = Object.entries(schemeData).map(([name, f]) => Object.entries(f).map(([flavour, colours]) => ({
                                    name: name,
                                    flavour: flavour,
                                    fullName: `${name} ${flavour}`
                                })));

                    const flat = [];
                    for (const s of list)
                        for (const f of s)
                            flat.push(f);

                    actionsList.schemesData = flat.sort((a, b) => a.fullName.localeCompare(b.fullName));
                } catch (e) {
                    console.error("Failed to parse scheme list", e);
                }
            }
        }
    }

    Process {
        id: getCurrentScheme
        command: ["sh", "-c", "$HOME/.local/bin/hebi scheme get -nfv"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = text.trim().split("\n");
                    if (parts.length >= 2) {
                        actionsList.currentScheme = `${parts[0]} ${parts[1]}`;
                    }
                } catch (e) {
                    console.error("Failed to parse current scheme", e);
                }
            }
        }
    }

    Component.onCompleted: {
        getSchemes.running = true;
        getCurrentScheme.running = true;
    }

    model: {
        const q = actionsList.query.toLowerCase();
        let listToSearch = [];
        let searchQ = q;

        if (activeMenu === "root") {
            listToSearch = rootActions;
        } else if (activeMenu === "system") {
            listToSearch = [
                {
                    name: "Back",
                    desc: "Return to main menu",
                    icon: "󰁍",
                    type: "back"
                }
            ].concat(systemActions);
            if (q.startsWith("system "))
                searchQ = q.slice(7).trim();
            else
                searchQ = "";
        } else if (activeMenu === "scheme") {
            listToSearch = [
                {
                    name: "Back",
                    desc: "Return to main menu",
                    icon: "󰁍",
                    type: "back"
                }
            ].concat(schemesData.map(s => ({
                        name: s.fullName,
                        desc: s.fullName === actionsList.currentScheme ? "Current Theme" : "Theme scheme",
                        icon: "",
                        type: "scheme",
                        schemeName: s.name,
                        schemeFlavour: s.flavour,
                        isCurrent: s.fullName === actionsList.currentScheme
                    })));
            if (q.startsWith("scheme "))
                searchQ = q.slice(7).trim();
            else
                searchQ = "";
        }

        if (!searchQ) {
            return listToSearch.map(a => Object.assign({}, a, {
                    score: 1000
                }));
        }

        return listToSearch.map(a => Object.assign({}, a, {
                score: fuzzyScore(a.name, searchQ)
            })).filter(x => x.score >= 0).sort((x, y) => y.score !== x.score ? y.score - x.score : x.name.localeCompare(y.name));
    }

    function handleUp() {
        if (count === 0)
            return;
        if (currentIndex >= count - 1)
            currentIndex = 0;
        else
            incrementCurrentIndex();
    }

    function handleDown() {
        if (count === 0)
            return;
        if (currentIndex <= 0)
            currentIndex = count - 1;
        else
            decrementCurrentIndex();
    }

    function handleReturn() {
        const item = currentItem;
        if (item)
            item.activate();
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Theme.surfaceVariant
        }
    }

    highlight: Rectangle {
        radius: 8
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
        width: actionsList.width
    }
    highlightFollowsCurrentItem: true
    highlightMoveDuration: 80

    delegate: Item {
        id: delRoot
        required property var modelData
        required property int index
        width: actionsList.width
        height: actionsList.itemH

        function activate() {
            if (modelData.type === "back") {
                actionsList.activeMenu = "root";
            } else if (modelData.type === "submenu") {
                actionsList.activeMenu = modelData.target;
            } else if (modelData.type === "autocomplete") {
                actionsList.autocomplete(modelData.target);
            } else if (modelData.type === "scheme") {
                actionsList.action();
                Quickshell.execDetached(["sh", "-c", "$HOME/.local/bin/hebi scheme set -n \"$1\" -f \"$2\"", "--", modelData.schemeName, modelData.schemeFlavour]);
            } else {
                actionsList.action();
                Quickshell.execDetached(modelData.cmd);
            }
        }

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: {
                actionsList.currentIndex = delRoot.index;
                delRoot.activate();
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            Text {
                text: delRoot.modelData?.icon ?? ""
                color: (actionsList.currentIndex === delRoot.index || hoverHandler.hovered) ? Theme.accent : Theme.subtext
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 28
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Text {
                    text: delRoot.modelData?.name ?? ""
                    color: {
                        if (delRoot.modelData.isCurrent)
                            return Theme.success;
                        if (actionsList.currentIndex === delRoot.index || hoverHandler.hovered)
                            return Theme.accent;
                        return Theme.text;
                    }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    visible: !!text
                    text: delRoot.modelData?.desc ?? ""
                    color: Theme.subtext
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Text {
                visible: delRoot.modelData?.type === "submenu"
                text: "" // Right chevron for submenu indication
                color: (actionsList.currentIndex === delRoot.index || hoverHandler.hovered) ? Theme.accent : Theme.subtext
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
