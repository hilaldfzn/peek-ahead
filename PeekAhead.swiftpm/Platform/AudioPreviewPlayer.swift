import AVFoundation

/// Plays the bundled preview loops (`Resources/Sounds/*.m4a`) once each, with a fade-in.
///
/// Uses the `.ambient` category, so previews respect the silent switch and mix with other audio (DESIGN.md).
/// Narration uses `.playback` instead; see docs/ARCHITECTURE.md, decision D3.
@MainActor
final class AudioPreviewPlayer: NSObject, SoundPlaying {
    private var player: AVAudioPlayer?
    private var continuation: AsyncStream<Void>.Continuation?

    func play(_ sound: PreviewSound, volume: Double, fadeIn: Double) -> AsyncStream<Void> {
        stop()
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        guard let url = AppResources.url(forResource: sound.fileName, withExtension: "m4a") else {
            Log.app.error("Sound file missing: \(sound.fileName, privacy: .public)")
            continuation.finish()
            return stream
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient)
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.numberOfLoops = 0
            player.volume = 0
            player.prepareToPlay()
            player.play()
            player.setVolume(Float(volume), fadeDuration: fadeIn)
            self.player = player
            self.continuation = continuation
        } catch {
            Log.app.error("Sound preview failed: \(error.localizedDescription, privacy: .public)")
            continuation.finish()
        }
        return stream
    }

    func setVolume(_ volume: Double) {
        player?.setVolume(Float(volume), fadeDuration: 0.2)
    }

    func stop() {
        player?.stop()
        player = nil
        continuation?.finish()
        continuation = nil
    }

    fileprivate func didFinish(_ id: ObjectIdentifier) {
        guard let player, ObjectIdentifier(player) == id else { return }
        stop()
    }
}

extension AudioPreviewPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(player)
        Task { @MainActor in self.didFinish(id) }
    }
}
