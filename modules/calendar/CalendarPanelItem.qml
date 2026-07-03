pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"

Item {
    id: root

    required property bool panelVisible

    signal closeRequested

    readonly property real panelWidth: 320
    readonly property real currentHeight: 360

    implicitWidth: panelWidth
    implicitHeight: currentHeight

    property date currentDate: new Date()
    property int currentMonth: currentDate.getMonth()
    property int currentYear: currentDate.getFullYear()
    property int viewMode: 0  // 0 = month, 1 = year

    function shiftMonth(delta) {
        let d = new Date(currentYear, currentMonth + delta, 1);
        currentMonth = d.getMonth();
        currentYear = d.getFullYear();
    }

    function generateMonthDays() {
        let days = [], firstDay = new Date(currentYear, currentMonth, 1).getDay();
        let daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate(), today = new Date();
        for (let i = 0; i < firstDay; i++)
            days.push({
                day: "",
                today: false
            });
        for (let i = 1; i <= daysInMonth; i++)
            days.push({
                day: i.toString(),
                today: today.getDate() === i && today.getMonth() === currentMonth && today.getFullYear() === currentYear
            });
        while (days.length < 42)
            days.push({
                day: "",
                today: false
            });
        return days;
    }

    property var monthDays: generateMonthDays()
    onCurrentMonthChanged: monthDays = generateMonthDays()
    onCurrentYearChanged: monthDays = generateMonthDays()

    property real offsetScale: root.panelVisible ? 0 : 1
    Behavior on offsetScale {
        Anim {}
    }
    readonly property real blobY: y + (-implicitHeight - 60) * offsetScale
    transform: Translate {
        y: (-root.implicitHeight - 60) * root.offsetScale
    }

    ColumnLayout {
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
                        if (root.viewMode === 0)
                            root.shiftMonth(-1);
                        else
                            root.currentYear -= 1;
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                implicitHeight: monthYearLabel.implicitHeight
                Text {
                    id: monthYearLabel
                    anchors.centerIn: parent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: myHov.containsMouse ? Theme.accent : "#ffffff"
                    text: root.viewMode === 0 ? ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][root.currentMonth] + " " + root.currentYear : root.currentYear.toString()
                }
                MouseArea {
                    id: myHov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.viewMode = (root.viewMode === 0) ? 1 : 0
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
                        if (root.viewMode === 0)
                            root.shiftMonth(1);
                        else
                            root.currentYear += 1;
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
                            color: modelData.today ? Theme.accent : dayHov.containsMouse && modelData.day !== "" ? "#292e42" : "transparent"
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
                            let n = new Date();
                            return (index === n.getMonth() && root.currentYear === n.getFullYear()) ? Theme.accent : pickerHov.containsMouse ? "#292e42" : "transparent";
                        }
                        Text {
                            anchors.centerIn: parent
                            text: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][index]
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: {
                                let n = new Date();
                                return (index === n.getMonth() && root.currentYear === n.getFullYear()) ? "#1a1b26" : "#ffffff";
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
