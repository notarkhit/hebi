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

    function setVolume(newVolume: real): void {
        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.muted = false;
            Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1.5, newVolume));
        }
    }
}
