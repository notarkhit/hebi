pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property date date: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes
    readonly property int seconds: clock.seconds

    readonly property string timeStr: Qt.formatDateTime(clock.date, "hh:mm")
    readonly property string hourStr:   Qt.formatDateTime(clock.date, "hh")
    readonly property string minuteStr: Qt.formatDateTime(clock.date, "mm")
    readonly property string dateStr:   Qt.formatDateTime(clock.date, "ddd, MMM dd")

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
