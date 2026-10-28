import Foundation
import Observation

/// Plays sound files. The app uses `AudioPreviewPlayer` (AVFoundation); tests use a fake.
@MainActor
protocol SoundPlaying: AnyObject {
    /// Starts `sound` silent and fades it up to `volume` over `fadeIn` seconds. The stream ends when the sound
    /// stops for any reason.
    func play(_ sound: PreviewSound, volume: Double, fadeIn: Double) -> AsyncStream<Void>
    func setVolume(_ volume: Double)
    func stop()
}

/// "Hear it quietly first": the child previews a loud sound at a volume they choose.
///
/// Sensory rules from DESIGN.md: nothing plays by itself, every slider starts at 20%, sounds fade in over
/// 1.5 s, Stop is always available, and nothing plays at all until a grown-up has turned sounds on.
@MainActor
@Observable
final class SoundPreviewModel {
    static let startLevel = 0.2
    static let fadeInSeconds = 1.5

    let cues: [SoundCue]
    /// Set by a grown-up in settings. When off, the screen explains that sounds are off instead of playing.
    let soundsEnabled: Bool
    /// The grown-up's ceiling for preview volume, from 0 to 1.
    let volumeLimit: Double
    private(set) var playing: PreviewSound?
    private(set) var levels: [PreviewSound: Double]

    @ObservationIgnored private let player: any SoundPlaying
    @ObservationIgnored private var playbackTask: Task<Void, Never>?
    @ObservationIgnored private var generation = 0

    init(cues: [SoundCue], player: any SoundPlaying, soundsEnabled: Bool, volumeLimit: Double = 1) {
        self.cues = cues
        self.player = player
        self.soundsEnabled = soundsEnabled
        self.volumeLimit = min(max(volumeLimit, 0), 1)
        levels = Dictionary(uniqueKeysWithValues: cues.map { ($0.sound, Self.startLevel) })
    }

    func level(for sound: PreviewSound) -> Double {
        levels[sound] ?? Self.startLevel
    }

    /// The child's slider position (0…1). While the sound plays, the change is heard straight away.
    func setLevel(_ level: Double, for sound: PreviewSound) {
        let clamped = min(max(level, 0), 1)
        levels[sound] = clamped
        if playing == sound {
            player.setVolume(effectiveVolume(for: sound))
        }
    }

    /// The player volume for `sound`: the child's level, within the sound's cap and the grown-up's limit.
    func effectiveVolume(for sound: PreviewSound) -> Double {
        level(for: sound) * sound.volumeCap * volumeLimit
    }

    /// Plays one sound once. Playing another sound stops the first.
    @discardableResult
    func play(_ sound: PreviewSound) -> Task<Void, Never>? {
        guard soundsEnabled else { return nil }
        stop()
        let current = generation
        playing = sound
        let stream = player.play(sound, volume: effectiveVolume(for: sound), fadeIn: Self.fadeInSeconds)
        let task = Task { [weak self] in
            for await _ in stream {}
            guard let self, self.generation == current else { return }
            self.playing = nil
        }
        playbackTask = task
        return task
    }

    func stop() {
        generation += 1
        playbackTask?.cancel()
        playbackTask = nil
        player.stop()
        playing = nil
    }
}
