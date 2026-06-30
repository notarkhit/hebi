pragma ComponentBehavior: Bound

// System tray — one icon per SNI item (qBittorrent, Discord, etc.)
// Left-click  → activate (show/raise window)
// Right-click → secondaryActivate
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Item {
    id: root
    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: ScriptModel { values: SystemTray.items.values }

            Item {
                id: trayItem
                required property SystemTrayItem modelData

                implicitWidth:  20
                implicitHeight: 20
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                    anchors.fill: parent
                    source: {
                        const raw = trayItem.modelData.icon;
                        if (typeof raw === "string" && raw.includes("?path=")) {
                            const [name, path] = raw.split("?path=");
                            return Qt.resolvedUrl(path + "/" + name.slice(name.lastIndexOf("/") + 1));
                        }
                        return raw;
                    }
                    asynchronous: true
                    smooth: true
                    opacity: itemMouse.containsMouse ? 1.0 : 0.75
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill:    parent
                    anchors.margins: -4
                    hoverEnabled:    true
                    cursorShape:     Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            trayItem.modelData.secondaryActivate();
                        else
                            trayItem.modelData.activate();
                    }
                }
            }
        }
    }
}
