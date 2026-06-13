import QtQuick
import ".." as BarModule
import "../../../services"

// Active window title — truncated single line
Text {
    id: root

    readonly property string title: {
        const t = Hypr.activeToplevel?.title
        if (!t) return "<font color=\"#33ccff\"></font> Hyprland"
        const parts = t.split(/\s+[\-\u2013\u2014]\s+/)
        return parts.length > 1 ? parts[parts.length - 1].trim() : t
    }

    text: title
    textFormat: !Hypr.activeToplevel?.title ? Text.StyledText : Text.PlainText
    color: "white"
    font.family: "FiraMono Nerd Font"
    font.pixelSize: 12
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter


}
