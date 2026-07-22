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
    signal openModeReq(string mode)

    clip: true
    verticalLayoutDirection: ListView.BottomToTop

    readonly property int itemH: 48
    readonly property int maxItems: 8
    implicitHeight: Math.min(count, maxItems) * itemH

    spacing: 0
    currentIndex: 0
    onCountChanged: currentIndex = 0

    onCurrentItemChanged: {
        if (!visible) return;
        if (activeMenu === "scheme" && currentItem && currentItem.modelData && currentItem.modelData.type === "scheme-family") {
            Theme.setSchemePreview(currentItem.activeFlavour.colours);
        } else {
            Theme.setSchemePreview(null);
        }
    }

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
        else
            Theme.setSchemePreview(null);
    }

    function updateMenuState() {
        const q = query.toLowerCase();
        if (q.startsWith("system ")) {
            activeMenu = "system";
        } else if (q.startsWith("scheme ")) {
            activeMenu = "scheme";
        } else if (q.startsWith("wallpaper ")) {
            activeMenu = "wallpaper";
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
            name: "Wallpaper",
            desc: "Change the wallpaper",
            icon: "󰸉",
            type: "submenu",
            target: "wallpaper"
        },
        {
            name: "System",
            desc: "System power actions",
            icon: "",
            type: "submenu",
            target: "system"
        },
        {
            name: "Theme Mode",
            desc: "Switch between light and dark mode",
            icon: "󰔎",
            type: "toggle-mode"
        },
        {
            name: "Calculator",
            desc: "Open Calculator",
            icon: "󰃬",
            type: "mode",
            target: "calc"
        },
        {
            name: "Clipboard",
            desc: "Clipboard History",
            icon: "󱘢",
            type: "mode",
            target: "clipboard"
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
    property string currentScheme: Theme.currentSchemeName + " " + Theme.currentSchemeFlavour

    property string currentActiveMode: Theme.currentSchemeMode || "dark"
    onCurrentActiveModeChanged: {
        getSchemes.running = true;
    }

    property bool currentSchemeHasOpposite: {
        const current = schemesData.find(s => s.fullName === actionsList.currentScheme);
        return current ? (current.colours.has_opposite_mode ?? false) : false;
    }

    property var selectedFlavours: ({})

    function updateSelectedFlavour(schemeName, newIndex) {
        let temp = selectedFlavours;
        temp[schemeName] = newIndex;
        selectedFlavours = Object.assign({}, temp);
    }

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
                                    fullName: `${name} ${flavour}`,
                                    colours: colours
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

    Component.onCompleted: {
        getSchemes.running = true;
    }

    model: {
        const q = actionsList.query.toLowerCase();
        let listToSearch = [];
        let searchQ = q;

        if (activeMenu === "root") {
            listToSearch = rootActions;
        } else if (activeMenu === "system") {
            listToSearch = systemActions;
            if (q.startsWith("system "))
                searchQ = q.slice(7).trim();
            else
                searchQ = q;
        } else if (activeMenu === "scheme") {
            const families = {};
            
            schemesData.filter(s => s.fullName !== "dynamic hard" && s.colours.mode === currentActiveMode).forEach(s => {
                if (!families[s.name]) {
                    families[s.name] = {
                        name: s.name === "dynamic" ? "dynamic" : s.name,
                        icon: s.name === "dynamic" ? "󰸉" : "",
                        type: "scheme-family",
                        schemeName: s.name,
                        flavours: []
                    };
                }
                families[s.name].flavours.push({
                    flavour: s.flavour,
                    colours: s.colours
                });
            });

            const filteredSchemes = Object.values(families).map(f => {
                let selIdx = f.flavours.findIndex(fl => f.schemeName + " " + fl.flavour === actionsList.currentScheme);
                if (selIdx < 0) selIdx = 0;
                f.initialSelectedIndex = selIdx;
                f.isCurrent = f.flavours.some(fl => f.schemeName + " " + fl.flavour === actionsList.currentScheme);
                
                return f;
            });

            listToSearch = filteredSchemes;
            if (q.startsWith("scheme "))
                searchQ = q.slice(7).trim();
            else
                searchQ = q;
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


    function cycleFlavour(direction) {
        if (activeMenu !== "scheme") return;
        const currentData = actionsList.model[currentIndex];
        if (currentData && currentData.type === "scheme-family") {
            let numFlavours = currentData.flavours.length;
            let currentSel = selectedFlavours[currentData.schemeName];
            if (currentSel === undefined) {
                currentSel = currentData.initialSelectedIndex;
            }
            let newSel = (currentSel + direction + numFlavours) % numFlavours;
            updateSelectedFlavour(currentData.schemeName, newSel);
            
            const selFlavour = currentData.flavours[newSel];
            Theme.setSchemePreview(selFlavour.colours);
        }
    }

    function handleTab() { cycleFlavour(1); }
    function handleBacktab() { cycleFlavour(-1); }
    function handleLeft() { cycleFlavour(-1); }
    function handleRight() { cycleFlavour(1); }

    function handleBackspace() {
        if (activeMenu !== "root") {
            activeMenu = "root";
            return true;
        }
        return false;
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
        height: modelData?.type === "wallpaper-item" ? 68 : actionsList.itemH

        property int activeFlavourIndex: {
            if (delRoot.modelData?.type === "scheme-family") {
                let val = actionsList.selectedFlavours[delRoot.modelData.schemeName];
                if (val !== undefined) return val;
                return delRoot.modelData.initialSelectedIndex;
            }
            return 0;
        }

        property var activeFlavour: {
            if (delRoot.modelData?.type === "scheme-family") {
                return delRoot.modelData.flavours[activeFlavourIndex];
            }
            return null;
        }

        function activate() {
            if (modelData.type === "back") {
                actionsList.activeMenu = "root";
            } else if (modelData.type === "submenu") {
                actionsList.activeMenu = modelData.target;
            } else if (modelData.type === "mode") {
                actionsList.openModeReq(modelData.target);
            } else if (modelData.type === "autocomplete") {
                actionsList.autocomplete(modelData.target);
            } else if (modelData.type === "scheme-family") {
                const sName = modelData.schemeName;
                const selFlav = delRoot.activeFlavour.flavour;
                Quickshell.execDetached(["sh", "-c", "$HOME/.local/bin/hebi scheme set -n \"$1\" -f \"$2\"", "--", sName, selFlav]);
                Qt.callLater(actionsList.action);
            } else if (modelData.type === "toggle-mode") {
                Quickshell.execDetached(["sh", "-c", "$HOME/.local/bin/hebi scheme set -m " + (Theme.currentSchemeMode === "dark" ? "light" : "dark")]);
            } else if (modelData.type === "wallpaper-item") {
                const p = modelData.path;
                Wallpapers.apply(p);
                Qt.callLater(actionsList.action);
            } else {
                const c = modelData.cmd;
                Quickshell.execDetached(c);
                Qt.callLater(actionsList.action);
            }
        }

        HoverHandler {
            id: hoverHandler
            cursorShape: delRoot.modelData?.type === "header" || !delRoot.enabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: {
                if (delRoot.modelData?.type !== "header" && delRoot.enabled) {
                    actionsList.currentIndex = delRoot.index;
                    delRoot.activate();
                }
            }
        }

        // Header View
        Text {
            visible: delRoot.modelData?.type === "header"
            anchors.fill: parent
            anchors.leftMargin: 10
            verticalAlignment: Text.AlignVCenter
            text: delRoot.modelData?.name ?? ""
            color: Theme.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        RowLayout {
            visible: delRoot.modelData?.type !== "header"
            enabled: delRoot.modelData?.type !== "toggle-mode" || actionsList.currentSchemeHasOpposite
            opacity: enabled ? 1.0 : 0.4
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            // Wallpaper thumbnail (only for wallpaper-item type)
            Rectangle {
                visible: delRoot.modelData?.type === "wallpaper-item"
                width: 80
                height: 45
                radius: 6
                color: Theme.surfaceVariant
                clip: true
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.fill: parent
                    source: delRoot.modelData?.type === "wallpaper-item" ? ("file://" + delRoot.modelData.path) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 160
                    sourceSize.height: 90
                }

                // Ring highlight for active item
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Theme.accent
                    border.width: (actionsList.currentIndex === delRoot.index || delRoot.modelData?.isCurrent) ? 2 : 0
                }
            }

            Text {
                visible: delRoot.modelData?.type !== "wallpaper-item"
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
                    text: {
                        if (delRoot.modelData?.type === "scheme-family") {
                            return delRoot.modelData.name + (activeFlavour ? " " + activeFlavour.flavour : "");
                        }
                        return delRoot.modelData?.name ?? "";
                    }
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
                Item {
                    width: parent.width
                    height: childrenRect.height
                    visible: !!delRoot.modelData?.desc || delRoot.modelData?.type === "scheme-family"

                    Text {
                        visible: delRoot.modelData?.type !== "scheme-family"
                        text: delRoot.modelData?.desc ?? ""
                        color: Theme.subtext
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Row {
                        visible: delRoot.modelData?.type === "scheme-family"
                        spacing: 6
                        Repeater {
                            model: delRoot.modelData?.flavours ?? []
                            delegate: Text {
                                required property var modelData
                                required property int index
                                text: modelData.flavour
                                color: index === delRoot.activeFlavourIndex ? Theme.accent : Theme.subtext
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }

            Text {
                visible: delRoot.modelData?.type === "submenu"
                text: "" // Right chevron for submenu indication
                color: (actionsList.currentIndex === delRoot.index || hoverHandler.hovered) ? Theme.accent : Theme.subtext
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
            }

            // Theme Mode Toggle Visualizer
            Rectangle {
                visible: delRoot.modelData?.type === "toggle-mode"
                width: 40
                height: 22
                radius: 11
                color: Theme.currentSchemeMode === "dark" ? Theme.accent : Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.5)
                Layout.alignment: Qt.AlignVCenter
                
                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: Theme.surface
                    x: Theme.currentSchemeMode === "dark" ? parent.width - width - 2 : 2
                    y: 2
                    
                    Behavior on x {
                        NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }
    }
}
