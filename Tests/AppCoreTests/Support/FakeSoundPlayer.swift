@testable import AppCore

/// Records what the sound preview asked for; the test decides when a sound ends.
@MainActor
final class FakeSoundPlayer: SoundPlaying {
    struct Play: Equatable {
        let sound: PreviewSound
        let volume: Double
        let fadeIn: Double
    }

    private(set) var plays: [Play] = []
    private(set) var volumes: [Double] = []
    private(set) var stopCount = 0
    private var continuation: AsyncStream<Void>.Continuation?

    func play(_ sound: PreviewSound, volume: Double, fadeIn: Double) -> AsyncStream<Void> {
        plays.append(Play(sound: sound, volume: volume, fadeIn: fadeIn))
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        self.continuation = continuation
        return stream
    }

    func setVolume(_ volume: Double) {
        volumes.append(volume)
    }

    func stop() {
        stopCount += 1
        continuation?.finish()
        continuation = nil
    }

    /// Simulates the clip reaching its end.
    func finishCurrent() {
        continuation?.finish()
        continuation = nil
    }
}
