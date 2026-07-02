pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Hebi.Blobs
import "../../services"

PanelWindow {
    id: root
    property bool panelVisible: false

    IpcHandler {
        target: "calendar"
        function toggle(): void { root.panelVisible = !root.panelVisible; }
        function open(): void { root.panelVisible = true; }
        function close(): void { root.panelVisible = false; }
    }

    anchors.top: true
    anchors.left: false
    anchors.right: false
    anchors.bottom: false

    implicitWidth: 360
    implicitHeight: 480
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    mask: panelVisible ? activeRegion : emptyRegion
    Region { id: emptyRegion }
    Region {
        id: activeRegion
        x: panelBg.x
        y: panelBg.y
        width: panelBg.width
        height: panelBg.height
    }

    BlobGroup {
        id: bgGroup
        color: Theme.surface
    }

    property date currentDate: new Date()
    property int currentMonth: currentDate.getMonth()
    property int currentYear: currentDate.getFullYear()
    property int viewMode: 0
    
    function shiftMonth(delta) {
        let d = new Date(currentYear, currentMonth + delta, 1);
        currentMonth = d.getMonth();
        currentYear = d.getFullYear();
    }

    function generateMonthDays() {
        let days = [];
        let firstDay = new Date(currentYear, currentMonth, 1).getDay();
        let daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
        let today = new Date();
        
        for (let i = 0; i < firstDay; i++) {
            days.push({ day: "", today: false });
        }
        for (let i = 1; i <= daysInMonth; i++) {
            let isToday = (today.getDate() === i && today.getMonth() === currentMonth && today.getFullYear() === currentYear);
            days.push({ day: i.toString(), today: isToday });
        }
        
        // Always pad the grid to 42 slots (6 weeks * 7 days) to prevent height jumping
        while (days.length < 42) {
            days.push({ day: "", today: false });
        }
        
        return days;
    }

    property var monthDays: generateMonthDays()
    onCurrentMonthChanged: monthDays = generateMonthDays()
    onCurrentYearChanged: monthDays = generateMonthDays()

    Item {
        id: container
        anchors.fill: parent

        BlobRect {
            id: panelBg
            group: bgGroup
            anchors.horizontalCenter: parent.horizontalCenter
            
            // Start from the exact position and size of the clock in the bar
            y: root.panelVisible ? 12 : 0

            property real openW: 320
            property real openH: 360

            width: root.panelVisible ? openW : 80
            height: root.panelVisible ? openH : 32
            radius: root.panelVisible ? 24 : 16

            // Fade out completely when closed so it doesn't tint the clock text over the bar
            opacity: root.panelVisible ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 320; easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic } }
            Behavior on y { NumberAnimation { duration: 320; easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic } }
            Behavior on width { NumberAnimation { duration: 320; easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic } }
            Behavior on height { NumberAnimation { duration: 320; easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic } }
            Behavior on radius { NumberAnimation { duration: 320; easing.type: root.panelVisible ? Easing.OutQuint : Easing.InCubic } }
            
            Item {
                id: contentWrapper
                anchors.fill: parent
                clip: true

                Item {
                    id: content
                    anchors.centerIn: parent
                    width: panelBg.openW
                    height: panelBg.openH

                    opacity: root.panelVisible ? 1 : 0
                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation { duration: root.panelVisible ? 300 : 0 }
                            NumberAnimation { duration: root.panelVisible ? 180 : 80; easing.type: Easing.OutCubic }
                        }
                    }

                    ColumnLayout {
                        id: col
                        anchors.centerIn: parent
                        width: 280
                        spacing: 16

                        RowLayout {
                            Layout.fillWidth: true
                            
                            Text {
                                text: "‹"
                                font.pixelSize: 18
                                color: leftHov.containsMouse ? "#ffffff" : "#c0caf5"
                                
                                MouseArea {
                                    id: leftHov
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.viewMode === 0) root.shiftMonth(-1);
                                        else root.currentYear -= 1;
                                    }
                                }
                            }
                            
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: monthYearLabel.implicitHeight
                                
                                Text {
                                    id: monthYearLabel
                                    anchors.centerIn: parent
                                    text: {
                                        if (root.viewMode === 0) {
                                            const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                                            return monthNames[root.currentMonth] + " " + root.currentYear;
                                        } else {
                                            return root.currentYear.toString();
                                        }
                                    }
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: myHov.containsMouse ? Theme.accent : "#ffffff"
                                }
                                
                                MouseArea {
                                    id: myHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.viewMode = (root.viewMode === 0) ? 1 : 0;
                                    }
                                }
                            }
                            
                            Text {
                                text: "›"
                                font.pixelSize: 18
                                color: rightHov.containsMouse ? "#ffffff" : "#c0caf5"
                                
                                MouseArea {
                                    id: rightHov
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.viewMode === 0) root.shiftMonth(1);
                                        else root.currentYear += 1;
                                    }
                                }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: root.viewMode === 0
                            spacing: 8
                            
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 7
                                rowSpacing: 8
                                columnSpacing: 4
                                
                                Repeater {
                                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                                    delegate: Text {
                                        required property var modelData
                                        required property int index
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignHCenter
                                        color: (index === 0 || index === 6) ? "#7dcfff" : "#9aa5ce"
                                    }
                                }
                                
                                Repeater {
                                    model: root.monthDays
                                    delegate: Item {
                                        required property var modelData
                                        required property int index
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 28
                                            height: 28
                                            radius: 14
                                            color: {
                                                if (modelData.today) return Theme.accent;
                                                if (dayHov.containsMouse && modelData.day !== "") return "#292e42";
                                                return "transparent";
                                            }
                                            visible: modelData.day !== ""
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.day
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 13
                                                color: modelData.today ? "#1a1b26" : "#ffffff"
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: dayHov
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: modelData.day !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        }
                                    }
                                }
                            }
                        }
                        
                        GridLayout {
                            Layout.fillWidth: true
                            visible: root.viewMode === 1
                            columns: 3
                            rowSpacing: 12
                            columnSpacing: 12
                            
                            Repeater {
                                model: 12
                                delegate: Item {
                                    required property int index
                                    implicitWidth: 80
                                    implicitHeight: 40
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: {
                                            let now = new Date();
                                            if (index === now.getMonth() && root.currentYear === now.getFullYear()) {
                                                return Theme.accent;
                                            }
                                            return pickerHov.containsMouse ? "#292e42" : "transparent";
                                        }
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][index]
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: {
                                                let now = new Date();
                                                if (index === now.getMonth() && root.currentYear === now.getFullYear()) {
                                                    return "#1a1b26";
                                                }
                                                return "#ffffff";
                                            }
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: pickerHov
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.currentMonth = index;
                                            root.viewMode = 0;
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

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.panelVisible = false
    }
}
