pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io

Singleton {
    id: root

    property real volume: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume * 100 : 0
    property bool muted: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.muted : false

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    onVolumeChanged: {
        console.log("AudioService volume changed to:", volume);
    }

    property real queuedVolume: NaN

    Timer {
        id: debounceTimer
        interval: 40
        onTriggered: {
            if (!isNaN(queuedVolume)) {
                root.setVolume(queuedVolume);
                queuedVolume = NaN;
            }
        }
    }

    function setVolume(newVolume: real): void {
        if (debounceTimer.running) {
            queuedVolume = newVolume;
            return;
        }

        let clamped = Math.max(0, Math.min(1.5, newVolume));
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]);
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", clamped.toString()]);
        
        debounceTimer.restart();
    }
}
