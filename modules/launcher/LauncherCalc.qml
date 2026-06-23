import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: calcRoot
    property string expr: ""
    property string calcResult: "…"
    property bool calcError: false
    signal action()

    implicitHeight: 48

    function handleUp() {}
    function handleDown() {}
    function handleReturn() {
        if (calcResult !== "…" && !calcError) {
            calcRoot.action();
            Quickshell.execDetached(["wl-copy", calcResult]);
        }
    }

    Process {
        id: calcProcess
        running: false
        command: ["qalc", "-t", calcRoot.expr]
        stdout: SplitParser { onRead: line => { const t = line.trim(); if(t) { calcRoot.calcResult = t; calcRoot.calcError = false; } } }
        stderr: SplitParser { onRead: line => { const t = line.trim(); if(t && calcRoot.calcResult === "…") { calcRoot.calcResult = t; calcRoot.calcError = true; } } }
    }

    Timer {
        id: calcDebounce
        interval: 300
        onTriggered: {
            if (calcRoot.expr) {
                calcRoot.calcResult = "…";
                calcRoot.calcError = false;
                calcProcess.running = false;
                calcProcess.running = true;
            } else {
                calcRoot.calcResult = "…";
            }
        }
    }

    onExprChanged: calcDebounce.restart()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 14

        Text {
            text: "󰃬"
            color: "#bb9af7"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            Layout.alignment: Qt.AlignVCenter
        }

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                text: calcRoot.expr || "Type an expression…"
                color: calcRoot.expr.length > 0 ? "#c0caf5" : "#565f89"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: calcRoot.expr ? calcRoot.calcResult : "Enter an expression after ="
                color: calcRoot.calcError ? "#f7768e" : (calcRoot.calcResult === "…" ? "#565f89" : "#9ece6a")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.weight: Font.Medium
                elide: Text.ElideRight
                width: parent.width
            }
        }

        Text {
            visible: calcRoot.calcResult !== "…" && !calcRoot.calcError
            text: "Copy"
            color: "#7aa2f7"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
