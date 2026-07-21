pragma ComponentBehavior: Bound

// System tray — one icon per SNI item (qBittorrent, Discord, Telegram, etc.)
// Left-click  → activate() (show/raise window), or open menu if onlyMenu
// Right-click → writes to TrayMenuState singleton; MainWindow renders the overlay
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../../services"

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

                // Scale-in animation when item appears
                scale: 0
                Component.onCompleted: scale = 1
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

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
                        if (mouse.button === Qt.RightButton) {
                            if (trayItem.modelData.onlyMenu && trayItem.modelData.hasMenu) {
                                if (TrayMenuState.visible && TrayMenuState.menuHandle === trayItem.modelData.menu) {
                                    TrayMenuState.close()
                                } else {
                                    const p = root.mapToItem(null, root.width / 2, 0)
                                    TrayMenuState.open(trayItem.modelData.menu, p.x)
                                }
                            } else {
                                trayItem.modelData.activate()
                            }
                        } else {
                            if (trayItem.modelData.hasMenu) {
                                if (TrayMenuState.visible && TrayMenuState.menuHandle === trayItem.modelData.menu) {
                                    TrayMenuState.close()
                                } else {
                                    // Map the center of the entire Tray module to MainWindow
                                    const p = root.mapToItem(null, root.width / 2, 0)
                                    TrayMenuState.open(trayItem.modelData.menu, p.x)
                                }
                            } else {
                                trayItem.modelData.secondaryActivate()
                            }
                        }
                    }
                }
            }
        }
    }
}
