import QtQuick
import ".." as BarModule
import "../../../services"

// Active window title — truncated single line
Text {
    id: root

    readonly property bool isValid: Hypr.activeToplevel && Hypr.activeToplevel.workspace === Hypr.focusedWorkspace

    readonly property string title: {
        if (!isValid) return "<font color=\"#7dcfff\"></font> Hyprland"
        const t = Hypr.activeToplevel.title
        if (!t) return "<font color=\"#7dcfff\"></font> Hyprland"
        const parts = t.split(/\s+[\-\u2013\u2014]\s+/)
        return parts.length > 1 ? parts[parts.length - 1].trim() : t
    }

    text: title
    textFormat: !isValid || !Hypr.activeToplevel.title ? Text.StyledText : Text.PlainText
    color: Theme.text
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter


}
